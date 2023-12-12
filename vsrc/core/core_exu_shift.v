module core_exu_shift(
	input		[5:0]	op_type,
	input		[31:0]	reg_data_rs1,
	input		[31:0]	reg_data_rs2,
	input		[31:0]	imme,

	output				shift_enable,
	output	reg	[31:0]	shift_data_out
);

	wire [4:0] shift_opnum = imme[4:0];
	wire signal_rs1 = reg_data_rs1[31];
	
	always @(*) begin
		case(op_type)
			`op_type_sll:
				shift_data_out = reg_data_rs1 << reg_data_rs2[4:0];
			`op_type_slli:
				shift_data_out = reg_data_rs1 << shift_opnum;
			`op_type_srl:
				shift_data_out = reg_data_rs1 >> reg_data_rs2[4:0];
			`op_type_srli:
				shift_data_out = reg_data_rs1 >> shift_opnum;
			`op_type_sra:
				shift_data_out = {{32{signal_rs1}}, reg_data_rs1} >> (reg_data_rs2[4:0]);
			`op_type_srai:
				shift_data_out = {{32{signal_rs1}}, reg_data_rs1} >> shift_opnum;
			default:
				shift_data_out = 'd0;
		endcase
	end

	assign shift_enable = ((op_type==`op_type_sll) || (op_type==`op_type_slli) ||
						  (op_type==`op_type_srl) || (op_type==`op_type_srli) ||
						  (op_type==`op_type_sra) || (op_type==`op_type_srai));

endmodule