`include "const_defines.svh"
module tb_ram_top;

    parameter CLK_PERIOD = 10;     // 时钟周期，单位：ns
    
    // Signals
    reg clk;
    reg rstn;
    reg [`AHB_ADDR_WIDTH-1:0] haddr;
    reg [`AHB_DATA_WIDTH-1:0] hwdata;
    reg hwrite;
    reg hsel;
    wire hready;
    wire hresp;
    wire [`AHB_DATA_WIDTH-1:0] hrdata;

    // Instantiate the RAM_TOP module
    ram_top dut (
        .clk(clk),
        .rstn(rstn),
        .haddr(haddr),
        .hwdata(hwdata),
        .hwrite(hwrite),
        .hsel(hsel),
        .hready(hready),
        .hresp(hresp),
        .hrdata(hrdata)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // tb
    initial begin
        rstn = 'b0;
        haddr = 'b0;
        hwdata = 'b0;
        hwrite = 'b0;
        hsel = 'b0;
        #(3 * CLK_PERIOD/5);
        #(10 * CLK_PERIOD) rstn = 'b1;
        #(10 * CLK_PERIOD);

    // case1 write
        hsel = 'b1;
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

    // case2 read
        hsel = 'b1;
        hwrite = 'b0;
        #(CLK_PERIOD);
        haddr = 32'b1111_0000_1111_0000_1111_0000_1111_0000;
        hwrite = 'b0;
        hsel = 'b0;
        #(CLK_PERIOD);
        haddr = 32'b0;
        #(10 * CLK_PERIOD);

    // case2 read empty
        hsel = 'b1;
        hwrite = 'b0;
        #(CLK_PERIOD);
        haddr = 32'b1111_0000_1111_0000_1111_0000_1111_0001;
        hwrite = 'b0;
        hsel = 'b0;
        #(CLK_PERIOD);
        haddr = 32'b0;
        #(10 * CLK_PERIOD);

    // case3 invalid write
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
        
        #(10 * CLK_PERIOD);
        $finish;
    end



    `ifdef FSDB
        initial begin
            $fsdbDumpfile("ram.fsdb");
            $fsdbDumpvars;
        end
    `endif

endmodule