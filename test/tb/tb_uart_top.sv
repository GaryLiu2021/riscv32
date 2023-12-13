`include "const_defines.svh"

module tb_uart_top;

    localparam CLK_PERIOD = 1000 / `CLK_FRE; // ns
    localparam CYCLE = `CLK_FRE * 1000000 / `BAUD_RATE;

    // Signals
    reg clk;
    reg rstn;
    reg [`AHB_DATA_WIDTH-1:0] hwdata;
    reg [`AHB_ADDR_WIDTH-1:0] haddr;
    reg hsel;
    reg hwrite;
    wire hready;
    wire hresp;
    wire [`AHB_DATA_WIDTH-1:0] hrdata;
    reg rx_pin;
    wire tx_pin;

    reg [31:0] uart_in;

    // Instantiate the UART_TOP module
    uart_top dut (
        .clk(clk),
        .rstn(rstn),
        .hwdata(hwdata),
        .haddr(haddr),
        .hsel(hsel),
        .hwrite(hwrite),
        .hready(hready),
        .hresp(hresp),
        .hrdata(hrdata),
        .rx_pin(rx_pin),
        .tx_pin(tx_pin)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        rx_pin ='b1;
        rstn = 'b0;
        haddr = 'b0;
        hwdata = 'b0;
        hwrite = 'b0;
        hsel = 'b0;
        rstn = 0;
        #(10 * CLK_PERIOD);
        rstn = 1;
        #(10 * CLK_PERIOD);

    // case1 invalid write
        hsel = 'b0;
        hwrite = 'b1;
        #(CLK_PERIOD);
        haddr = 32'b1111_0000_1111_0000_1111_0000_1111_0000;
        hwrite = 'b0;
        hsel = 'b0;
        #(CLK_PERIOD);
        hwdata = 32'h1234_5678;
        haddr = 32'b0;
        #(CLK_PERIOD);
        hwdata = 'b0;
        #(10 * CLK_PERIOD);

    // case2 write is_scanf
        hsel = 'b1;
        hwrite = 'b1;
        #(CLK_PERIOD);
        haddr = 32'b0111_0000_1111_0000_1111_0000_1111_0000;
        hwrite = 'b0;
        hsel = 'b0;
        #(CLK_PERIOD);
        hwdata = 32'h1234_567F;
        haddr = 32'b0;
        #(CLK_PERIOD);
        hwdata = 'b0;
        #(10 * CLK_PERIOD);

    // case3 read is_scanf
        hsel = 'b1;
        hwrite = 'b0;
        #(CLK_PERIOD);
        haddr = 32'b0111_0000_1111_0000_1111_0000_1111_0000;
        hwrite = 'b0;
        hsel = 'b0;
        #(CLK_PERIOD);
        haddr = 32'b0;
        #(10 * CLK_PERIOD);

    // case4 reset is_scanf
        hsel = 'b1;
        hwrite = 'b1;
        #(CLK_PERIOD);
        haddr = 32'b0111_0000_1111_0000_1111_0000_1111_0000;
        hwrite = 'b0;
        hsel = 'b0;
        #(CLK_PERIOD);
        hwdata = 32'h1234_5670;
        haddr = 32'b0;
        #(CLK_PERIOD);
        hwdata = 'b0;
        #(10 * CLK_PERIOD);

    // case4 write buffer
        hsel = 'b1;
        hwrite = 'b1;
        #(CLK_PERIOD);
        haddr = 32'b0011_0000_1111_0000_1111_0000_1111_0000;
        hwrite = 'b0;
        hsel = 'b0;
        #(CLK_PERIOD);
        hwdata = 32'h1234_5678;
        haddr = 32'b0;
        #(CLK_PERIOD);
        hwdata = 'b0;
        #(35 * CYCLE * CLK_PERIOD);

    // case5 read buffer
        // firstly set scanf
        hsel = 'b1;
        hwrite = 'b1;
        #(CLK_PERIOD);
        haddr = 32'b0111_0000_1111_0000_1111_0000_1111_0000;
        hwrite = 'b0;
        hsel = 'b0;
        #(CLK_PERIOD);
        hwdata = 32'h1234_567F;
        haddr = 32'b0;
        #(CLK_PERIOD);
        hwdata = 'b0;
        // then read req
        hsel = 'b1;
        hwrite = 'b0;
        #(CLK_PERIOD);
        haddr = 32'b0011_0000_1111_0000_1111_0000_1111_0000;
        hwrite = 'b0;
        hsel = 'b0;
        #(CLK_PERIOD);
        haddr = 32'b0;
        rx_pin = 0; // start bit
        #(CYCLE * CLK_PERIOD);
        uart_in = 32'b1111_0110_1100_1100_1010_1010_1110_0111;
        for (int i = 0; i < 32 ;i++) begin // data
            rx_pin = uart_in[i];
            #(CYCLE * CLK_PERIOD);
        end // data end
        rx_pin = 1; //end bit
        #(CYCLE * CLK_PERIOD);
        // finally reset scanf
        hsel = 'b1;
        hwrite = 'b1;
        #(CLK_PERIOD);
        haddr = 32'b0111_0000_1111_0000_1111_0000_1111_0000;
        hwrite = 'b0;
        hsel = 'b0;
        #(CLK_PERIOD);
        hwdata = 32'h1234_5670;
        haddr = 32'b0;
        #(CLK_PERIOD);
        hwdata = 'b0;
        #(CLK_PERIOD);
            
        #(10 * CLK_PERIOD);
        $finish;
    end

`ifdef FSDB
    initial begin
        $fsdbDumpfile("uart.fsdb");
        $fsdbDumpvars;
    end
`endif

endmodule