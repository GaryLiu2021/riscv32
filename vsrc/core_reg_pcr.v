`include "inst_define.v"

module reg_pcr (
	// Global signal
	input               clk,
	input               rstn,

	// Signals from EXU and LSU
	input               pcr_rx_valid,
	output  reg         pcr_rx_ready,

	input               pcr_rx_bc_valid,
	input       [31:0]  pcr_rx_bc_pc,

	// Signals to IFU
	output  reg         pcr_tx_valid,
	input               pcr_tx_ready,

	output  reg [31:0]  pcr_tx_pc
);

	wire [31:0] pcr_seq_pc = pcr_tx_pc + 32'd4;

	wire tx_ena = pcr_tx_valid && pcr_tx_ready;
	wire rx_ena = pcr_rx_valid && pcr_rx_ready;

	localparam  S_RX_PEND	=	2'd0,
				S_TX_PEND	=	2'd1;

	reg	s_pres;
	reg	s_next;

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			s_pres <= 'd0;
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
				if(rx_ena)
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
				pcr_rx_ready = rstn;
			S_TX_PEND:
				pcr_rx_ready = tx_ena;
		endcase
	end

	// As long as enter the S_TX_PEND, we can assert pcr_tx_valid = 1.
	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			pcr_tx_valid <= 1'b0;
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena)
					pcr_tx_valid <= 1'b1;
				else
					pcr_tx_valid <= 1'b0;
			S_TX_PEND:
				if(rx_ena)
					pcr_tx_valid <= 1'b1;
				else if(tx_ena)
					pcr_tx_valid <= 1'b0;
		endcase
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			pcr_tx_pc <= `zero_word + `RESET_VECTOR;
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena)
					pcr_tx_pc <= pcr_rx_bc_valid ? pcr_rx_bc_pc : pcr_seq_pc;
			S_TX_PEND:
				if(rx_ena)
					pcr_tx_pc <= pcr_rx_bc_valid ? pcr_rx_bc_pc : pcr_seq_pc;
				// In other cases, pc would be invalid.
		endcase
	end

endmodule //reg_pcr