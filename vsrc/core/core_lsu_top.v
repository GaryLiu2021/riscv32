module core_lsu_top(
	// Global Signal
	input				clk,
	input				rstn,

	// Interface with IDU
	input				lsu_rx_valid,
	output				lsu_rx_ready,

	input		[6:0]	lsu_rx_opcode,
	input		[2:0]	lsu_rx_func3,
	input		[31:0]	lsu_rx_rs1_data,
	input		[31:0]	lsu_rx_rs2_data,
	input		[4:0]	lsu_rx_rd_idx,
	input		[31:0]	lsu_rx_imme,

	// Memory Interface
	output				lsu_bus_wen,
	output				lsu_bus_ren,
	output		[2:0]	lsu_bus_rwtyp,
	output		[31:0]	lsu_bus_addr,
	output		[31:0]	lsu_bus_wdata,

	input				lsu_bus_wack,		// Write data ack
	input				lsu_bus_rvld,		// Read data valid
	input		[31:0]	lsu_bus_rdata,

	// Interface with WBU
	output				lsu_tx_valid,
	input				lsu_tx_ready,

	output		[31:0]	lsu_tx_data,
	output		[4:0]	lsu_tx_rd_idx
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
		.DEPTH      ( 8 ))
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

	assign	fifo_rx_valid	=	lsu_rx_valid && lsu_req_ld_sd;
	assign	fifo_rx_data	=	lsu_req_entry;
	assign	fifo_tx_ready	=	~fifo_tx_valid ? 1'b1 : lsu_bus_rvld;

	/*
	 * Interface with bus
	 */
	wire	rx_ena	=	lsu_rx_valid && lsu_rx_ready;
	wire	tx_ena	=	lsu_tx_valid && lsu_tx_ready;

	assign	lsu_bus_wen		=	rx_ena && lsu_rx_opcode == `store;
	assign	lsu_bus_ren		=	rx_ena && lsu_rx_opcode == `load;
	assign	lsu_bus_rwtyp	=	lsu_rx_func3;
	assign	lsu_bus_addr	=	lsu_rx_rs1_data + lsu_rx_imme;
	assign	lsu_bus_wdata	=	lsu_rx_rs2_data;

	/*
	 * LSU IO
	 */
	assign	lsu_rx_ready	=	lsu_tx_ready && fifo_rx_ready;
	assign	lsu_tx_valid	=	lsu_bus_rvld && fifo_tx_valid;
	assign	lsu_tx_data		=	lsu_bus_rdata;
	assign	lsu_tx_rd_idx	=	fifo_tx_data[4:0];

	always @(posedge clk) begin
		if(rstn) begin
			if(lsu_bus_wen) begin
				$display("LSU: Sending memory write request to bus...");
				$display("\tTarget address: 0x%h", lsu_bus_addr);
				$display("\tData sent: %h", lsu_bus_wdata);
			end
			if(lsu_bus_ren) begin
				$display("LSU: Sending memory read request to bus...");
				$display("\tTarget address: 0x%h", lsu_bus_addr);
				$display("\tData fetched: %h", lsu_bus_rdata);
			end
		end
	end

endmodule