module core_ctrl_scb(
	// Global Signal
	input 				clk,
	input				rstn,

	// Emit Instruction
    input       [4:0]   scb_emit_rs1_idx,
    input       [4:0]   scb_emit_rs2_idx,
	input		[4:0]	scb_emit_rd_idx,

	// Retire Instruction
	input		[4:0]	scb_ret_reg_idx,
	input				scb_ret_reg_valid,

	output				reg_rs_ready
);

	reg [31:0] score_board; // To store the register is ready(0) or busy(1)

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			score_board <= 'd0;
		/*
		 * If the same REG need emit and retire simultaneously,
		 * keep the score of the REG being busy, which is shown
		 * as the 'if' sequence below.
		 */
		else if(reg_rs_ready)
			score_board[scb_emit_rd_idx] <= 1'b1;
		else if(scb_ret_reg_valid)
			score_board[scb_ret_reg_idx] <= 1'b0;
	end

	/*
	 * If source reg is not ready, then do not push the data to the next pipe.
	 * i.e. Resolve the RAW hazards
	 */
	assign reg_rs_ready = ~(score_board[scb_emit_rs1_idx] || score_board[scb_emit_rs2_idx] || score_board[scb_emit_rd_idx]);

endmodule