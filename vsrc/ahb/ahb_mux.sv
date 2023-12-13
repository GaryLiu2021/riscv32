`include "const_defines.svh"

module ahb_mux #(
    parameter WIDTH = 32
) (
    input [WIDTH - 1 : 0]   in_1,
    input [WIDTH - 1 : 0]   in_2,
    input                   sel,

    output [WIDTH - 1 : 0]  out
);
    
    assign out = sel ? in_1: in_2;

endmodule