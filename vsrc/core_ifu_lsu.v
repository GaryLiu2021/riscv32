
module core_ifu_lsu(
	input                   clk,
	input                   rstn,

	// Request Interface
	input                   lsu_rx_valid,
	output					lsu_rx_ready,
	input		[31:0]		lsu_rx_addr,

	// Bus Interface
	output					bus_req_valid,
	output		[31:0]		bus_req_addr,

	input					bus_rsp_valid,
	input		[31:0]		bus_rsp_data,

	// Response Interface
	output					lsu_tx_valid,
	input					lsu_tx_ready,
	output		[31:0]		lsu_tx_inst
);

	reg [31:0] icache [(1<<17)-1:0];

	// always @(posedge clk) begin
	// 	if(!rstn)
	// 		for(i = 0;i < 32;i = i + 1)
	// 			icache[i] <= i;
	// 	else
	// 		icache[5] <= 32'b0000_0000_0000_0000_0000_0000_01100011; // A branch inst
	// end

	reg [31:0] icache_del [2:0];

	assign bus_req_valid = lsu_rx_valid && lsu_rx_ready;
	// assign bus_req_addr = lsu_rx_addr;

	integer i;
	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			for(i = 0;i < 3;i = i + 1)
				icache_del[i] <= 'd0;
		end
		else begin
			if(bus_req_valid) begin
				icache_del[0] <= icache[lsu_rx_addr[31:2]];
				$display("IFU fetching inst on %h", lsu_rx_addr);
			end
			icache_del[1] <= icache_del[0];
			icache_del[2] <= icache_del[1];
		end
	end
	
	reg [2:0] valid;
	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			for(i = 0;i < 3;i = i + 1)
				valid[i] <= 'd0;
		else begin
			valid[0] <= bus_req_valid;
			valid[1] <= valid[0];
			valid[2] <= valid[1];
		end
	end

	// FIFO Inputs
	wire   fifo_rx_valid;
	wire   fifo_tx_ready;
	wire   [31:0]  fifo_rx_data;

	// FIFO Outputs
	wire  [31:0]  fifo_tx_data;
	wire  fifo_rx_ready;
	wire  fifo_tx_valid;

	FIFO #(
		.DATA_WIDTH ( 32 ),
		.DEPTH      ( 8 ))
	ifu_lsu_buf (
		.clk                     ( clk             ),
		.rstn                    ( rstn            ),
		.fifo_rx_valid           ( fifo_rx_valid   ),
		.fifo_tx_ready           ( fifo_tx_ready   ),
		.fifo_rx_data            ( fifo_rx_data    ),

		.fifo_tx_data            ( fifo_tx_data    ),
		.fifo_rx_ready           ( fifo_rx_ready   ),
		.fifo_tx_valid           ( fifo_tx_valid   )
	);

	assign fifo_rx_valid = valid[2];
	assign fifo_rx_data = icache_del[2];
	assign lsu_rx_ready = fifo_rx_ready;

	assign fifo_tx_ready = lsu_tx_ready;
	assign lsu_tx_valid = fifo_tx_valid;
	assign lsu_tx_inst = fifo_tx_data;

`ifdef __VERILATOR__

	import "DPI-C" function void set_ptr_mem(input logic [31:0] icache []);
	initial begin
		set_ptr_mem(icache);
        // $readmemb("/home/sgap/ysyx-workbench/npc/vsrc/mem.init", mem);
    end

`endif

endmodule