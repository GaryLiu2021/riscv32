`include "inst_define.v"

module core_ifu_top(
	// Global Signal
	input					clk,
	input					rstn,

	// PCR to IFU
	input					ifu_rx_valid,
	input		[31:0]		ifu_rx_pc,
	output					ifu_rx_ready,

	// IFU to IDU
	output					ifu_tx_valid,
	output		[31:0]		ifu_tx_pc,
	output		[31:0]		ifu_tx_inst,
	input					ifu_tx_ready,
	
	// IFU to BUS
	output					bus_req_valid,
	output		[31:0]		bus_req_addr,

	// BUS to IFU
	input					bus_rsp_valid,
	input		[31:0]		bus_rsp_data,

	// EXU to IFU
	input					ifu_rx_bc_done,
	input					ifu_rx_bc_en
);

	wire  lsu_rx_ready;
	wire  lsu_tx_valid;
	wire  lsu_rx_valid;
	wire  lsu_tx_ready;
	wire  [31:0]  lsu_rx_addr;
	wire  [31:0]  lsu_tx_inst;

	core_ifu_lsu  u_core_ifu_lsu (
		.clk                     ( clk             ),
		.rstn                    ( rstn            ),
		.lsu_rx_valid            ( lsu_rx_valid    ),
		.lsu_rx_addr             ( lsu_rx_addr     ),
		.bus_rsp_valid           ( bus_rsp_valid   ),
		.bus_rsp_data            ( bus_rsp_data    ),
		.lsu_tx_ready            ( lsu_tx_ready    ),

		.lsu_rx_ready            ( lsu_rx_ready    ),
		.bus_req_valid           ( bus_req_valid   ),
		.bus_req_addr            ( bus_req_addr    ),
		.lsu_tx_valid            ( lsu_tx_valid    ),
		.lsu_tx_inst             ( lsu_tx_inst     )
	);

	/*
	 * A FIFO is needed because it should sync with the
	 * instruction read from icache.
	 */
	wire  fifo_rx_valid;
	wire  fifo_tx_ready;
	wire  [31:0]  fifo_rx_data;
	wire  [31:0]  fifo_tx_data;
	wire  fifo_rx_ready;
	wire  fifo_tx_valid;

	FIFO #(
		.DATA_WIDTH ( 32 ),
		.DEPTH      ( 8 ))
	pc_buffer (
		.clk                     ( clk             ),
		.rstn                    ( rstn            ),
		.fifo_rx_valid           ( fifo_rx_valid   ),
		.fifo_tx_ready           ( fifo_tx_ready   ),
		.fifo_rx_data            ( fifo_rx_data    ),

		.fifo_tx_data            ( fifo_tx_data    ),
		.fifo_rx_ready           ( fifo_rx_ready   ),
		.fifo_tx_valid           ( fifo_tx_valid   )
	);

	/* 
	 *	MODULE:	core_ifu_pre_dec
	 *	  ROLE:	predecode the instruction and judge to stall the pipeline or not
	 */
	wire  [6:0]  pre_dec_opcode;

	core_ifu_pre_dec  u_core_ifu_pre_dec (
		.pre_dec_rx_inst         ( lsu_tx_inst   ),

		.pre_dec_opcode          ( pre_dec_opcode    )
	);

	/*
	 * State Control
	 */	

	reg		[1:0]	s_pres;
	reg		[1:0]	s_next;

	localparam		S_RX_PEND	=	0,
					S_TX_PEND	=	1,
					S_BC_PEND	=	2,	//	Waiting for branch result
					S_FS_PEND	=	3;	//	Flushing discarded instructions

	wire rx_ena = ifu_rx_valid && ifu_rx_ready;
	wire tx_ena = ifu_tx_valid && ifu_tx_ready;
	wire inst_is_branch = lsu_tx_valid && (pre_dec_opcode == `jal || pre_dec_opcode == `jalr || pre_dec_opcode == `branch);

	always @(posedge clk) begin
		if(rstn && inst_is_branch)
			$display("IFU: [0x%h] Identified a branch inst...", ifu_tx_pc);
	end

	reg		[2:0]	rx_counter;
	reg		[2:0]	tx_counter;
	reg		[2:0]	fs_counter;
	reg		[2:0]	fs_num;
	
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
				if(inst_is_branch && tx_ena)
					s_next = S_BC_PEND;
				else if(inst_is_branch && !tx_ena)
					s_next = S_TX_PEND;
				else if(tx_ena && rx_ena)
					s_next = S_TX_PEND;
				else if(tx_ena && tx_counter != rx_counter - 1)
					s_next = S_TX_PEND;
				else if(tx_ena && tx_counter == rx_counter - 1)
					s_next = S_RX_PEND;
				else
					s_next = S_TX_PEND;
			S_BC_PEND:
				if(ifu_rx_bc_done) begin
					if(ifu_rx_bc_en)
						s_next = S_FS_PEND;
					else if(rx_ena)
						s_next = S_TX_PEND;
					else if(tx_counter != rx_counter)
						s_next = S_TX_PEND;
					else if(tx_counter == rx_counter)
						s_next = S_RX_PEND;
					else
						s_next = S_TX_PEND;
				end
				else
					s_next = S_BC_PEND;
			S_FS_PEND:
				if(fs_counter == fs_num - 1)
					if(rx_ena)
						s_next = S_TX_PEND;
					else if(tx_counter + fs_counter == rx_counter - 1)
						s_next = S_RX_PEND;
					else
						s_next = S_TX_PEND;
				else
					s_next = S_FS_PEND;
		endcase
	end

	/*
	 * Update Counters
	 */
	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			rx_counter <= 'd0;
			tx_counter <= 'd0;
			fs_counter <= 'd0;
			fs_num <= 'd0;
		end
		else case(s_pres)
			S_RX_PEND:
				if(rx_ena)
					rx_counter <= rx_counter + 1;
			S_TX_PEND: begin
				if(tx_ena && inst_is_branch)
					if(rx_ena)
						fs_num <= rx_counter - tx_counter;
					else
						fs_num <= rx_counter - tx_counter - 1;
				if(rx_ena)
					rx_counter <= rx_counter + 1;
				if(tx_ena)
					tx_counter <= tx_counter + 1;
			end
			S_BC_PEND:
				;
			S_FS_PEND: begin
				if(fs_counter == fs_num - 1) begin
					tx_counter <= tx_counter + fs_num;
					fs_counter <= 'd0;
				end else
					fs_counter <= fs_counter + 1;
				if(rx_ena)
					rx_counter <= rx_counter + 1;
			`ifdef __LOG_ENABLE__
				$display("IFU: Flushing...");
			`endif
			end
		endcase
	end
	

	/*
	 * Assignments
	 */
	assign lsu_rx_addr = ifu_rx_pc;
	assign fifo_rx_data = ifu_rx_pc;

	/*
	 * Only when lsu and fifo are both ready, shoule ifu recv new pc.
	 */
	assign ifu_rx_ready = lsu_rx_ready && fifo_rx_ready && s_pres != S_BC_PEND && ifu_tx_ready;

	/*
	 * One's recv data is not valid if:
	 	1.	pcr is not valid
		2.	one peer is not ready
	 */
	assign lsu_rx_valid = ifu_tx_ready && s_pres != S_BC_PEND && ifu_rx_valid && fifo_rx_ready;	// If ifu tx ready is low, tell submodule to not recv
	assign fifo_rx_valid = ifu_tx_ready && s_pres != S_BC_PEND && ifu_rx_valid && lsu_rx_ready;
	
	/*
	 * Update lsu and fifo control signals

	 * When present status is S_BC_PEND, the pipeline is stalled.
	 * For lsu and fifo:
	 * One is stalled if:
		1. idu is not ready
		2. present state is S_BC_PEND
		3. one of other peers is not valid
	 */
	assign	lsu_tx_ready 	= 	s_pres == S_RX_PEND	? 	ifu_tx_ready :
								s_pres == S_BC_PEND	?	1'b0 :
								s_pres == S_FS_PEND ?	1'b1 :
														ifu_tx_ready && fifo_tx_valid;

	assign	fifo_tx_ready 	= 	s_pres == S_RX_PEND	? 	ifu_tx_ready :
								s_pres == S_BC_PEND	?	1'b0 :
								s_pres == S_FS_PEND ?	1'b1 :
														ifu_tx_ready && lsu_tx_valid;

	/*
	 * Only when lsu and fifo are both valid, should ifu pass new inst and pc.
	 * Tx data is valid when:
	 	1.	lsu and fifo are both valid
		2.	Present state is S_TX_PEND
	 */
	assign ifu_tx_valid = s_pres == S_TX_PEND ?	lsu_tx_valid && fifo_tx_valid :
												1'b0;
	assign ifu_tx_inst = lsu_tx_inst;
	assign ifu_tx_pc = fifo_tx_data;

	
endmodule
