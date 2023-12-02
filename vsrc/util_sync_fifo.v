module FIFO #(
	parameter DATA_WIDTH = 8,  
	parameter DEPTH = 8        
)(
	input							clk,
	input							rstn,
	input							fifo_rx_valid,
	output							fifo_rx_ready,
	input		[DATA_WIDTH-1:0]	fifo_rx_data,
       
	output	reg 					fifo_tx_valid,
	input							fifo_tx_ready,
	output		[DATA_WIDTH-1:0]	fifo_tx_data
);

	localparam	W_PTR	=	$clog2(DEPTH);

	reg [DATA_WIDTH - 1:0] fifo [DEPTH - 1:0];

	reg [W_PTR - 1:0] tx_ptr, rx_ptr;
	reg [DEPTH - 1:0] count;

	reg fifo_full;
	reg fifo_empty;

	assign fifo_rx_ready = !fifo_full;

	wire rx_ena = fifo_rx_valid && fifo_rx_ready;
	wire tx_ena = fifo_tx_valid && fifo_tx_ready;

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			tx_ptr <= 0;
			rx_ptr <= 0;
			fifo_full <= 0;
			fifo_empty <= 1;
		end else begin
			if (rx_ena) begin
				rx_ptr <= (rx_ptr == DEPTH-1) ? 0 : rx_ptr + 1;
				if(!tx_ena)
					if (count == DEPTH - 1)
						fifo_full <= 1;
				fifo_empty <= 0;
			end
			if (tx_ena) begin
				tx_ptr <= (tx_ptr == DEPTH-1) ? 0 : tx_ptr + 1;
				if(!rx_ena)
					if(count == 1)
						fifo_empty <= 1;
				fifo_full <= 0;
			end
		end
	end

	integer i;
	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			for(i = 0;i < DEPTH;i = i + 1)
				fifo[i] <= 'd0;
		else if(rx_ena) begin
			fifo[rx_ptr] <= fifo_rx_data;
			// $display("Writing %d into fifo[%d]\n", fifo_rx_data, tx_ptr);
		end
	end

	assign fifo_tx_data = fifo[tx_ptr];

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			count <= 'd0;
		else
			if(rx_ena && !tx_ena)
				count <= count + 1;
			else if(!rx_ena && tx_ena)
				count <= count - 1;
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			fifo_tx_valid <= 0;
		else
			if(rx_ena)
				fifo_tx_valid <= 1'b1;
			else if(tx_ena)
				fifo_tx_valid <= count == 1 ? 0 : 1;
	end

endmodule
