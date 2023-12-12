module core_ctrl_scb(
	// Global Signal
	input 				clk,
	input				rstn,

	// Emit Instruction
	input				scb_emit_idx_valid,		//	IDU read valid
	input				scb_emit_rs1_vld,		//	RS1 read valid
    input       [4:0]   scb_emit_rs1_idx,
	input				scb_emit_rs2_vld,		//	RS2 read valid
    input       [4:0]   scb_emit_rs2_idx,
	input				scb_emit_rd_vld,		//	RD read valid
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
		else begin
			if(scb_emit_idx_valid && scb_emit_rd_vld && reg_rs_ready)
				score_board[scb_emit_rd_idx] <= 1'b1;
			if(scb_ret_reg_valid)
				score_board[scb_ret_reg_idx] <= 1'b0;
		end
	end

	/*
	 * If source reg is not ready, then do not push the data to the next pipe.
	 * i.e. Resolve the RAW hazards
	 */
	wire	reg_rs1_ready	=	scb_emit_rs1_vld	?	~score_board[scb_emit_rs1_idx]	:	1'b1;
	wire	reg_rs2_ready	=	scb_emit_rs2_vld	?	~score_board[scb_emit_rs2_idx]	:	1'b1;
	wire	reg_rd_ready	=	scb_emit_rd_vld		?	~score_board[scb_emit_rd_idx]	:	1'b1;

	assign reg_rs_ready = reg_rs1_ready && reg_rs2_ready && reg_rd_ready;

	always @(posedge clk) begin
		if(rstn)
			case(1)
				!reg_rs1_ready:	$display("SCB: Rs1 gpr[%0d] busy!", scb_emit_rs1_idx);
				!reg_rs2_ready:	$display("SCB: Rs2 gpr[%0d] busy!", scb_emit_rs2_idx);
				!reg_rd_ready:	$display("SCB: Rd gpr[%0d] busy!", scb_emit_rd_idx);
			endcase
	end

endmodule