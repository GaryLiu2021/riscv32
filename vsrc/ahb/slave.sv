`include "const_defines.v"

module slave (
    input                               clk,
    input                               rstn,

    // simulus
    input                               hready_i,
    input                               hresp_i,
    input [`AHB_DATA_WIDTH - 1:0]       hrdata_i,

    // ahb if
    input [`AHB_DATA_WIDTH - 1:0]       hdata_m2s,
    input [`AHB_ADDR_WIDTH - 1:0]       haddr_m2s,
    input                               hwrite,
    input                               hsel, // io

    output                              hready,
    output                              hresp,
    output [`AHB_DATA_WIDTH - 1:0]      hrdata 
);
    
    assign hready = hready_i;
    assign hresp = hresp_i;
    assign hrdata = hrdata_i;

endmodule