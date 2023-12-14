
`ifdef	__TEST_FOR_INSTS__

module test;

	// core_ifu_top Inputs
	reg   clk = 0;
	reg   rstn = 0;
	reg   ifu_rx_valid = 0;
	reg   [31:0]  ifu_rx_pc;
	reg   ifu_tx_ready = 1;
	reg   bus_rsp_valid;
	reg   [31:0]  bus_rsp_data;
	reg   ifu_rx_bc_done = 1;
	reg   ifu_rx_bc_en = 0;

	always #(10) clk = ~clk;

	// core_ifu_top Outputs
	wire  ifu_rx_ready;
	wire  ifu_tx_valid;
	wire  [31:0]  ifu_tx_pc;
	wire  [31:0]  ifu_tx_inst;
	wire  bus_req_valid;
	wire  [31:0]  bus_req_addr;

	core_ifu_top  u_core_ifu_top (
		.clk                     ( clk                ),
		.rstn                    ( rstn               ),
		.ifu_rx_valid            ( ifu_rx_valid       ),
		.ifu_rx_pc               ( ifu_rx_pc          ),
		.ifu_tx_ready            ( ifu_tx_ready       ),
		.bus_rsp_valid           ( bus_rsp_valid      ),
		.bus_rsp_data            ( bus_rsp_data       ),
		.ifu_rx_bc_done          ( ifu_rx_bc_done     ),
		.ifu_rx_bc_en            ( ifu_rx_bc_en       ),

		.ifu_rx_ready            ( ifu_rx_ready       ),
		.ifu_tx_valid            ( ifu_tx_valid       ),
		.ifu_tx_pc               ( ifu_tx_pc          ),
		.ifu_tx_inst             ( ifu_tx_inst        ),
		.bus_req_valid           ( bus_req_valid      ),
		.bus_req_addr            ( bus_req_addr       )
	);

	task readpc;
		input	[31:0]	pc;
		begin
			@(posedge clk) begin
				ifu_rx_valid <= 1;
				ifu_rx_pc <= pc;
			end
		end
	endtask

	task pcr_stall;
		input	[31:0]	cycle;
		repeat(cycle) begin
			@(posedge clk) begin
				ifu_rx_valid <= 0;
			end
		end
	endtask

	task idu_stall;
		begin
			ifu_tx_ready <= 0;
		end
	endtask

	initial begin
		#(40) rstn = 1;
		readpc(32'd0);
		readpc(32'd1);
		pcr_stall(1);
		readpc(2);
		readpc(3);
		readpc(4);
		readpc(5);
		readpc(6);
		readpc(7);
		readpc(5);
		readpc(2);
		readpc(3);
		readpc(4);
		pcr_stall(5);
		$finish;
	end

	initial begin
		$dumpfile("waveform.vcd");
		$dumpvars(0, test);
	end

endmodule

`endif