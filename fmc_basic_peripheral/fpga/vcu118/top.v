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
	input trst,
	input srst,
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
	input [3:0] key,
	/* USB */
	input usb_det,
	output usb_spd,
	input usb_rcv,
	inout usb_vp,
	inout usb_vm,
	output usb_con,
	output usb_sus,
	output usb_oen,
	/* GPIO */
	output [15:0] gpio
);

wire rst_n;
wire clk_ibuf;

wire clk;
wire clk_usb;

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

always@(posedge clk_usb,negedge rst_n) begin
	if(!rst_n)
		counter <= 0;
	else
		counter <= counter + 1;
end

always@(posedge clk_usb,negedge rst_n) begin
	if(!rst_n)
		status <= 0;
	else if (!(key[1] | key[3]))
		status <= status + 1;
	else
		status <= status;
end

assign led[7:0] =
	status == 2'b11 ? counter[31:24] :
	status == 2'b01 ? {switch[3:0] , key[3:0]} :
	status == 2'b10 ? {switch[3:0] ^ key[3:0] , switch[3:0] ^ key[3:0]} :
	status == 2'b00 ? {{(8-1){usb_det}}, ~usb_det} :
	8'b11111111;

assign gpio[15:0] = {counter[31:24], counter[31:24]};
assign rst_n = (key[0] | key[3]) & trst & srst;

(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire uart_loop_valid;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire uart_loop_accept;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire [7:0] uart_loop_data;

(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire usb_pads_rx_dn_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire usb_pads_rx_dp_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire usb_pads_rx_rcv_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire usb_pads_tx_dn_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire usb_pads_tx_dp_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire usb_pads_tx_oen_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire [31:0] counter_probe;
assign counter_probe[31:0] = counter[31:0];

(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire utmi_dmpulldown_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire utmi_dppulldown_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire utmi_rxactive_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire utmi_rxerror_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire utmi_rxvalid_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire utmi_termselect_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire utmi_txready_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire utmi_txvalid_w;

(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire [  1:0]  utmi_linestate_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire [  1:0]  utmi_op_mode_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire [  1:0]  utmi_xcvrselect_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire [  7:0]  utmi_data_in_w;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) wire [  7:0]  utmi_data_out_w;

mmcm mmcm_inst
(
	.resetn(rst_n),
	.clk_in1(clk),
	.clk_out1(clk_usb),
	.locked()
);

usb_cdc_core usb_cdc_core_inst
(
    .clk_i(clk_usb),
    .rst_i(~rst_n),

    .enable_i(1'b1),

    .utmi_data_in_i(utmi_data_in_w),
    .utmi_txready_i(utmi_txready_w),
    .utmi_rxvalid_i(utmi_rxvalid_w),
    .utmi_rxactive_i(utmi_rxactive_w),
    .utmi_rxerror_i(utmi_rxerror_w),
    .utmi_linestate_i(utmi_linestate_w),
    .utmi_data_out_o(utmi_data_out_w),
    .utmi_txvalid_o(utmi_txvalid_w),
    .utmi_op_mode_o(utmi_op_mode_w),
    .utmi_xcvrselect_o(utmi_xcvrselect_w),
    .utmi_termselect_o(utmi_termselect_w),
    .utmi_dppulldown_o(utmi_dppulldown_w),
    .utmi_dmpulldown_o(utmi_dmpulldown_w),

    /* Device -> Host */
    .inport_valid_i(uart_loop_valid),
    .inport_data_i(uart_loop_data),
    .inport_accept_o(uart_loop_accept),

    /* Host -> Device */
    .outport_valid_o(uart_loop_valid),
    .outport_data_o(uart_loop_data),
    .outport_accept_i(uart_loop_accept)
);

usb_fs_phy u_usb_phy
(
    /* Inputs */
     .clk_i(clk_usb)
    ,.rst_i(~rst_n)
    ,.utmi_data_out_i(utmi_data_out_w)
    ,.utmi_txvalid_i(utmi_txvalid_w)
    ,.utmi_op_mode_i(utmi_op_mode_w)
    ,.utmi_xcvrselect_i(utmi_xcvrselect_w)
    ,.utmi_termselect_i(utmi_termselect_w)
    ,.utmi_dppulldown_i(utmi_dppulldown_w)
    ,.utmi_dmpulldown_i(utmi_dmpulldown_w)
    ,.usb_rx_rcv_i(usb_pads_rx_rcv_w)
    ,.usb_rx_dp_i(usb_pads_rx_dp_w)
    ,.usb_rx_dn_i(usb_pads_rx_dn_w)
    ,.usb_reset_assert_i(1'b0)

    /* Outputs */
    ,.utmi_data_in_o(utmi_data_in_w)
    ,.utmi_txready_o(utmi_txready_w)
    ,.utmi_rxvalid_o(utmi_rxvalid_w)
    ,.utmi_rxactive_o(utmi_rxactive_w)
    ,.utmi_rxerror_o(utmi_rxerror_w)
    ,.utmi_linestate_o(utmi_linestate_w)
    ,.usb_tx_dp_o(usb_pads_tx_dp_w)
    ,.usb_tx_dn_o(usb_pads_tx_dn_w)
    ,.usb_tx_oen_o(usb_pads_tx_oen_w)
    ,.usb_reset_detect_o()
    ,.usb_en_o()
);

IOBUF iobuf_usb_vp_inst
(
	.O(usb_pads_rx_dp_w),
	.IO(usb_vp),
	.I(usb_pads_tx_dp_w),
	.T(usb_pads_tx_oen_w)
);

IOBUF iobuf_usb_vm_inst
(
	.O(usb_pads_rx_dn_w),
	.IO(usb_vm),
	.I(usb_pads_tx_dn_w),
	.T(usb_pads_tx_oen_w)
);

assign usb_spd = 1'b1;
assign usb_con = 1'b1;
assign usb_sus = ~usb_det;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) assign usb_pads_rx_rcv_w = usb_rcv;
(* keep="true",mark_debug,mark_debug_valid="true",mark_debug_clock="mmcm_inst/inst/clk_out1" *) assign usb_oen = usb_pads_tx_oen_w;

endmodule
