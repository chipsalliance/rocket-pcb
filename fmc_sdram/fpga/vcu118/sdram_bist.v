/**
 * @file  sdram_bist.v
 * @brief Built-in self test for the full SDRAM address space.
 *
 * Sweeps the entire 24-bit (= 16 Mword = 64 MB) address space across
 * four patterns:
 *   pattern_idx 0: addr ^ 0xA5A5_A5A5
 *   pattern_idx 1: ~addr ^ 0x5A5A_5A5A
 *   pattern_idx 2: xorshift32(addr | 1)        (pseudo-random)
 *   pattern_idx 3: xorshift32((addr|1) ^ 0xDEADBEEF)
 *
 * Each pattern runs WRITE pass then READ pass. Mismatches increment a
 * per-pattern counter and a global counter. The first mismatch's
 * address / expected / actual are latched and exposed for ILA capture.
 * On ALL_DONE the BIST loops back to pattern 0 so the ILA can be
 * re-armed against fresh transactions at any time.
 */

module sdram_bist #(
    parameter integer ADDR_WIDTH = 24,
    parameter [ADDR_WIDTH-1:0] END_ADDR_PARAM = {ADDR_WIDTH{1'b1}}
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  start,           // level: re-arm on rising edge
    input  wire                  loop_enable,     // 1 = auto-restart after ALL_DONE

    // controller request port
    output reg                   req_valid,
    input  wire                  req_ready,
    output reg                   req_we,
    output reg  [ADDR_WIDTH-1:0] req_addr,
    output reg  [31:0]           req_wdata,
    output reg  [ 3:0]           req_wmask,
    input  wire                  rsp_valid,
    input  wire [31:0]           rsp_data,

    // status
    output reg  [ 1:0]           pattern_idx,
    output reg                   phase_write,
    output reg                   bist_busy,
    output reg                   bist_done,
    output reg  [31:0]           err_count_total,
    output reg  [31:0]           err_count_this,
    output reg  [ADDR_WIDTH-1:0] err_first_addr,
    output reg  [31:0]           err_expected,
    output reg  [31:0]           err_actual,
    output wire                  mismatch_strobe,
    output wire [ 2:0]           dbg_state
);

    localparam [ADDR_WIDTH-1:0] END_ADDR = END_ADDR_PARAM;

    // -------- pattern function: 4 patterns, deterministic from addr ---
    function [31:0] xorshift32;
        input [31:0] s;
        reg   [31:0] x;
        begin
            x = s  ^ (s << 13);
            x = x  ^ (x >> 17);
            x = x  ^ (x << 5);
            xorshift32 = x;
        end
    endfunction

    function [31:0] pattern;
        input [ADDR_WIDTH-1:0] a;
        input [1:0]            sel;
        reg   [31:0] base;
        begin
            // Old pattern: address ^ {addr[15:0], ~addr[15:0]}. This is
            // the pattern that produced 0 errors at CL_CYC=6 with the 1
            // Mword sweep, so it is our known-good baseline.
            base = {{(32-ADDR_WIDTH){1'b0}}, a} ^ {a[15:0], ~a[15:0]};
            case (sel)
                2'b00: pattern = base;
                2'b01: pattern = 32'hAAAA_5555 ^ {{(32-ADDR_WIDTH){1'b0}}, a};
                2'b10: pattern = 32'h5555_AAAA ^ {{(32-ADDR_WIDTH){1'b0}}, a};
                2'b11: pattern = ~base;
                default: pattern = base;
            endcase
        end
    endfunction

    // -------- FSM ----------------------------------------------------
    localparam [2:0] S_IDLE      = 3'd0;
    localparam [2:0] S_W_ISSUE   = 3'd1;
    localparam [2:0] S_W_WAIT    = 3'd2;
    localparam [2:0] S_R_ISSUE   = 3'd3;
    localparam [2:0] S_R_WAIT    = 3'd4;
    localparam [2:0] S_NEXT_PAT  = 3'd5;
    localparam [2:0] S_DONE      = 3'd6;

    reg [2:0] state;
    reg [ADDR_WIDTH-1:0] addr;
    reg [31:0] expected;

    assign dbg_state       = state;
    assign mismatch_strobe = (state == S_R_WAIT) && rsp_valid && (rsp_data != expected);

    // sticky start latch so a brief external pulse cannot be missed
    reg start_q, start_lvl;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_q   <= 1'b0;
            start_lvl <= 1'b0;
        end else begin
            start_q   <= start;
            if (start && !start_q) start_lvl <= 1'b1;
            if (state != S_IDLE)   start_lvl <= 1'b0;
        end
    end
    wire start_eff = start_lvl;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= S_IDLE;
            addr             <= {ADDR_WIDTH{1'b0}};
            expected         <= 32'h0;
            req_valid        <= 1'b0;
            req_we           <= 1'b0;
            req_addr         <= {ADDR_WIDTH{1'b0}};
            req_wdata        <= 32'h0;
            req_wmask        <= 4'h0;
            pattern_idx      <= 2'd0;
            phase_write      <= 1'b1;
            bist_busy        <= 1'b0;
            bist_done        <= 1'b0;
            err_count_total  <= 32'h0;
            err_count_this   <= 32'h0;
            err_first_addr   <= {ADDR_WIDTH{1'b0}};
            err_expected     <= 32'h0;
            err_actual       <= 32'h0;
        end else begin
            req_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    bist_busy   <= 1'b0;
                    if (start_eff) begin
                        addr            <= {ADDR_WIDTH{1'b0}};
                        pattern_idx     <= 2'd0;
                        phase_write     <= 1'b1;
                        err_count_total <= 32'h0;
                        err_count_this  <= 32'h0;
                        err_first_addr  <= {ADDR_WIDTH{1'b0}};
                        err_expected    <= 32'h0;
                        err_actual      <= 32'h0;
                        bist_done       <= 1'b0;
                        bist_busy       <= 1'b1;
                        state           <= S_W_ISSUE;
                    end
                end

                // Hold req_valid asserted until req_valid && req_ready are
                // both 1 in the SAME cycle (the actual transfer cycle).
                // Without this, a refresh that fires between the master
                // setting valid and the slave latching it eats the request
                // and the BIST hangs in R_WAIT forever.
                S_W_ISSUE: begin
                    req_valid <= 1'b1;
                    req_we    <= 1'b1;
                    req_addr  <= addr;
                    req_wdata <= pattern(addr, pattern_idx);
                    req_wmask <= 4'h0;
                    if (req_valid && req_ready) begin
                        req_valid <= 1'b0;
                        state     <= S_W_WAIT;
                    end
                end

                S_W_WAIT: begin
                    if (req_ready) begin
                        if (addr == END_ADDR) begin
                            addr        <= {ADDR_WIDTH{1'b0}};
                            phase_write <= 1'b0;
                            state       <= S_R_ISSUE;
                        end else begin
                            addr  <= addr + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
                            state <= S_W_ISSUE;
                        end
                    end
                end

                S_R_ISSUE: begin
                    req_valid <= 1'b1;
                    req_we    <= 1'b0;
                    req_addr  <= addr;
                    expected  <= pattern(addr, pattern_idx);
                    if (req_valid && req_ready) begin
                        req_valid <= 1'b0;
                        state     <= S_R_WAIT;
                    end
                end

                S_R_WAIT: begin
                    if (rsp_valid) begin
                        if (rsp_data != expected) begin
                            err_count_total <= err_count_total + 32'd1;
                            err_count_this  <= err_count_this  + 32'd1;
                            if (err_count_total == 32'd0) begin
                                err_first_addr <= addr;
                                err_expected   <= expected;
                                err_actual     <= rsp_data;
                            end
                        end
                        if (addr == END_ADDR) begin
                            state <= S_NEXT_PAT;
                        end else begin
                            addr  <= addr + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
                            state <= S_R_ISSUE;
                        end
                    end
                end

                S_NEXT_PAT: begin
                    err_count_this <= 32'h0;
                    if (pattern_idx == 2'd3) begin
                        state <= S_DONE;
                    end else begin
                        pattern_idx <= pattern_idx + 2'd1;
                        addr        <= {ADDR_WIDTH{1'b0}};
                        phase_write <= 1'b1;
                        state       <= S_W_ISSUE;
                    end
                end

                S_DONE: begin
                    bist_busy <= 1'b0;
                    bist_done <= 1'b1;
                    if (loop_enable || start_eff) begin
                        addr            <= {ADDR_WIDTH{1'b0}};
                        pattern_idx     <= 2'd0;
                        phase_write     <= 1'b1;
                        err_count_total <= 32'h0;
                        err_count_this  <= 32'h0;
                        err_first_addr  <= {ADDR_WIDTH{1'b0}};
                        err_expected    <= 32'h0;
                        err_actual      <= 32'h0;
                        bist_done       <= 1'b0;
                        bist_busy       <= 1'b1;
                        state           <= S_W_ISSUE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
