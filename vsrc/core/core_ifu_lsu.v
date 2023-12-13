
module core_ifu_lsu(
	input                   clk,
	input                   rstn,

	// Request Interface
	input                   lsu_rx_valid,
	output					lsu_rx_ready,
	input		[31:0]		lsu_rx_addr,

	// Bus Interface
	output					bus_req_valid,
	output		[31:0]		bus_req_addr,

	input					bus_rsp_valid,
	input		[31:0]		bus_rsp_data,

	// Response Interface
	output					lsu_tx_valid,
	input					lsu_tx_ready,
	output		[31:0]		lsu_tx_inst
);

	assign bus_req_valid	=	lsu_rx_valid && lsu_rx_ready;
	assign bus_req_addr		=	lsu_rx_addr;

	// FIFO Inputs
	wire   fifo_rx_valid;
	wire   fifo_tx_ready;
	wire   [31:0]  fifo_rx_data;

	// FIFO Outputs
	wire  [31:0]  fifo_tx_data;
	wire  fifo_rx_ready;
	wire  fifo_tx_valid;

	FIFO #(
		.DATA_WIDTH ( 32 ),
		.DEPTH      ( 8 ))
	ifu_lsu_buf (
		.clk                     ( clk             ),
		.rstn                    ( rstn            ),
		.fifo_rx_valid           ( fifo_rx_valid   ),
		.fifo_tx_ready           ( fifo_tx_ready   ),
		.fifo_rx_data            ( fifo_rx_data    ),

		.fifo_tx_data            ( fifo_tx_data    ),
		.fifo_rx_ready           ( fifo_rx_ready   ),
		.fifo_tx_valid           ( fifo_tx_valid   )
	);

	assign fifo_rx_valid = bus_rsp_valid;
	assign fifo_rx_data = bus_rsp_data;
	assign lsu_rx_ready = fifo_rx_ready;

	assign fifo_tx_ready = lsu_tx_ready;
	assign lsu_tx_valid = fifo_tx_valid;
	assign lsu_tx_inst = fifo_tx_data;

endmodule