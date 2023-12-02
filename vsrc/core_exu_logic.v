/*
 * This module is used for logical operations.
 ! This module is pure combinational-logic.
 */

module core_exu_logic(
	input		[5:0]	op_type,
	input		[31:0]	reg_data_rs1,
	input		[31:0]	reg_data_rs2,
	input		[31:0]	imme,

	output				logic_enable,
	output	reg	[31:0]	logic_data_out
);

	always @(*) begin
		case(op_type)
			`op_type_xori:
				logic_data_out = reg_data_rs1 ^ imme;
			`op_type_xor:
				logic_data_out = reg_data_rs1 ^ reg_data_rs2;
			`op_type_ori:
				logic_data_out = reg_data_rs1 | imme;
			`op_type_or:
				logic_data_out = reg_data_rs1 | reg_data_rs2;
			`op_type_andi:
				logic_data_out = reg_data_rs1 & imme;
			`op_type_and:
				logic_data_out = reg_data_rs1 & reg_data_rs2;
			default: logic_data_out = 32'd0;
		endcase
	end

	assign logic_enable = ((op_type==`op_type_xori) || (op_type==`op_type_xor) ||
						  (op_type==`op_type_or)  || (op_type==`op_type_ori) ||
						  (op_type==`op_type_andi) || (op_type==`op_type_and));
	
endmodule