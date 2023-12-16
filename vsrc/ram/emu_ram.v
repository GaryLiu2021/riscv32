module emu_ram
#(
	parameter ADDR_WIDTH =32,
	parameter DATA_WIDTH =32
)
(
	input clk,
	input rstn,
	input [2:0]rwtyp,
	input [ADDR_WIDTH-1:0]addr,
	input [DATA_WIDTH-1:0]data,
	input wren,
	input rden,
	output [DATA_WIDTH-1:0]q

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

MyRAM u_MyRAM(
	.address(addr[17:2]),
	.byteena(byteena),
	.clock(clk),
	.data(data),
	.rden(rden),
	.wren(wren),
	.q(q));
	
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

wire [31:0] qw = ram[address] & sel;

always@(posedge clock)
	begin
		if(rden)
			begin
				case(byteena)
					4'b1111,4'b1101,4'b1011,4'b0111,4'b1001,4'b0101,4'b0011,4'b0001: q <= qw;
					4'b1110,4'b1010,4'b0110,4'b0010: q <= qw >> 8;
					4'b1100,4'b0100:	q <= qw >> 16;
					4'b1000:	q <= qw >> 24;
				endcase
		`ifdef __LOG_ENABLE__
			$display("RAM: [0x%8h] reading...", address);
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
			case(byteena)
				4'b0001:ram[address]<={24'd0,data[7:0]};
				4'b0011:ram[address]<={16'd0,data[15:0]};
				4'b1111:ram[address]<=data;
				default:ram[address]<=data;
			endcase
			`ifdef __LOG_ENABLE__
				$display("RAM: [0x%8h] writing, data: %h", address, data);
			`endif
		end
		else;
		$display("0x801fffac: %h", ram[16'h3feb]);
	end

endmodule
	