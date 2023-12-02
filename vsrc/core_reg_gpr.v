`include "inst_define.v"

module gpr (
	input				clk,
	input				rstn,

	// Read GPR
	input		[4:0]   gpr_rx_rs1_idx,
	input		[4:0]   gpr_rx_rs2_idx,

	output		[31:0]  gpr_tx_rs1,
	output		[31:0]  gpr_tx_rs2,

	// Write GPR
	// input				gpr_rx_valid,
	output				gpr_rx_ready,

	input		[4:0]   gpr_rx_rd_idx,
	input		[31:0]  gpr_rx_exu_res,
	input		[31:0]  gpr_rx_pc,
	input		[31:0]  gpr_rx_imme,
	input		[31:0]  gpr_rx_pc_seq,
	input		[31:0]  gpr_rx_mem,
	input		[31:0]  gpr_rx_csr,

	input				gpr_rx_imme_valid,
	input				gpr_rx_pc_valid,
	input				gpr_rx_pc_seq_valid,
	input				gpr_rx_csr_valid,
	input				gpr_rx_mem_valid,
	input				gpr_rx_alu_valid
);

	reg [31:0] gpr [31:0];
	// import "DPI-C" function void set_ptr_gpr(input logic [31:0] gpr []);

	wire reg_wr_en;
	wire [31:0] reg_data_rd;

	assign	reg_data_rd	=	gpr_rx_imme_valid	?	gpr_rx_imme		:
							gpr_rx_pc_valid		?	gpr_rx_pc		:
							gpr_rx_pc_seq_valid	?	gpr_rx_pc_seq	:
							gpr_rx_csr_valid	?	gpr_rx_csr		:
							gpr_rx_mem_valid	?	gpr_rx_mem		:
							gpr_rx_alu_valid	?	gpr_rx_exu_res	:	'd0;

	assign	reg_wr_en	=	gpr_rx_imme_valid || gpr_rx_pc_valid || gpr_rx_pc_seq_valid ||
							gpr_rx_csr_valid || gpr_rx_mem_valid || gpr_rx_alu_valid;

	integer i;
	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			for(i = 0 ; i < 32 ; i = i + 1)
				gpr[i] <= i == 5'd2 ? `RESET_VECTOR : 32'd0;
		else if(reg_wr_en)
			gpr[gpr_rx_rd_idx] <= (gpr_rx_rd_idx == 5'd0) ? 32'd0 : reg_data_rd;
	end

	assign gpr_tx_rs1 = gpr[gpr_rx_rs1_idx];
	assign gpr_tx_rs2 = gpr[gpr_rx_rs2_idx];

	// always @(posedge clk) begin
	// if(reg_wr_en)
	// $display("writing data %0d into %0d", $signed(reg_data_rd), gpr_rx_rd_idx);
	// end

	// always @(posedge clk) begin
	// 	if(op_type == `op_type_ecall && gpr[17] == 32'd93) begin
	// 		if(gpr[10] == 'd0)
	// 			$display("Pass!!!");
	// 		else
	// 			$display("Fail!!!");
	// 		#(1) $finish;
	// 	end
	// end

	// initial  begin
	// 	set_ptr_gpr(gpr);
	// end

endmodule //gpr