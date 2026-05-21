/**
 * @file  sdram_ctrl.v
 * @brief Minimal SDRAM controller for dual MT48LC16M16A2 organized as x32.
 *
 * Target: 100 MHz, CL=2, BL=1 (one 32-bit word per transaction).
 * Address layout: req_addr[23:11]=row, [10:9]=bank, [8:0]=col.
 * 32M words total (= 128 MB) addressable by 25-bit word address; this
 * controller uses the low 24 bits only since the part is 32 MB per chip
 * and the FMC mezzanine wires both chips into a x32 word.
 *
 * The req/rsp interface is a strict request-response with a single
 * outstanding transaction (req_ready drops while the controller is busy).
 *
 * The DQ bus is exposed split (sdram_dq_o, sdram_dq_i, sdram_dq_oe);
 * the parent module is responsible for the IOBUF instantiation and for
 * driving the level-shifter direction pin from sdram_dq_oe.
 */

module sdram_ctrl #(
    parameter integer CLK_FREQ_HZ      = 50_000_000,
    parameter integer T_DESL_NS        = 100_000,  // 100 us power-on wait
    parameter integer REFRESH_PERIOD_NS = 7_500    // tREF/8192 with margin
) (
    input  wire        clk,
    input  wire        rst_n,

    // user side
    input  wire        req_valid,
    output wire        req_ready,
    input  wire        req_we,
    input  wire [23:0] req_addr,
    input  wire [31:0] req_wdata,
    input  wire [ 3:0] req_wmask,    // 1 = mask out byte (DQM polarity)
    output reg         rsp_valid,
    output reg  [31:0] rsp_data,

    // SDRAM signals (registered, single-edge)
    output reg         sdram_cke,
    output reg         sdram_cs_n,
    output reg         sdram_ras_n,
    output reg         sdram_cas_n,
    output reg         sdram_we_n,
    output reg  [12:0] sdram_a,
    output reg  [ 1:0] sdram_ba,
    output reg  [ 3:0] sdram_dqm,
    output reg  [31:0] sdram_dq_o,
    input  wire [31:0] sdram_dq_i,
    output reg         sdram_dq_oe,

    // status / debug
    output wire [ 3:0] dbg_state
);

    // ---------------- timing in cycles ---------------------------------
    // INIT_WAIT_CYC = CLK_MHz * T_DESL_us. At 50 MHz, 100 us → 5000 cycles.
    localparam integer INIT_WAIT_CYC = (CLK_FREQ_HZ / 1_000_000) * (T_DESL_NS / 1000);
    localparam integer REFRESH_CYC   = (CLK_FREQ_HZ / 1_000_000) * REFRESH_PERIOD_NS / 1000;
    // MT48LC16M16A2 -7E typical timing in cycles @ 50 MHz (20 ns/cycle):
    // NOTE: parameters with tCK-units in the datasheet (tRDL, tMRD) must be
    // satisfied in cycle count regardless of clock frequency.
    localparam integer T_RCD_CYC = 1;  // tRCD = 15 ns (ns-spec)
    localparam integer T_RP_CYC  = 1;  // tRP  = 15 ns (ns-spec)
    localparam integer T_RC_CYC  = 3;  // tRC  = 60 ns (ns-spec)
    localparam integer T_RFC_CYC = 3;  // tRFC = 60 ns (ns-spec)
    localparam integer T_MRD_CYC = 2;  // tMRD = 2 tCK (tCK-spec, ALWAYS >= 2)
    localparam integer T_WR_CYC  = 3;  // tRDL = 2 tCK (tCK-spec, ALWAYS >= 2). Use 3 for 1 cycle margin.
    localparam integer CL_CYC    = 4;  // CL=2 in MR + cmd reg cycle + round-trip margin

    // ---------------- SDRAM commands -----------------------------------
    // {cs_n, ras_n, cas_n, we_n}
    localparam [3:0] CMD_DESEL = 4'b1111;
    localparam [3:0] CMD_NOP   = 4'b0111;
    localparam [3:0] CMD_ACT   = 4'b0011;
    localparam [3:0] CMD_READ  = 4'b0101;
    localparam [3:0] CMD_WRITE = 4'b0100;
    localparam [3:0] CMD_PRE   = 4'b0010;
    localparam [3:0] CMD_AREF  = 4'b0001;
    localparam [3:0] CMD_LMR   = 4'b0000;

    // Mode register: BL=1, BT=sequential, CL=2, single-write
    // [12:10]=000 reserved, [9]=1 single write, [8:7]=00 standard,
    // [6:4]=010 CL2, [3]=0 sequential, [2:0]=000 BL1
    localparam [12:0] MODE_REG = 13'b000_1_00_010_0_000;

    // ---------------- FSM ----------------------------------------------
    localparam [3:0] S_INIT_WAIT = 4'd0;
    localparam [3:0] S_INIT_PRE  = 4'd1;
    localparam [3:0] S_INIT_AREF = 4'd2;
    localparam [3:0] S_INIT_LMR  = 4'd3;
    localparam [3:0] S_IDLE      = 4'd4;
    localparam [3:0] S_ACT       = 4'd5;
    localparam [3:0] S_RW        = 4'd6;
    localparam [3:0] S_RW_WAIT   = 4'd7;
    localparam [3:0] S_READ_DAT  = 4'd8;
    localparam [3:0] S_PRE       = 4'd9;
    localparam [3:0] S_AREF      = 4'd10;

    reg [ 3:0] state;
    reg [31:0] timer;
    reg [ 3:0] aref_cnt;
    reg [15:0] refresh_timer;
    reg        refresh_due;

    // latched request
    reg        cmd_we_q;
    reg [12:0] cmd_row_q;
    reg [ 1:0] cmd_bank_q;
    reg [ 8:0] cmd_col_q;
    reg [31:0] cmd_wdata_q;
    reg [ 3:0] cmd_wmask_q;

    assign req_ready = (state == S_IDLE) && !refresh_due;
    assign dbg_state = state;

    // ---------------- command register helper --------------------------
    task issue_cmd;
        input [3:0] cmd;
        input [12:0] addr;
        input [1:0] bank;
        input [3:0] dqm;
        begin
            sdram_cs_n  <= cmd[3];
            sdram_ras_n <= cmd[2];
            sdram_cas_n <= cmd[1];
            sdram_we_n  <= cmd[0];
            sdram_a     <= addr;
            sdram_ba    <= bank;
            sdram_dqm   <= dqm;
        end
    endtask

    // ---------------- main FSM -----------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_INIT_WAIT;
            timer         <= INIT_WAIT_CYC[31:0];
            aref_cnt      <= 4'd0;
            refresh_timer <= 16'd0;
            refresh_due   <= 1'b0;
            sdram_cke     <= 1'b0;
            sdram_dq_oe   <= 1'b0;
            sdram_dq_o    <= 32'h0;
            rsp_valid     <= 1'b0;
            rsp_data      <= 32'h0;
            cmd_we_q      <= 1'b0;
            cmd_row_q     <= 13'h0;
            cmd_bank_q    <= 2'h0;
            cmd_col_q     <= 9'h0;
            cmd_wdata_q   <= 32'h0;
            cmd_wmask_q   <= 4'h0;
            issue_cmd(CMD_NOP, 13'h0, 2'h0, 4'hF);
        end else begin
            // refresh counter runs after init complete
            if (state != S_INIT_WAIT && state != S_INIT_PRE
                && state != S_INIT_AREF && state != S_INIT_LMR) begin
                if (refresh_timer == REFRESH_CYC[15:0]) begin
                    refresh_timer <= 16'd0;
                    refresh_due   <= 1'b1;
                end else begin
                    refresh_timer <= refresh_timer + 16'd1;
                end
            end

            // default: NOP, drop response strobe
            issue_cmd(CMD_NOP, 13'h0, 2'h0, 4'h0);
            rsp_valid <= 1'b0;

            case (state)
                S_INIT_WAIT: begin
                    sdram_cke <= 1'b1;
                    sdram_dq_oe <= 1'b0;
                    if (timer == 32'd0) begin
                        state <= S_INIT_PRE;
                    end else begin
                        timer <= timer - 32'd1;
                    end
                end

                S_INIT_PRE: begin
                    issue_cmd(CMD_PRE, 13'h0400, 2'h0, 4'h0); // A10=1: all banks
                    timer    <= T_RP_CYC - 1;
                    aref_cnt <= 4'd8;
                    state    <= S_INIT_AREF;
                end

                S_INIT_AREF: begin
                    if (timer != 32'd0) begin
                        timer <= timer - 32'd1;
                    end else if (aref_cnt != 4'd0) begin
                        issue_cmd(CMD_AREF, 13'h0, 2'h0, 4'h0);
                        timer    <= T_RFC_CYC - 1;
                        aref_cnt <= aref_cnt - 4'd1;
                    end else begin
                        issue_cmd(CMD_LMR, MODE_REG, 2'h0, 4'h0);
                        timer <= T_MRD_CYC - 1;
                        state <= S_INIT_LMR;
                    end
                end

                S_INIT_LMR: begin
                    if (timer == 32'd0) begin
                        state <= S_IDLE;
                    end else begin
                        timer <= timer - 32'd1;
                    end
                end

                S_IDLE: begin
                    sdram_dq_oe <= 1'b0;
                    if (refresh_due) begin
                        issue_cmd(CMD_AREF, 13'h0, 2'h0, 4'h0);
                        refresh_due <= 1'b0;
                        timer       <= T_RFC_CYC - 1;
                        state       <= S_AREF;
                    end else if (req_valid) begin
                        cmd_we_q    <= req_we;
                        cmd_row_q   <= req_addr[23:11];
                        cmd_bank_q  <= req_addr[10:9];
                        cmd_col_q   <= req_addr[8:0];
                        cmd_wdata_q <= req_wdata;
                        cmd_wmask_q <= req_wmask;
                        issue_cmd(CMD_ACT, req_addr[23:11], req_addr[10:9], 4'h0);
                        timer <= T_RCD_CYC - 1;
                        state <= S_ACT;
                    end
                end

                S_ACT: begin
                    if (timer == 32'd0) begin
                        // issue R or W
                        if (cmd_we_q) begin
                            issue_cmd(CMD_WRITE,
                                      {4'h0, cmd_col_q},  // A10=0 no auto-prech
                                      cmd_bank_q,
                                      cmd_wmask_q);
                            sdram_dq_o  <= cmd_wdata_q;
                            sdram_dq_oe <= 1'b1;
                        end else begin
                            issue_cmd(CMD_READ,
                                      {4'h0, cmd_col_q},
                                      cmd_bank_q,
                                      4'h0);
                            sdram_dq_oe <= 1'b0;
                        end
                        timer <= cmd_we_q ? (T_WR_CYC - 1) : (CL_CYC - 1);
                        state <= S_RW_WAIT;
                    end else begin
                        timer <= timer - 32'd1;
                    end
                end

                S_RW_WAIT: begin
                    if (timer == 32'd0) begin
                        if (cmd_we_q) begin
                            sdram_dq_oe <= 1'b0;
                            issue_cmd(CMD_PRE, 13'h0400, cmd_bank_q, 4'h0); // A10=1 all
                            timer <= T_RP_CYC - 1;
                            state <= S_PRE;
                        end else begin
                            // CL cycles elapsed; latch DQ this cycle and signal
                            rsp_data  <= sdram_dq_i;
                            rsp_valid <= 1'b1;
                            issue_cmd(CMD_PRE, 13'h0400, cmd_bank_q, 4'h0);
                            timer <= T_RP_CYC - 1;
                            state <= S_PRE;
                        end
                    end else begin
                        timer <= timer - 32'd1;
                    end
                end

                S_PRE: begin
                    if (timer == 32'd0) begin
                        state <= S_IDLE;
                    end else begin
                        timer <= timer - 32'd1;
                    end
                end

                S_AREF: begin
                    if (timer == 32'd0) begin
                        state <= S_IDLE;
                    end else begin
                        timer <= timer - 32'd1;
                    end
                end

                default: state <= S_INIT_WAIT;
            endcase
        end
    end

endmodule
