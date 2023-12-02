module core_ifu_pre_dec(
	input		[31:0]	pre_dec_rx_inst,

	output		[6:0]	pre_dec_opcode
);

	assign pre_dec_opcode = pre_dec_rx_inst[6:0];

endmodule