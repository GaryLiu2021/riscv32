`include "const_defines.svh"

module ram_top (
    // global
    input clk,
    input rstn,

    // ahb
    input [`AHB_DATA_WIDTH - 1:0]       hwdata,
    input [`AHB_ADDR_WIDTH - 1:0]       haddr,
    input                               hwrite,
    input                               hsel,
    output reg                          hready,
    output                              hresp,
    output [`AHB_DATA_WIDTH - 1:0]      hrdata 

    // ram
        // add ram io ports
);
    
    // ram
    wire [`AHB_ADDR_WIDTH-1:0]          address;
    wire                                rden;
    wire [`AHB_DATA_WIDTH-1:0]          q;
    wire                                wren;
    wire [`AHB_DATA_WIDTH-1:0]          data;
    wire [2:0]                          rwtyp;

    ahb2ram ahb_ram_if (
        .clk(clk),
        .rstn(rstn),
        .address(address),
        .rden(rden),
        .q(q),
        .wren(wren),
        .data(data),
        .rwtyp(rwtyp),
        .hwdata(hwdata),
        .haddr(haddr),
        .hwrite(hwrite),
        .hsel(hsel),
        .hready(hready),
        .hresp(hresp),
        .hrdata(hrdata)
    );

    spram #(
        .ADDR_WIDTH ( 16    ),
        .DATA_WIDTH ( 32    ),
        .RAM_DEPTH  ( 65536 ))
    u_spram (
        .clk                     ( clk       ),
        .rstn                    ( rstn      ),
        .address                 ( address   ),
        .rden                    ( rden      ),
        .wren                    ( wren      ),
        .data                    ( data      ),
        .rwtyp                   ( rwtyp     ),

        .q                       ( q         )
    );

endmodule