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
			000:byteena=4'b0001;
			001:byteena=4'b0011;
			010:byteena=4'b1111;
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

reg [31:0]ram [65535:0];

always@(posedge clock)
	begin
		if(rden)
			begin
				case(byteena)
					4'b0001:q<={24'd0,ram[address][7:0]};
					4'b0011:q<={16'd0,ram[address][15:0]};
					4'b1111:q<=ram[address];
					default:q<=ram[address];
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
	end

endmodule
	