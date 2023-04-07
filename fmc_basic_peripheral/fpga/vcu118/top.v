/**
 * @file  top.v
 * @brief Test code to roughly verify the basic functions of fmc
 * @date  2023-03-31
 */
module top(
	/* clock */
	input clk_p,
	input clk_n,
	/* jtag */
	input tck,
	input tms,
	input tdi,
	output tdo,
	/* uart */
	input uart_rx,
	output uart_tx,
	/* led */
	output [7:0] led,
	/* switch */
	input [3:0] switch,
	/* key */
	input [3:0] key
);

wire rst_n;
wire clk_ibuf;
wire clk;
reg [31:0] counter;
reg [1:0] status;

IBUFDS ibufds_inst (
	.I(clk_p),
	.IB(clk_n),
	.O(clk_ibuf)
);

BUFG bufg_inst (
	.I(clk_ibuf),
	.O(clk)
);

jtag_tap jtag_tap_inst (
	.trstn_pad_i(rst_n),
	.tck_pad_i(tck),
	.tms_pad_i(tms),
	.tdi_pad_i(tdi),
	.tdo_pad_o(tdo)
);

assign uart_tx = uart_rx;

always@(posedge clk,negedge rst_n) begin
	if(!rst_n)
		counter <= 0;
	else
		counter <= counter + 1;
end

always@(posedge clk,negedge rst_n) begin
	if(!rst_n)
		status <= 0;
	else if (!(key[1]))
		status <= status + 1;
	else
		status <= status;
end

assign led[7:0] =
	status == 2'b00 ? counter[31:24] :
	status == 2'b01 ? {switch[3:0] , key[3:0]} :
	status == 2'b10 ? {switch[3:0] ^ key[3:0] , switch[3:0] ^ key[3:0]} :
	8'b11111111;

assign rst_n = key[0] | key[3];

endmodule
