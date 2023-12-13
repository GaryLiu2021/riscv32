module spram #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter RAM_DEPTH  = 65536 // 256KBYTE
) (
    input                   clk,
    input                   rstn,
    input [ADDR_WIDTH-1:0]  address,
    input                   rden,
    output [DATA_WIDTH-1:0] q,
    input                   wren,
    input [DATA_WIDTH-1:0]  data,
    input [2:0]             rwtyp
);

(*ram_style = "block"*) reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];
reg [DATA_WIDTH-1:0] dout_w;

always_ff @(posedge clk or negedge rstn) begin : WRITE
    if (!rstn) ram <= '{default: '0};
    else if(wren)
        case(rwtyp[1:0])
            2'b00:
                ram[address][7:0] <= data[7:0];
            2'b01:
                ram[address][15:0] <= data[15:0];
            2'b10:
                ram[address] <= data;
        endcase
end

always_ff @(posedge clk or negedge rstn) begin : READ
    if(!rstn) dout_w <= 'b0;
    else if(rden)
        case(rwtyp[1:0])
            2'b00:
                dout_w <= {24'd0, ram[address][7:0]};
            2'b01:
                dout_w <= {16'd0, ram[address][15:0]};
            2'b10:
                dout_w <= ram[address];
            default:
                dout_w <= 32'hxxxx_xxxx;
        endcase
end

assign q = dout_w;

endmodule