`include "inst_define.v"

module core_exu_adder(
	input       [6:0]   opcode,
	input       [31:0]  imme,
	input       [31:0]  reg_data_rs1,
	input       [31:0]  reg_data_rs2,
	input       [5:0]   op_type,

	// Adder Result
	output				adder_res_valid,
	output		[31:0]	adder_res,

	// Logical Operation Result
	output				adder_res_lt,
	output				adder_res_ltu,
	output				adder_res_neq
);

	// ADDER

	wire [31:0] adder_data_in1, adder_data_in2, adder_data_in2_sig;
	wire [31:0] adder_out;
	wire adder_carry_in, adder_carry_out;
	
	assign adder_res_valid	=	((op_type == `op_type_addi)  || (op_type == `op_type_add) || (op_type == `op_type_slti) || (op_type == `op_type_slt) ||
						  		(op_type == `op_type_sltu) || (op_type == `op_type_sltiu) || (op_type == `op_type_auipc) || (op_type == `op_type_jal) || 
								(op_type == `op_type_jalr) || (opcode == `branch) || (opcode == `store) || (opcode == `load) || (op_type == `op_type_sub));

	// adder in1可能是pc、rs1 ---- pc:auipc/jal/jalr/branch
	assign adder_data_in1 = reg_data_rs1;

	// adder in2可能是imme(auipc,jal,jalr,load,store,addi,slti,sltiu)
	assign adder_data_in2 = (opcode == `auipc || opcode == `jal || opcode == `jalr || opcode == `load || opcode == `store || op_type == `op_type_addi || op_type == `op_type_slti || op_type == `op_type_sltiu) ? imme : reg_data_rs2;
	
	// 减法(branch,slti,sltiu,slt,sub)
	// 减法情况下需要将data2取反
	assign adder_carry_in = (op_type == `op_type_sub || op_type == `op_type_slt || op_type == `op_type_slti || opcode == `branch || op_type == `op_type_sltu || op_type == `op_type_sltiu) ? 1'b1 : 1'b0;
	assign adder_data_in2_sig = adder_carry_in ? ~adder_data_in2 : adder_data_in2;
	assign {adder_carry_out, adder_out} = adder_data_in1 + adder_data_in2_sig + adder_carry_in;

	// 正-负=正、负-正=负、正-正 and 负-负：如果没有进位则=负，有进位则=正
	assign adder_res_lt = (adder_data_in1[31] && ~adder_data_in2[31]) || ((adder_data_in1[31]==adder_data_in2[31]) && ~adder_carry_out);

	// 正-正 看进位
	assign adder_res_ltu = ~adder_carry_out;
	assign adder_res_neq = (|adder_out);

	assign adder_res = 	(op_type == `op_type_slt || op_type == `op_type_slti || op_type == `op_type_blt)	?	{{31{1'b0}}, adder_res_ltu}	:
						(op_type == `op_type_bge)															?	{{31{1'b0}}, ~adder_res_lt}	:
						(op_type == `op_type_sltu || op_type == `op_type_sltiu || op_type == `op_type_bltu)	?	{{31{1'b0}}, adder_res_ltu}	:
						(op_type == `op_type_bgeu)															?	{{31{1'b0}}, ~adder_res_ltu}:
						(op_type == `op_type_bne)															?	{{31{1'b0}}, adder_res_neq}	: 
						(op_type == `op_type_beq)															?	{{31{1'b0}}, ~adder_res_neq}:	adder_out;

	// End of Adder

endmodule