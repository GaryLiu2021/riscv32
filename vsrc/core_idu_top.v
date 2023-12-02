module core_idu_top(
	// Global Signal
	input				clk,
	input				rstn,

	// Interface with prev pipe
	input		[31:0]	idu_rx_pc,
	input		[31:0]	idu_rx_inst,
	input				idu_rx_valid,
	output				idu_rx_ready,

	// Interface with global purpose registers(GPR)
	output		[4:0]	idu_tx_rs1_idx,
	output		[4:0]	idu_tx_rs2_idx,
	input		[31:0]	idu_rx_rs1,
	input		[31:0]	idu_rx_rs2,

	// Interface to Score Board
	input				reg_rs_ready,

	// Interface with next pipe
	output	reg			idu_tx_valid,
	input				idu_tx_ready,

	output	reg	[31:0]	idu_tx_pc,
	output  reg [6:0]   idu_tx_opcode,
	output  reg [2:0]   idu_tx_func3,
	output  reg         idu_tx_func7,
	output  reg [4:0]   idu_tx_rs1,
	output  reg [4:0]   idu_tx_rs2,
	output  reg [4:0]   idu_tx_rd_idx,
	output  reg [5:0]   idu_tx_op_type,
	output  reg [31:0]  idu_tx_imme,

	output				idu_tx_to_exu,
	output				idu_tx_to_lsu
);

	// core_idu_dec Outputs
	wire  [6:0]  opcode;
	wire  [2:0]  func3;
	wire  func7;
	wire  [4:0]  reg_addr_rd;
	wire  [5:0]  op_type;
	wire  [31:0]  imme;

	core_idu_dec  u_core_idu_dec (
		.inst                    ( idu_rx_inst    ),

		.opcode                  ( opcode         ),
		.func3                   ( func3          ),
		.func7                   ( func7          ),
		.reg_addr_rs1            ( idu_tx_rs1_idx ),
		.reg_addr_rs2            ( idu_tx_rs2_idx ),
		.reg_addr_rd             ( reg_addr_rd    ),
		.op_type                 ( op_type        ),
		.imme                    ( imme           )
	);

	reg reg_rs_ready_del;
	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			reg_rs_ready_del <= 1'b1;
		else
			reg_rs_ready_del <= reg_rs_ready;
	end

	assign idu_rx_ready = reg_rs_ready_del && idu_tx_ready;

	reg [1:0]	s_pres;
	reg	[1:0]	s_next;

	localparam	S_RX_PEND	=	0,
				S_RS_PEND	=	1,	// Waiting for RS REG ready
				S_TX_PEND	=	2;

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			s_pres <= S_RX_PEND;
		else
			s_pres <= s_next;
	end

	wire rx_ena = idu_rx_valid && idu_rx_ready;
	wire tx_ena = idu_tx_valid && idu_tx_ready;

	always @(*) begin
		case(s_pres)
			S_RX_PEND:
				if(rx_ena && reg_rs_ready)
					s_next = S_TX_PEND;
				else if(rx_ena && !reg_rs_ready)
					s_next = S_RS_PEND;
				else
					s_next = S_RX_PEND;
			S_RS_PEND:
				if(reg_rs_ready)
					s_next = S_TX_PEND;
				else
					s_next = S_RS_PEND;
			S_TX_PEND:
				if(tx_ena && rx_ena)
					s_next = reg_rs_ready ? S_TX_PEND : S_RS_PEND;
				else if(tx_ena && !rx_ena)
					s_next = S_RX_PEND;
				else
					s_next = S_TX_PEND;
			default:
				s_next = S_RX_PEND;
		endcase
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			idu_tx_valid <= 1'b0;
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena && reg_rs_ready)
					idu_tx_valid <= 1'b1;
				else if(rx_ena && !reg_rs_ready)
					idu_tx_valid <= 1'b0;
			S_RS_PEND:
				if(reg_rs_ready)
					idu_tx_valid <= 1'b1;
			S_TX_PEND:
				if(tx_ena && rx_ena)
					idu_tx_valid <= reg_rs_ready ? 1'b1 : 1'b0;
				else if(tx_ena && !rx_ena)
					idu_tx_valid <= 1'b0;
		endcase
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			idu_tx_pc		<=	'd0;
			idu_tx_opcode	<=	'd0;
			idu_tx_func3	<=	'd0;
			idu_tx_func7	<=	'd0;
			idu_tx_rs1		<=	'd0;
			idu_tx_rs2		<=	'd0;
			idu_tx_rd_idx	<=	'd0;
			idu_tx_op_type	<=	'd0;
			idu_tx_imme		<=	'd0;
		end
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena && reg_rs_ready) begin
					idu_tx_pc		<=	idu_rx_pc;
					idu_tx_opcode	<=	opcode;
					idu_tx_func3	<=	func3;
					idu_tx_func7	<=	func7;
					idu_tx_rs1		<=	idu_rx_rs1;
					idu_tx_rs2		<=	idu_rx_rs2;
					idu_tx_rd_idx	<=	reg_addr_rd;
					idu_tx_op_type	<=	op_type;
					idu_tx_imme		<=	imme;
				end
			S_RS_PEND:
				if(reg_rs_ready) begin
					idu_tx_pc		<=	idu_rx_pc;
					idu_tx_opcode	<=	opcode;
					idu_tx_func3	<=	func3;
					idu_tx_func7	<=	func7;
					idu_tx_rs1		<=	idu_rx_rs1;
					idu_tx_rs2		<=	idu_rx_rs2;
					idu_tx_rd_idx	<=	reg_addr_rd;
					idu_tx_op_type	<=	op_type;
					idu_tx_imme		<=	imme;
				end
			S_TX_PEND:
				if(tx_ena && rx_ena && reg_rs_ready) begin
					idu_tx_pc		<=	idu_rx_pc;
					idu_tx_opcode	<=	opcode;
					idu_tx_func3	<=	func3;
					idu_tx_func7	<=	func7;
					idu_tx_rs1		<=	idu_rx_rs1;
					idu_tx_rs2		<=	idu_rx_rs2;
					idu_tx_rd_idx	<=	reg_addr_rd;
					idu_tx_op_type	<=	op_type;
					idu_tx_imme		<=	imme;
				end
		endcase
	end

	assign	idu_tx_to_exu	=	idu_tx_valid && (idu_tx_opcode != `load && idu_tx_opcode != `store);
	assign	idu_tx_to_lsu	=	idu_tx_valid && (idu_tx_opcode == `load	|| idu_tx_opcode == `store);

endmodule