`include "inst_define.v"

module core_exu_top (

	// Global Signal
	input               clk,
	input               rstn,

	// Interface with IDU
	input               exu_rx_valid,
	output	reg			exu_rx_ready,

	input       [6:0]   exu_rx_opcode,
	input       [31:0]  exu_rx_imme,
	input       [31:0]  exu_rx_rs1,
	input       [31:0]  exu_rx_rs2,
	input       [31:0]  exu_rx_pc,
	input       [5:0]   exu_rx_op_type,
	input		[4:0]	exu_rx_rd_idx,

	// Interface with WBU
	output	reg			exu_tx_valid,
	input				exu_tx_ready,

	output  reg [31:0]  exu_tx_exu_res,
	output	reg	[31:0]	exu_tx_pc,
	output	reg	[31:0]	exu_tx_pc_seq,
	output	reg	[31:0]	exu_tx_imme,
	
	// Tell GPR which data is valid to write
	output	reg			exu_tx_imme_valid,		//	Tell GPR to write imme
	output	reg			exu_tx_pc_valid,		//	Tell GPR to write pc(auipc)
	output	reg			exu_tx_pc_seq_valid,	//	Tell GPR to wirte pc + 4
	output	reg			exu_tx_csr_valid,		//	Tell GPR to write CSR
	output	reg			exu_tx_alu_valid,		//	Tell GPR to write ALU result

	output	reg			exu_tx_rd_idx,			//	Tell GPR the rd idx

	output				exu_tx_bc_en,			//	Tell IFU jump or not
	output	reg			exu_tx_bc_done,			//	Tell IFU branch instruction is done
	output  reg [31:0]  exu_tx_bc_pc			//	Tell IFU the addr to jump to
);

	/*
	 * Status Control
	 
	 *	S_RX_PEND:	Waiting for a valid input data.
	 *	S_TX_PEND:	Waiting for the data piped to next pipe.

	 */
	
	reg s_pres;
	reg s_next;

	localparam	S_RX_PEND	=	0,
				S_TX_PEND	=	1;

	wire tx_ena = exu_tx_valid && exu_tx_ready;
	wire rx_ena = exu_rx_valid && exu_rx_ready;

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			s_pres <= S_RX_PEND;
		else
			s_pres <= s_next;
	end

	always @(*) begin
		case(s_pres)
			S_RX_PEND:
				if(rx_ena)
					s_next = S_TX_PEND;
				else
					s_next = S_RX_PEND;
			S_TX_PEND:
				if(rx_ena && tx_ena)
					s_next = S_TX_PEND;
				else if(!rx_ena && tx_ena)
					s_next = S_RX_PEND;
				else
					s_next = S_TX_PEND;
		endcase
	end

	always @(*) begin
		case(s_pres)
			S_RX_PEND:
				exu_rx_ready = exu_tx_ready;
			S_TX_PEND:
				exu_rx_ready = tx_ena;
		endcase
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			exu_tx_valid <= 1'b0;
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena)
					exu_tx_valid <= 1'b1;
			S_TX_PEND:
				if(rx_ena && tx_ena)
					exu_tx_valid <= 1'b1;
				else if(!rx_ena && tx_ena)
					exu_tx_valid <= 1'b0;
		endcase
	end

	/*
	 * 32 bit Adder
	 */
	wire  adder_res_valid;
	wire  [31:0]  adder_res;
	wire  adder_res_lt;
	wire  adder_res_ltu;
	wire  adder_res_neq;

	core_exu_adder  u_core_exu_adder (
		.opcode                  ( exu_rx_opcode     ),
		.imme                    ( exu_rx_imme       ),
		.reg_data_rs1            ( exu_rx_rs1        ),
		.reg_data_rs2            ( exu_rx_rs2      ),
		.op_type                 ( exu_rx_op_type    ),

		.adder_res_valid         ( adder_res_valid   ),
		.adder_res               ( adder_res         ),
		.adder_res_lt            ( adder_res_lt      ),
		.adder_res_ltu           ( adder_res_ltu     ),
		.adder_res_neq           ( adder_res_neq     )
	);

	assign exu_tx_bc_en = exu_tx_bc_done && exu_tx_exu_res[0];

	/*
	 * PC Adder
	 ! Operating PC REG
	 */
	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			exu_tx_bc_pc <= `zero_word;
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena)
					exu_tx_bc_pc <= (exu_rx_op_type == `op_type_jalr) ? (exu_rx_rs1 + exu_rx_imme) & (~32'b1) : exu_rx_pc + exu_rx_imme;
			S_TX_PEND:
				if(rx_ena && tx_ena)
					exu_tx_bc_pc <= (exu_rx_op_type == `op_type_jalr) ? (exu_rx_rs1 + exu_rx_imme) & (~32'b1) : exu_rx_pc + exu_rx_imme;
		endcase
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			exu_tx_bc_done <= 1'b0;
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena)
					exu_tx_bc_done <= (exu_rx_opcode == `jal || exu_rx_opcode == `jalr || exu_rx_opcode == `branch);
			S_TX_PEND:
				if(rx_ena && tx_ena)
					exu_tx_bc_done <= (exu_rx_opcode == `jal || exu_rx_opcode == `jalr || exu_rx_opcode == `branch);
				else if(!rx_ena && tx_ena)
					exu_tx_bc_done <= 1'b0;
		endcase
	end


	/*
	 * Logical Operation
	 */

	wire  logic_enable;
	wire  [31:0]  logic_data_out;

	core_exu_logic  u_core_exu_logic (
		.op_type                 ( exu_rx_op_type   ),
		.reg_data_rs1            ( exu_rx_rs1       ),
		.reg_data_rs2            ( exu_rx_rs2     ),
		.imme                    ( exu_rx_imme      ),

		.logic_enable            ( logic_enable     ),
		.logic_data_out          ( logic_data_out   )
	);

	/*
	 * Shift Operation
	 */
	
	wire  shift_enable;
	wire  [31:0]  shift_data_out;

	core_exu_shift  u_core_exu_shift (
		.op_type                 ( exu_rx_op_type   ),
		.reg_data_rs1            ( exu_rx_rs1       ),
		.reg_data_rs2            ( exu_rx_rs2     ),
		.imme                    ( exu_rx_imme      ),

		.shift_enable            ( shift_enable     ),
		.shift_data_out          ( shift_data_out   )
	);

	reg		[31:0]	exu_tx_exu_res_w;

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			exu_tx_exu_res <= `zero_word;
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena)
					exu_tx_exu_res <= exu_tx_exu_res_w;
			S_TX_PEND:
				if(rx_ena && tx_ena)
					exu_tx_exu_res <= exu_tx_exu_res_w;
		endcase
	end

	always @(*) begin
		case(1'b1)
			adder_res_valid:	exu_tx_exu_res_w = adder_res;
			logic_enable: 		exu_tx_exu_res_w = logic_data_out;
			shift_enable: 		exu_tx_exu_res_w = shift_data_out;
			default:			exu_tx_exu_res_w = `zero_word;
		endcase
	end

	wire	exu_tx_imme_sel		=	exu_rx_op_type == `op_type_lui;
	wire	exu_tx_pc_sel		=	exu_rx_op_type == `op_type_auipc;
	wire	exu_tx_pc_seq_sel	=	exu_rx_op_type == `op_type_jal || exu_rx_op_type == `op_type_jalr;
	wire	exu_tx_csr_sel		=	exu_rx_opcode == `system && (exu_rx_op_type != `op_type_ecall) && (exu_rx_op_type != `op_type_ebreak);
	wire	exu_tx_alu_sel		=	exu_rx_opcode == `alui || exu_rx_opcode == `alur;

	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			exu_tx_imme_valid	<= 1'b0;
			exu_tx_pc_valid		<= 1'b0;
			exu_tx_pc_seq_valid	<= 1'b0;
			exu_tx_csr_valid	<= 1'b0;
			exu_tx_alu_valid	<= 1'b0;
		end
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena) begin
					exu_tx_imme_valid	<=	exu_tx_imme_sel		?	1'b1	:	1'b0;
					exu_tx_pc_valid		<=	exu_tx_pc_sel		?	1'b1	:	1'b0;
					exu_tx_pc_seq_valid	<=	exu_tx_pc_seq_sel	?	1'b1	:	1'b0;
					exu_tx_csr_valid	<=	exu_tx_csr_sel		?	1'b1	:	1'b0;
					exu_tx_alu_valid	<=	exu_tx_alu_sel		?	1'b1	:	1'b0;
				end
			S_TX_PEND:
				if(rx_ena) begin
					exu_tx_imme_valid	<=	exu_tx_imme_sel		?	1'b1	:	1'b0;
					exu_tx_pc_valid		<=	exu_tx_pc_sel		?	1'b1	:	1'b0;
					exu_tx_pc_seq_valid	<=	exu_tx_pc_seq_sel	?	1'b1	:	1'b0;
					exu_tx_csr_valid	<=	exu_tx_csr_sel		?	1'b1	:	1'b0;
					exu_tx_alu_valid	<=	exu_tx_alu_sel		?	1'b1	:	1'b0;
				end
				else if(tx_ena) begin
					exu_tx_imme_valid	<= 1'b0;
					exu_tx_pc_valid		<= 1'b0;
					exu_tx_pc_seq_valid	<= 1'b0;
					exu_tx_csr_valid	<= 1'b0;
					exu_tx_alu_valid	<= 1'b0;
				end
		endcase
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			exu_tx_pc		<= 'd0;
			exu_tx_pc_seq	<= 'd0;
			exu_tx_imme		<= 'd0;
		end
		else if(rx_ena) begin
			if(exu_tx_pc_sel)
				exu_tx_pc <= exu_rx_pc;
			if(exu_tx_pc_seq_sel)
				exu_tx_pc <= exu_rx_pc + 32'd4;
			if(exu_tx_imme_sel)
				exu_tx_imme <= exu_rx_imme;
		end
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			exu_tx_rd_idx <= 'd0;
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena)
					exu_tx_rd_idx <= exu_rx_rd_idx;
			S_TX_PEND:
				if(rx_ena)
					exu_tx_rd_idx <= exu_rx_rd_idx;
		endcase
	end

endmodule //core_exu_top