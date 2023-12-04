module sim(
    input clk,
    input rstn
);

// always #(1) clk = ~clk;

single_cycle_cpu  u_single_cycle_cpu (  
    .clk                     ( clk    ),
    .rstn                    ( rstn   ) 
);
reg [31:0]  counter = 0;
always @(posedge clk) begin
    if(rstn)
        counter <= counter + 1;
end

// initial begin
//     #(10000);
//     $display("Time Out!!!");
//     $finish;
// end

// initial begin
//     $dumpfile("wave.vcd");
//     $dumpvars;
// end

endmodule //sim