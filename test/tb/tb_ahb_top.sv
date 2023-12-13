`include "const_defines.svh"
module tb_ahb_top;

    localparam CLK_PERIOD = 1000 / `CLK_FRE; // ns
    localparam CYCLE = `CLK_FRE * 1000000 / `BAUD_RATE;

    // Signals
    reg clk;
    reg rstn;
    reg [3:0] testcase;
    reg [`AHB_ADDR_WIDTH-1:0] haddr_i;
    reg hwrite_i;
    reg haddr_ctrl_i;
    reg [`AHB_DATA_WIDTH-1:0] hwdata_i;
    reg hbusreq_i;
    reg rx_pin;
    wire tx_pin;

    // Instantiate the AHB_LITE_TOP module
    ahb_lite_top dut (
        .clk(clk),
        .rstn(rstn),
        .haddr_i(haddr_i),
        .hwrite_i(hwrite_i),
        .haddr_ctrl_i(haddr_ctrl_i),
        .hwdata_i(hwdata_i),
        .hbusreq_i(hbusreq_i),
        .rx_pin(rx_pin),
        .tx_pin(tx_pin)
    );
    

    initial begin : CLOCK_GEN
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin : RESET
        rstn = 'b0;
        #(5 * CLK_PERIOD);
        rstn = 'b1;
    end

    initial begin : MASTER
        // init
        testcase = 'b0;
        haddr_i = 32'b0;
        hwrite_i = 'b0;
        haddr_ctrl_i = 'b0;
        hwdata_i = 'b0;
        hbusreq_i = 'b0;
        #(3 * CLK_PERIOD/5);
        #(20 * CLK_PERIOD);
        
    // case2 write ram
        // write1
        testcase = 'd2;
        hbusreq_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b1_1_101_11111111111_1100_1100_1101_1101;
        hwrite_i = 'b1;
        haddr_ctrl_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b0;
        hwrite_i = 'b0;
        haddr_ctrl_i = 'b0;//此时是hreq的上升沿
        hwdata_i = 32'h1234_5678;
        #(CLK_PERIOD);
        hwdata_i = 'b0;
        hbusreq_i = 'b0;
        // write2
        #(2*CLK_PERIOD);// at least 2
        hbusreq_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b1_1_101_11111111111_1100_1100_1101_1111;
        hwrite_i = 'b1;
        haddr_ctrl_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b0;
        hwrite_i = 'b0;
        haddr_ctrl_i = 'b0;
        hwdata_i = 32'h8765_4321;
        #(CLK_PERIOD);
        hwdata_i = 'b0;
        hbusreq_i = 'b0;
        #(10 * CLK_PERIOD); // at least 2

    // case3 read ram
        // read1
        testcase = 'd3;
        hbusreq_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b1_1_101_11111111111_1100_1100_1101_1101;
        hwrite_i = 'b0;
        haddr_ctrl_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b0;
        hwrite_i = 'b0;
        haddr_ctrl_i = 'b0;
        #(CLK_PERIOD);
        hbusreq_i = 'b0;
        #(10 * CLK_PERIOD);// at least 2
        // read2
        hbusreq_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b1_1_101_11111111111_1100_1100_1101_1111;
        hwrite_i = 'b0;
        haddr_ctrl_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b0;
        hwrite_i = 'b0;
        haddr_ctrl_i = 'b0;
        #(CLK_PERIOD);
        hbusreq_i = 'b0;
        #(10 * CLK_PERIOD);// at least 2

    // case4 set reg
        testcase = 'd4;
        hbusreq_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b0_1_101_11111111111_1100_1100_1101_1101;
        hwrite_i = 'b1;
        haddr_ctrl_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b0;
        hwrite_i = 'b0;
        haddr_ctrl_i = 'b0;
        hwdata_i = 32'h1234_567F;
        #(CLK_PERIOD);
        hwdata_i = 'b0;
        hbusreq_i = 'b0;
        #(10 * CLK_PERIOD);// at least 2

    // case5 read reg
        testcase = 'd5;
        hbusreq_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b0_1_101_11111111111_1100_1100_1101_1101;
        hwrite_i = 'b0;
        haddr_ctrl_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b0;
        hwrite_i = 'b0;
        haddr_ctrl_i = 'b0;
        #(CLK_PERIOD);
        hbusreq_i = 'b0;
        #(10 * CLK_PERIOD);// at least 2

    // case6 write uart
        testcase = 'd6;
        hbusreq_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b0_0_101_11111111111_1100_1100_1101_1101;
        hwrite_i = 'b1;
        haddr_ctrl_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b0;
        hwrite_i = 'b0;
        haddr_ctrl_i = 'b0;
        hwdata_i = 32'b1110_1110_1100_1100_1010_0001_1010_0001;
        #(CLK_PERIOD);
        hwdata_i = 'b0;
        hbusreq_i = 'b0;
        #(34 * CYCLE * CLK_PERIOD);

    // case7 reset reg
        testcase = 'd7;
        hbusreq_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b0_1_101_11111111111_1100_1100_1101_1101;
        hwrite_i = 'b1;
        haddr_ctrl_i = 'b1;
        #(CLK_PERIOD);
        haddr_i = 32'b0;
        hwrite_i = 'b0;
        haddr_ctrl_i = 'b0;
        hwdata_i = 32'h1234_5670;
        #(CLK_PERIOD);
        hwdata_i = 'b0;
        hbusreq_i = 'b0;
        #(10 * CLK_PERIOD);// at least 2

    // case8 read uart

        #(8 * CYCLE * CLK_PERIOD);
        $finish;
    end

    initial begin : SLAVE
        rx_pin = 1;

    end


`ifdef FSDB
    initial begin
        $fsdbDumpfile("ahb_top.fsdb");
        $fsdbDumpvars;
    end
`endif
    
endmodule