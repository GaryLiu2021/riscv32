`include "inst_define.v"

module core_lsu_top(
	// Global Signal
	input				clk,
	input				rstn,

	// IDU to LSU
	input				lsu_rx_valid,
	input		[6:0]	lsu_rx_opcode,
	input		[2:0]	lsu_rx_func3,
	input		[31:0]	lsu_rx_rs1_data,
	input		[31:0]	lsu_rx_rs2_data,
	input		[4:0]	lsu_rx_rd_idx,
	input		[31:0]	lsu_rx_imme,
	output				lsu_rx_ready,

	// LSU to BUS
	output				lsu_req_vld,
	output				lsu_req_wen,
	output		[2:0]	lsu_req_rwtyp,
	output		[31:0]	lsu_req_addr,
	output		[31:0]	lsu_req_wdata,
	input				lsu_req_rdy,

	// BUS to LSU
	input				lsu_resp_vld,
	input		[31:0]	lsu_resp_rdata,
	output				lsu_resp_rdy,

	// LSU to WBU
	output				lsu_tx_valid,
	output		[31:0]	lsu_tx_data,
	output		[4:0]	lsu_tx_rd_idx,
	input				lsu_tx_ready
);

	/*
	 * Request Entry
	 */
	wire			lsu_req_ld_sd	=	lsu_rx_opcode == `load;
	wire	[5:0]	lsu_req_entry	=	{lsu_req_ld_sd, lsu_rx_rd_idx};

	/*
	 * A FIFO to record requests under processing
	 */
	wire			fifo_rx_valid;
	wire	[4:0]	fifo_rx_data;
	wire			fifo_tx_ready;

	wire			fifo_rx_ready;
	wire			fifo_tx_valid;
	wire	[4:0]	fifo_tx_data;

	FIFO #(
		.DATA_WIDTH ( 5 ),
		.DEPTH      ( 3 ))
	LSU_REQ_TABLE (
		.clk                     ( clk             ),
		.rstn                    ( rstn            ),
		.fifo_rx_valid           ( fifo_rx_valid   ),
		.fifo_rx_data            ( fifo_rx_data    ),
		.fifo_tx_ready           ( fifo_tx_ready   ),

		.fifo_rx_ready           ( fifo_rx_ready   ),
		.fifo_tx_valid           ( fifo_tx_valid   ),
		.fifo_tx_data            ( fifo_tx_data    )
	);

	/*
	 * Request table
	 */
	assign	fifo_rx_valid	=	lsu_rx_valid && lsu_req_rdy && lsu_req_ld_sd;
	assign	fifo_rx_data	=	lsu_req_entry;
	assign	fifo_tx_ready	=	~fifo_tx_valid ? lsu_tx_ready : lsu_tx_ready && lsu_resp_vld;

	/*
	 * LSU to AHB master
	 */
	assign	lsu_req_vld		=	lsu_rx_valid && fifo_rx_ready;
	assign	lsu_req_wen		=	lsu_rx_opcode == `store;
	assign	lsu_req_rwtyp	=	lsu_rx_func3;
	assign	lsu_req_addr	=	lsu_rx_rs1_data + lsu_rx_imme;
	assign	lsu_req_wdata	=	lsu_rx_rs2_data;
	assign	lsu_resp_rdy	=	lsu_tx_ready;

	/*
	 * LSU IO
	 */
	assign	lsu_rx_ready	=	lsu_tx_ready && fifo_rx_ready && lsu_req_rdy;
	assign	lsu_tx_valid	=	lsu_resp_vld && fifo_tx_valid;
	assign	lsu_tx_data		=	lsu_resp_rdata;
	assign	lsu_tx_rd_idx	=	fifo_tx_data[4:0];


`ifdef __LOG_ENABLE__
	always @(posedge clk) begin
		if(rstn && lsu_req_vld && lsu_req_rdy) begin
			if(lsu_req_wen) begin
				$display("LSU: Sending memory write request to bus...");
				$display("\tTarget address: 0x%h", lsu_req_addr);
				$display("\tData sent: %h", lsu_req_wdata);
			end
			else begin
				$display("LSU: Sending memory read request to bus...");
				$display("\tTarget address: 0x%h", lsu_req_addr);
			end
		end
	end
`endif

endmodule