module emu_rom (
	// Global Signal
	input				clk,
	input				rstn,

	// Interface
	input				rom_rx_valid,
	// output	reg			rx_ready,
	input		[31:0]	rom_rx_addr,

	output	reg			rom_tx_valid,
	// input				tx_ready,
	output	reg	[31:0]	rom_tx_data
);
	
	reg [31:0] memory [1<<14 - 1:0];

	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			rom_tx_valid	<=	'd0;
			rom_tx_data		<=	'd0;
		end
		else if(rom_rx_valid) begin
			rom_tx_valid	<=	1'b1;
			rom_tx_data		<=	memory[rom_rx_addr[15:2]];
		end
		else
			rom_tx_valid	<=	1'b0;
	end

`ifdef __VERILATOR__

	import "DPI-C" function void set_ptr_mem(input logic [31:0] memory []);
	initial begin
		set_ptr_mem(memory);
	end

`endif

endmodule //emu_rom
