module core_lsu_top(
	// Global Signal
	input				clk,
	input				rstn,

	// Interface with IDU
	input				lsu_rx_valid,
	output				lsu_rx_ready,

	input		[6:0]	lsu_rx_opcode,
	input		[2:0]	lsu_rx_func3,
	input		[4:0]	lsu_rx_rs1_data,
	input		[4:0]	lsu_rx_rs2_data,
	input		[4:0]	lsu_rx_rd_idx,
	input		[31:0]	lsu_rx_imme,

	// Memory Interface
	output				lsu_bus_wen,
	output		[2:0]	lsu_bus_rwtyp,

	output		[31:0]	lsu_bus_addr,
	output		[31:0]	lsu_bus_wdata,
	input		[31:0]	lsu_bus_rdata,

	//Todo: memory have valid signal

	// Interface with WBU
	output	reg			lsu_tx_valid,
	input				lsu_tx_ready,

	output	reg	[31:0]	lsu_tx_data,
	output	reg	[4:0]	lsu_tx_rd_idx
);

	wire rx_ena = lsu_rx_valid && lsu_rx_ready;
	wire tx_ena = lsu_tx_valid && lsu_tx_ready;

	assign	lsu_bus_wen		=	rx_ena && lsu_rx_opcode == `store;
	assign	lsu_bus_rwtyp	=	lsu_rx_func3;
	assign	lsu_bus_addr	=	lsu_rx_rs1_data + lsu_rx_imme;
	assign	lsu_bus_wdata	=	lsu_rx_rs2_data;

	assign lsu_rx_ready = lsu_tx_ready;

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			lsu_tx_valid <= 1'b0;
		else if(rx_ena)
			lsu_tx_valid <= lsu_rx_opcode == `load ? 1'b1 : 1'b0;
		else if(tx_ena)
			lsu_tx_valid <= 1'b0;
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			lsu_tx_data		<=	'd0;
			lsu_tx_rd_idx	<=	'd0;
		end
		else if(rx_ena && lsu_rx_opcode == `load) begin
			lsu_tx_data		<=	lsu_bus_rdata;
			lsu_tx_rd_idx	<=	lsu_rx_rd_idx;
		end
	end

endmodule