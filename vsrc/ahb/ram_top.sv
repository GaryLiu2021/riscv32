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
    wire [`AHB_ADDR_WIDTH-1:0]          addr;
    wire                                rden;
    wire [`AHB_DATA_WIDTH-1:0]          q;
    wire                                wren;
    wire [`AHB_DATA_WIDTH-1:0]          data;
    wire [2:0]                          rwtyp;

    ahb2ram ahb_ram_if (
        .clk(clk),
        .rstn(rstn),
        .address(addr),
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

    emu_ram #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 ))
    u_emu_ram (
        .clk                     ( clk     ),
        .rstn                    ( rstn    ),
        .rwtyp                   ( rwtyp   ),
        .addr                    ( addr    ),
        .data                    ( data    ),
        .wren                    ( wren    ),
        .rden                    ( rden    ),

        .q                       ( q       )
    );

endmodule