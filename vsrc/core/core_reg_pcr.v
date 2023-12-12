`include "inst_define.v"

module reg_pcr (
	// Global signal
	input					clk,
	input					rstn,

	// from EXU and LSU
	// input					pcr_rx_valid,

	input					pcr_rx_bc_valid,
	output					pcr_rx_bc_ready,
	input		[31:0]		pcr_rx_bc_pc,

	// to IFU
	output	reg				pcr_tx_valid,
	input					pcr_tx_ready,

	output	reg	[31:0]		pcr_tx_pc
);

	reg rstn_del;
	always @(posedge clk) begin
		rstn_del <= rstn;
	end

	/*
	 * Calculate sequential next pc
	 */
	wire			seq_pc_valid	=	rstn;
	wire			seq_pc_ready	=	pcr_tx_ready && rstn_del;	//	Cannot receive pc_seq when machine is just turned on, so use rstn_del
	wire	[31:0]	pcr_seq_pc		=	pcr_tx_pc + 32'd4;

	assign	pcr_rx_bc_ready	=	rstn;

	wire	rx_bc_pc_ena	=	pcr_rx_bc_valid && pcr_rx_bc_ready;
	wire	rx_seq_pc_ena	=	seq_pc_valid && seq_pc_ready;

	wire	tx_ena			=	pcr_tx_valid && pcr_tx_ready;
	wire	rx_ena			=	rx_bc_pc_ena || rx_seq_pc_ena;

	localparam  S_RX_PEND	=	2'd0,
				S_TX_PEND	=	2'd1,
				S_BC_PEND	=	2'd2;

	reg	[1:0]	s_pres;
	reg	[1:0]	s_next;

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
				if(tx_ena && rx_ena)
					s_next = S_TX_PEND;
				else if(tx_ena && !rx_ena)
					s_next = S_RX_PEND;
				else
					s_next = S_TX_PEND;
		endcase
	end
	

	// As long as enter the S_TX_PEND, we can assert pcr_tx_valid = 1.
	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			pcr_tx_valid <= 1'b0;
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena || rstn)
					pcr_tx_valid <= 1'b1;
				else
					pcr_tx_valid <= 1'b0;
			S_TX_PEND:
				if(tx_ena && rx_ena)
					pcr_tx_valid <= 1'b1;
				else if(tx_ena && !rx_ena)
					pcr_tx_valid <= 1'b0;
		endcase
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			pcr_tx_pc <= `zero_word + `RESET_VECTOR;
		else case(s_pres)
			S_RX_PEND:
				if(rx_bc_pc_ena) begin
					pcr_tx_pc <= pcr_rx_bc_pc;
				`ifdef __LOG_ENABLE__
					$display("PCR: Jumping to [0x%h]", pcr_rx_bc_pc);
				`endif
				end
				else if(rx_seq_pc_ena)
					pcr_tx_pc <= pcr_seq_pc;
			S_TX_PEND:
				if(rx_bc_pc_ena) begin
					pcr_tx_pc <= pcr_rx_bc_pc;
				`ifdef __LOG_ENABLE__
					$display("PCR: Jumping to [0x%h]", pcr_rx_bc_pc);
				`endif
				end
				else if(rx_seq_pc_ena)
					pcr_tx_pc <= pcr_seq_pc;
				// In other cases, pc would be invalid.
		endcase
	end

endmodule //reg_pcr