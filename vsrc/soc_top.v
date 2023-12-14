module soc_top(
	input	clk,
	input	rstn,
	input	soc_uart_rx_pin,
	output	soc_uart_tx_pin
);


	/*
	 * Counter
	 */
	reg [31:0]  counter = 0;
	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			counter <= 'd0;
		else
			counter <= counter + 1;
	end

	/*
	 * RV32I CORE
	 * INTERFACE:
	 *		LSU		TO	AHB(MASTER)
	 *		IFU		TO	ROM
	 */
	wire			core_ifu_inst_vld;
	wire	[31:0]	core_ifu_inst;
	wire			core_lsu_req_rdy;
	wire			core_lsu_resp_vld;
	wire	[31:0]	core_lsu_resp_rdata;

	wire			core_ifu_addr_vld;
	wire	[31:0]	core_ifu_addr;
	wire			core_lsu_req_vld;
	wire			core_lsu_wen;
	wire			core_lsu_ren;
	wire	[2:0]	core_lsu_rwtyp;
	wire	[31:0]	core_lsu_addr;
	wire	[31:0]	core_lsu_wdata;
	wire			core_lsu_resp_rdy;

	core_top  u_core_top (
		.clk                          ( clk                           ),
		.rstn                         ( rstn                          ),
		.core_ifu_inst_vld            ( core_ifu_inst_vld             ),
		.core_ifu_inst                ( core_ifu_inst                 ),
		.core_lsu_req_rdy             ( core_lsu_req_rdy              ),
		.core_lsu_resp_vld            ( core_lsu_resp_vld             ),
		.core_lsu_resp_rdata          ( core_lsu_resp_rdata           ),

		.core_ifu_addr_vld            ( core_ifu_addr_vld             ),
		.core_ifu_addr                ( core_ifu_addr                 ),
		.core_lsu_req_vld             ( core_lsu_req_vld              ),
		.core_lsu_wen                 ( core_lsu_wen                  ),
		.core_lsu_rwtyp               ( core_lsu_rwtyp                ),
		.core_lsu_addr                ( core_lsu_addr                 ),
		.core_lsu_wdata               ( core_lsu_wdata                ),
		.core_lsu_resp_rdy            ( core_lsu_resp_rdy             )
	);

	/*
	 * AHB
	 * INTERFACE:
	 *		AHB(MASTER)	TO	CORE(LSU)
	 *		UART(RX,TX)	TO	EXTERNAL
	 */
	wire	ahbm_lsu_req_vld;
	wire	ahbm_lsu_req_wen;
	wire	ahbm_lsu_req_rwtyp;
	wire	[31:0]	ahbm_lsu_req_addr;
	wire	[31:0]	ahbm_lsu_req_wdata;
	wire	ahbm_lsu_rsp_rdy;
	wire	rx_pin;

	wire	ahbm_lsu_req_rdy;
	wire	ahbm_lsu_rsp_vld;
	wire	[31:0]	ahbm_lsu_rsp_rdata;
	wire	tx_pin;

	ahb_lite_top  u_ahb_lite_top (
		.clk                     ( clk                  ),
		.rstn                    ( rstn                 ),
		.ahbm_lsu_req_vld        ( ahbm_lsu_req_vld     ),
		.ahbm_lsu_req_wen        ( ahbm_lsu_req_wen     ),
		.ahbm_lsu_req_rwtyp      ( ahbm_lsu_req_rwtyp   ),
		.ahbm_lsu_req_addr       ( ahbm_lsu_req_addr    ),
		.ahbm_lsu_req_wdata      ( ahbm_lsu_req_wdata   ),
		.ahbm_lsu_rsp_rdy        ( ahbm_lsu_rsp_rdy     ),
		.rx_pin                  ( rx_pin               ),

		.ahbm_lsu_req_rdy        ( ahbm_lsu_req_rdy     ),
		.ahbm_lsu_rsp_vld        ( ahbm_lsu_rsp_vld     ),
		.ahbm_lsu_rsp_rdata      ( ahbm_lsu_rsp_rdata   ),
		.tx_pin                  ( tx_pin               )
	);

	/*
	 * MODULE		ROM
	 * INTERFACE	ROM		TO	IFU
	 */
	wire			rom_rx_valid;
	wire	[31:0]	rom_rx_addr;

	wire			rom_tx_valid;
	wire	[31:0]	rom_tx_data;

	emu_rom  u_emu_rom (
		.clk                     ( clk            ),
		.rstn                    ( rstn           ),
		.rom_rx_valid            ( rom_rx_valid   ),
		.rom_rx_addr             ( rom_rx_addr    ),

		.rom_tx_valid            ( rom_tx_valid   ),
		.rom_tx_data             ( rom_tx_data    )
	);

	/*
	 * Assignments
	 */
	assign	core_ifu_inst_vld	=	rom_tx_valid;
	assign	core_ifu_inst		=	rom_tx_data;
	assign	core_lsu_req_rdy	=	ahbm_lsu_req_rdy;
	assign	core_lsu_resp_vld	=	ahbm_lsu_rsp_vld;
	assign	core_lsu_resp_rdata	=	ahbm_lsu_rsp_rdata;

	assign	ahbm_lsu_req_vld	=	core_lsu_req_vld;
	assign	ahbm_lsu_req_wen	=	core_lsu_wen;
	assign	ahbm_lsu_req_rwtyp	=	core_lsu_rwtyp;
	assign	ahbm_lsu_req_addr	=	core_lsu_addr;
	assign	ahbm_lsu_req_wdata	=	core_lsu_wdata;
	assign	ahbm_lsu_rsp_rdy	=	core_lsu_resp_rdy;
	assign	rx_pin				=	soc_uart_rx_pin;

	assign	rom_rx_valid		=	core_ifu_addr_vld;
	assign	rom_rx_addr			=	core_ifu_addr;

	assign	soc_uart_tx_pin		=	tx_pin;

endmodule //soc_top