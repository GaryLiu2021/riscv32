`include "const_defines.svh"

module uart (
    // global
    input                               clk,
    input                               rstn,

    // ahb if
    output                              tx_ready,
    input                               tx_valid,
    input [7:0]                         tx_data,
    input                               rx_ready,
    output                              rx_valid,
    output [7:0]                        rx_data,

    // uart pin
    input                               rx_pin,
    output                              tx_pin
);

    uart_tx #(
        .CLK_FRE        (`CLK_FRE),
        .BAUD_RATE      (`BAUD_RATE)
    ) tx (
        .clk            (clk),
        .rstn          (rstn),
        .tx_data        (tx_data),
        .tx_data_valid  (tx_valid),
        .tx_data_ready  (tx_ready),
        .tx_pin         (tx_pin)
    );

    uart_rx #(
        .CLK_FRE        (`CLK_FRE), 
        .BAUD_RATE      (`BAUD_RATE) 
    ) rx (
        .clk            (clk),
        .rstn          (rstn),
        .rx_data        (rx_data),
        .rx_data_valid  (rx_valid),
        .rx_data_ready  (rx_ready),
        .rx_pin         (rx_pin)
    );
    
endmodule