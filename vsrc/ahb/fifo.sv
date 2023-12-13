module fifo #(
	parameter   DATA_WIDTH = 'd32,	
    parameter   DATA_DEPTH = 'd8	
) (
	input									clk,	
	input									rstn,

	input	[DATA_WIDTH-1:0]				data_in	,      
	input									rd_en,  
	input									wr_en,
															
	output	reg	[DATA_WIDTH-1:0]			data_out,
	output									full,
    output                                  empty
);
 
    reg [DATA_WIDTH - 1 : 0]                fifo_buffer [DATA_DEPTH - 1 : 0];
    reg [$clog2(DATA_DEPTH) - 1 : 0]	    wr_addr;
    reg [$clog2(DATA_DEPTH) - 1 : 0]	    rd_addr;
    reg	[$clog2(DATA_DEPTH) : 0]	        fifo_cnt;
    
    // read
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            rd_addr <= 0;
        else if (!empty && rd_en) begin
            rd_addr <= rd_addr + 1'd1;
            data_out <= fifo_buffer[rd_addr];
        end
    end

    // write
    always_ff @ (posedge clk or negedge rstn) begin
        if (!rstn)
            wr_addr <= 0;
        else if (!full && wr_en) begin
            wr_addr <= wr_addr + 1'd1;
            fifo_buffer[wr_addr]<=data_in;
        end
    end

    always_ff @ (posedge clk or negedge rstn) begin
        if (!rstn)
            fifo_cnt <= 0;
        else begin
            case({wr_en,rd_en})	
                2'b00:fifo_cnt <= fifo_cnt;	
                2'b01:	
                    if(fifo_cnt != 0)	
                        fifo_cnt <= fifo_cnt - 1'b1;
                2'b10: 
                    if(fifo_cnt != DATA_DEPTH) 
                        fifo_cnt <= fifo_cnt + 1'b1;  
                2'b11:fifo_cnt <= fifo_cnt;
                default:;                              	
            endcase
        end
    end

    assign full  = (fifo_cnt == DATA_DEPTH) ? 1'b1 : 1'b0;
    assign empty = (fifo_cnt == 0)? 1'b1 : 1'b0;
 
endmodule