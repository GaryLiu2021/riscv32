`include "const_defines.v"

module master (
    input                               clk,
    input                               rstn,

    // simulus
    input [`AHB_ADDR_WIDTH - 1:0]       haddr_i,
    input                               haddr_ctrl_i,
    input                               hwrite_i,
    input [`AHB_DATA_WIDTH - 1:0]       hwdata_i,
    input                               hbusreq_i,

    //ahb if
    input [`AHB_DATA_WIDTH - 1:0]       hdata_s2m,
    input                               hgrant,
    input                               hresp_s2m,
    input                               hready_s2m,
    output [`AHB_ADDR_WIDTH - 1:0]      haddr,
    output                              haddr_ctrl,
    output                              hwrite,
    output [`AHB_DATA_WIDTH - 1:0]      hwdata,
    output                              hbusreq //cpu
);
    assign haddr        = haddr_i;
    assign haddr_ctrl   = haddr_ctrl_i;
    assign hwrite       = hwrite_i;
    assign hwdata       = hwdata_i;
    assign hbusreq      = hbusreq_i;

endmodule