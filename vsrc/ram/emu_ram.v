module emu_ram
#(
	parameter ADDR_WIDTH =32,
	parameter DATA_WIDTH =32
)
(
	input							clk,
	input							rstn,
	input		[2:0]				rwtyp,
	input		[ADDR_WIDTH-1:0]	addr,
	input		[DATA_WIDTH-1:0]	data,
	input							wren,
	input							rden,
	output		[DATA_WIDTH-1:0]	q
);


reg [3:0]byteena;
	
always@(*)
	begin
		case(rwtyp)
			3'b000:byteena=(4'b0001)<<(addr[1:0]);
			3'b001:byteena=(4'b0011)<<(addr[1:0]);
			3'b010:byteena=4'b1111;
			3'b100:byteena=(4'b0001)<<(addr[1:0]);
			3'b101:byteena=(4'b0011)<<(addr[1:0]);
			default:byteena=4'b1111;
		endcase
	end

wire	[31:0]	datain	=	data << ({3'd0, addr[1:0]} << 3);

wire	[3:0]	entry	=	{rwtyp[1:0], addr[1:0]};
reg		[3:0]	req_table;

always @(posedge clk or negedge rstn) begin
	if(!rstn)
		req_table <= 'd0;
	else if(rden)
		req_table <= entry;
end

wire	[31:0]	ip_ram_q;

MyRAM u_MyRAM(
	.address(addr[17:2]),
	.byteena(byteena),
	.clock(clk),
	.data(datain),
	.rden(rden),
	.wren(wren),
	.q(ip_ram_q));

	wire	[4:0]	base	=	{3'd0, req_table[1:0]};
	wire	[31:0]	aftershift	=	(ip_ram_q) >> (base << 3);
	reg		[31:0]	dout;

	always @(*) begin
		case(req_table[3:2])
			2'b00:
				dout	=	{24'd0, aftershift[7:0]};
			2'b01:
				dout	=	{16'd0, aftershift[15:0]};
			2'b10:
				dout	=	aftershift;
			default:
				dout	=	'd0;
		endcase
	end

	assign	q	=	dout;
	
endmodule



module MyRAM(
	 input [15:0]address,
	 input [3:0]byteena,
	 input clock,
	 input [31:0]data,
	 input rden,
	 input wren,
	 output reg [31:0]q
);

reg [31:0] ram [65535:0];
reg [31:0] sel;
integer i;
always @(*) begin
	for(i=0;i<4;i=i+1) begin
		sel[i*8 +: 8] = {8{byteena[i]}};
	end
end

always@(posedge clock)
	begin
		if(rden)
			begin
				q <= ram[address];
		`ifdef __LOG_ENABLE__
			$display("RAM: [0x%8h] reading...\nRAM: byteena = %b", address, byteena);
			@(posedge clock)
			$display("RAM: data fetched: %h", q);
		`endif
			end
		else
			q <= 'd0;
	end

always@(posedge clock)
	begin
		if(wren) begin
			ram[address]	<=	(data & sel) | (ram[address] & ~sel);
			`ifdef __LOG_ENABLE__
				$display("RAM: [0x%8h] writing...\nRAM: data = %h", address, (data & sel) | (ram[address] & ~sel));
			`endif
		end
		else;
	end

`ifdef __VERILATOR__

	import "DPI-C" function void set_ptr_ram(input logic [31:0] ram []);
	initial begin
		set_ptr_ram(ram);
	end

`endif

endmodule
	