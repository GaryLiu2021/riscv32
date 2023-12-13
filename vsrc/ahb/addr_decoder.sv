`include "const_defines.svh"

module addr_decoder (
    input [`AHB_ADDR_WIDTH - 1:0]   addr,
    input                           addr_ctrl,

    output                          hsel_0,
    output                          hsel_1
);
    assign hsel_0 = addr_ctrl & !addr[`AHB_ADDR_WIDTH - 1];
    assign hsel_1 = addr_ctrl & addr[`AHB_ADDR_WIDTH - 1];

endmodule