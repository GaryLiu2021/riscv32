`include "inst_define.v"

module dummy_icache (
	// Global Signal
	input				clk,
	input				rstn,

	// Interface
	input				rx_valid,
	output	reg			rx_ready,
	input		[31:0]	rx_addr,

	output	reg			tx_valid,
	input				tx_ready,
	output	reg	[31:0]	tx_data
);

	/*
	 * Store Logic
	 */

	//! IFetch only need load instructions.
	
	/*
	 * Load Logic
	 */
	
	reg [31:0] memory [31:0];

	wire rx_ena = rx_valid && rx_ready;
	wire tx_ena = tx_valid && tx_ready;

	reg s_pres;
	reg s_next;

	localparam	S_RX_PEND = 0,
				S_TX_PEND = 1;

	always @(posedge clk or negedge rstn)
		if(!rstn)
			s_pres <= S_RX_PEND;
		else
			s_pres <= s_next;
	
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
			S_RX_PEND:	rx_ready = tx_ready;
			S_TX_PEND:	rx_ready = tx_ena;
		endcase
	end

	always @(posedge clk or negedge rstn)
		if(!rstn)
			inst <= 'd0;
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena)
					inst <= memory[pc];
			S_TX_PEND:
				if(rx_ena && tx_ena)
					inst <= memory[pc];
		endcase
	
	always @(posedge clk or negedge rstn)
		if(!rstn)
			tx_valid <= 1'b0;
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena)
					tx_valid <= 1'b1;
			S_TX_PEND:
				if(rx_ena && tx_ena)
					tx_valid <= 1'b1;
				else if(!rx_ena && tx_ena)
					tx_valid <= 1'b0;
		endcase


endmodule //dummy_icache
