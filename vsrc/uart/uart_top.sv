`include "const_defines.svh"

module uart_top (
    // global
    input                               clk,
    input                               rstn,

    // ahb
    input [`AHB_DATA_WIDTH - 1:0]       hwdata,
    input [`AHB_ADDR_WIDTH - 1:0]       haddr,
    input                               hsel,
    input                               hwrite,
    output                              hready,
    output                              hresp,
    output [`AHB_DATA_WIDTH - 1:0]      hrdata,

    // uart
    input                               rx_pin,
    output                              tx_pin
);

    wire                                tx_ready;
    wire                                tx_valid;
    wire                                rx_ready;
    wire                                rx_valid;
    wire [7:0]                          tx_data;
    wire [7:0]                          rx_data;

    uart u_uart (
        .clk        (clk),
        .rstn       (rstn),
        .tx_ready   (tx_ready),//
        .tx_valid   (tx_valid),//
        .tx_data    (tx_data),//
        .rx_ready   (rx_ready),//
        .rx_valid   (rx_valid),//
        .rx_data    (rx_data),//
        .rx_pin     (rx_pin),
        .tx_pin     (tx_pin)
    );

    ahb2uart AHB_2_UART (
        .clk        (clk),
        .rstn       (rstn),
        .tx_ready   (tx_ready),
        .tx_valid   (tx_valid),
        .tx_data    (tx_data),
        .rx_ready   (rx_ready),
        .rx_valid   (rx_valid),
        .rx_data    (rx_data),
        .hwdata     (hwdata),
        .haddr      (haddr),
        .hwrite     (hwrite),
        .hsel       (hsel),
        .hready     (hready),
        .hresp      (hresp),
        .hrdata     (hrdata)
    );

endmodule