/**
 * @file  top.v
 * @brief Top-level FPGA test harness for the fmc_sdram mezzanine on
 *        VCU118. Brings up dual MT48LC16M16A2 SDRAM (organized x32),
 *        runs a built-in self test, and exposes status via on-board
 *        LEDs and ILA debug probes.
 *
 *  Slot: VCU118 J2 (FMC HPC1, LPC functional subset).
 *  SDRAM clock target: 100 MHz, CL=2, BL=1.
 */

module top(
    // 250 MHz on-board diff clock (bank 41)
    input  wire        clk_p,
    input  wire        clk_n,

    // VCU118 on-board controls
    input  wire        cpu_reset,          // L19 board CPU_RESET (active HIGH, pulldown)
    input  wire [3:0]  btn,                // BTNU/L/D/R
    input  wire [3:0]  sw,                 // DIP switches
    output wire [7:0]  led,

    // SDRAM interface (FMC HPC1 J2, 1.8 V LVCMOS through level shifters)
    output wire        sdram_clk_pad,
    output wire        sdram_cke_pad,
    output wire        sdram_cs_n_pad,
    output wire        sdram_ras_n_pad,
    output wire        sdram_cas_n_pad,
    output wire        sdram_we_n_pad,
    output wire [12:0] sdram_a_pad,
    output wire [ 1:0] sdram_ba_pad,
    output wire [ 3:0] sdram_dqm_pad,
    inout  wire [31:0] sdram_dq_pad,
    output wire        sdram_dq_dir_pad
);

    // ---------------- clocking ------------------------------------------
    wire clk_ibuf;
    wire clk_sys;            // 100 MHz logic clock
    wire mmcm_locked;

    IBUFDS #(.DIFF_TERM("FALSE"),
             .IBUF_LOW_PWR("FALSE"),
             .IOSTANDARD("DIFF_SSTL12"))
        u_ibufds (.O(clk_ibuf), .I(clk_p), .IB(clk_n));

    wire cpu_resetn = ~cpu_reset;

    mmcm u_mmcm (
        .resetn (cpu_resetn),
        .clk_in1(clk_ibuf),
        .clk_out1(clk_sys),     // 100 MHz, 0 deg
        .locked  (mmcm_locked)
    );

    // ---------------- reset synchronizer --------------------------------
    reg [3:0] rst_sync;
    wire      rst_n_async = cpu_resetn & mmcm_locked;
    always @(posedge clk_sys or negedge rst_n_async) begin
        if (!rst_n_async)
            rst_sync <= 4'b0;
        else
            rst_sync <= {rst_sync[2:0], 1'b1};
    end
    wire rst_n = rst_sync[3];

    // ---------------- SDRAM controller signals --------------------------
    wire        ctrl_cke;
    wire        ctrl_cs_n, ctrl_ras_n, ctrl_cas_n, ctrl_we_n;
    wire [12:0] ctrl_a;
    wire [ 1:0] ctrl_ba;
    wire [ 3:0] ctrl_dqm;
    wire [31:0] ctrl_dq_o;
    wire [31:0] ctrl_dq_i;
    wire        ctrl_dq_oe;
    wire [ 3:0] ctrl_dbg_state;

    // user side
    wire        req_valid, req_ready, req_we;
    wire [23:0] req_addr;
    wire [31:0] req_wdata;
    wire [ 3:0] req_wmask;
    wire        rsp_valid;
    wire [31:0] rsp_data;

    sdram_ctrl u_sdram_ctrl (
        .clk        (clk_sys),
        .rst_n      (rst_n),
        .req_valid  (req_valid),
        .req_ready  (req_ready),
        .req_we     (req_we),
        .req_addr   (req_addr),
        .req_wdata  (req_wdata),
        .req_wmask  (req_wmask),
        .rsp_valid  (rsp_valid),
        .rsp_data   (rsp_data),
        .sdram_cke  (ctrl_cke),
        .sdram_cs_n (ctrl_cs_n),
        .sdram_ras_n(ctrl_ras_n),
        .sdram_cas_n(ctrl_cas_n),
        .sdram_we_n (ctrl_we_n),
        .sdram_a    (ctrl_a),
        .sdram_ba   (ctrl_ba),
        .sdram_dqm  (ctrl_dqm),
        .sdram_dq_o (ctrl_dq_o),
        .sdram_dq_i (ctrl_dq_i),
        .sdram_dq_oe(ctrl_dq_oe),
        .dbg_state  (ctrl_dbg_state)
    );

    // ---------------- BIST ----------------------------------------------
    // Restart BIST on btn[0] press (rising edge).
    reg btn0_q;
    always @(posedge clk_sys) btn0_q <= btn[0];
    wire bist_start = ~btn0_q & btn[0];

    // Auto-start BIST after a long delay so the ILA can be armed in
    // HW Manager (programming + arm takes ~10 s; with a 30-bit delay we
    // get ~10 s @ 100 MHz between rst release and BIST start).
    reg        auto_start_done;
    reg [29:0] auto_start_dly;
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            auto_start_done <= 1'b0;
            auto_start_dly  <= 30'h0;
        end else if (!auto_start_done) begin
            if (&auto_start_dly)
                auto_start_done <= 1'b1;
            else
                auto_start_dly <= auto_start_dly + 30'd1;
        end
    end
    wire auto_start = (auto_start_dly == {{29{1'b1}}, 1'b0}) && !auto_start_done;

    wire        bist_busy, bist_done;
    wire [ 1:0] bist_pattern_idx;
    wire        bist_phase_write;
    wire        bist_mismatch;
    wire [31:0] err_count_total;
    wire [31:0] err_count_this;
    wire [23:0] err_first_addr;
    wire [31:0] err_expected;
    wire [31:0] err_actual;
    wire [ 2:0] bist_dbg_state;

    wire bist_start_any = bist_start | auto_start;
    wire bist_loop_en   = sw[0];   // sw[0]=1: auto-loop forever; sw[0]=0: stop after one full pass

    sdram_bist #(
        .ADDR_WIDTH(24),
        .END_ADDR_PARAM(24'h0F_FFFF)   // 1 Mword baseline (4 MB) — known good
    ) u_bist (
        .clk             (clk_sys),
        .rst_n           (rst_n),
        .start           (bist_start_any),
        .loop_enable     (bist_loop_en),
        .req_valid       (req_valid),
        .req_ready       (req_ready),
        .req_we          (req_we),
        .req_addr        (req_addr),
        .req_wdata       (req_wdata),
        .req_wmask       (req_wmask),
        .rsp_valid       (rsp_valid),
        .rsp_data        (rsp_data),
        .pattern_idx     (bist_pattern_idx),
        .phase_write     (bist_phase_write),
        .bist_busy       (bist_busy),
        .bist_done       (bist_done),
        .err_count_total (err_count_total),
        .err_count_this  (err_count_this),
        .err_first_addr  (err_first_addr),
        .err_expected    (err_expected),
        .err_actual      (err_actual),
        .mismatch_strobe (bist_mismatch),
        .dbg_state       (bist_dbg_state)
    );

    // ---------------- LED status ---------------------------------------
    // [7]=error present, [6]=bist_done, [5]=bist_busy, [4]=mmcm_locked,
    // [3:0]=heartbeat / error_count low nibble.
    reg [27:0] heart;
    always @(posedge clk_sys) heart <= heart + 28'd1;

    assign led[7] = |err_count_total;
    assign led[6] = bist_done;
    assign led[5] = bist_busy;
    assign led[4] = mmcm_locked;
    assign led[3:0] = (|err_count_total) ? err_count_total[3:0]
                    : bist_busy ? {bist_phase_write, bist_pattern_idx, heart[26]}
                    : {4{heart[26]}};

    // ---------------- SDRAM clock forwarding (ODDR) ---------------------
    // Forward clk_sys to the chip via ODDR for clean source-synchronous
    // edge alignment. Output is registered and routed through OBUF.
    wire sdram_clk_pre;
    ODDRE1 #(.SRVAL(1'b0)) u_oddr_clk (
        .Q (sdram_clk_pre),
        .C (clk_sys),
        .D1(1'b1),
        .D2(1'b0),
        .SR(~rst_n)
    );

    OBUF u_obuf_clk (.I(sdram_clk_pre), .O(sdram_clk_pad));

    // ---------------- SDRAM control signals to pads ---------------------
    assign sdram_cke_pad   = ctrl_cke;
    assign sdram_cs_n_pad  = ctrl_cs_n;
    assign sdram_ras_n_pad = ctrl_ras_n;
    assign sdram_cas_n_pad = ctrl_cas_n;
    assign sdram_we_n_pad  = ctrl_we_n;
    assign sdram_a_pad     = ctrl_a;
    assign sdram_ba_pad    = ctrl_ba;
    assign sdram_dqm_pad   = ctrl_dqm;

    // Level shifter direction: 1 = FPGA drives SDRAM (write), 0 = SDRAM
    // drives FPGA (read). Switch one cycle ahead of the actual data window
    // through the controller's sdram_dq_oe.
    assign sdram_dq_dir_pad = ctrl_dq_oe;

    // ---------------- DQ tri-state IOBUFs -------------------------------
    genvar gi;
    generate for (gi = 0; gi < 32; gi = gi + 1) begin : g_dq
        IOBUF u_dq (
            .O (ctrl_dq_i[gi]),
            .IO(sdram_dq_pad[gi]),
            .I (ctrl_dq_o[gi]),
            .T (~ctrl_dq_oe)
        );
    end endgenerate

    // ---------------- ILA debug probes (batch_insert_ila picks these) --
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [ 3:0] dbg_ctrl_state = ctrl_dbg_state;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [ 2:0] dbg_bist_state = bist_dbg_state;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire        dbg_req_valid  = req_valid;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire        dbg_req_ready  = req_ready;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire        dbg_req_we     = req_we;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [23:0] dbg_req_addr   = req_addr;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [31:0] dbg_req_wdata  = req_wdata;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire        dbg_rsp_valid  = rsp_valid;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [31:0] dbg_rsp_data   = rsp_data;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [31:0] dbg_err_total  = err_count_total;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [31:0] dbg_err_this   = err_count_this;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [23:0] dbg_err_addr   = err_first_addr;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [31:0] dbg_err_exp    = err_expected;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [31:0] dbg_err_act    = err_actual;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [ 1:0] dbg_pattern    = bist_pattern_idx;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire        dbg_phase_w    = bist_phase_write;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire        dbg_mismatch   = bist_mismatch;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire        dbg_bist_done  = bist_done;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire        dbg_dq_oe      = ctrl_dq_oe;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [12:0] dbg_a          = ctrl_a;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [ 1:0] dbg_ba         = ctrl_ba;
    (* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="u_mmcm/inst/clk_out1" *)
    wire [ 3:0] dbg_cmd        = {ctrl_cs_n, ctrl_ras_n, ctrl_cas_n, ctrl_we_n};

endmodule
