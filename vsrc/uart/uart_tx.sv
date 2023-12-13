// tx_data与valid对齐

module uart_tx #(
	parameter 					CLK_FRE = 50,      //clock frequency(Mhz)
	parameter 					BAUD_RATE = 115200 //serial baud rate
)(
	input                       clk,           
	input                       rstn,  
	input [7:0]                 tx_data,    
	input                       tx_data_valid,  
	output reg                  tx_data_ready,  
	output                      tx_pin   
);

	//calculates the clock cycle for baud rate 
	localparam                      CYCLE = CLK_FRE * 1000000 / BAUD_RATE;

	typedef enum logic [1:0] {
		S_IDLE,
		S_START,		//start bit
		S_SEND_BYTE,	//data bits
		S_STOP			//stop bit
	} tx_state_t;

	reg [1:0]                       state;
	reg [1:0]                       next_state;
	reg [15:0]                      cycle_cnt; //baud counter
	reg [2:0]                       bit_cnt;//bit counter
	reg [7:0]                       tx_data_latch; //latch data to send
	reg                             tx_reg; //serial data output

	assign tx_pin = tx_reg;

	always_ff @(posedge clk or negedge rstn) begin
		if(rstn == 1'b0)
			state <= S_IDLE;
		else
			state <= next_state;
	end

	always_comb begin
		case(state)
			S_IDLE:
				if(tx_data_valid == 1'b1)
					next_state <= S_START;
				else
					next_state <= S_IDLE;
			S_START:
				if(cycle_cnt == CYCLE - 1)
					next_state <= S_SEND_BYTE;
				else
					next_state <= S_START;
			S_SEND_BYTE:
				if(cycle_cnt == CYCLE - 1  && bit_cnt == 3'd7)
					next_state <= S_STOP;
				else
					next_state <= S_SEND_BYTE;
			S_STOP:
				if(cycle_cnt == CYCLE - 1)
					next_state <= S_IDLE;
				else
					next_state <= S_STOP;
			default:
				next_state <= S_IDLE;
		endcase
	end

	always_ff @(posedge clk or negedge rstn) begin
		if(rstn == 1'b0)
			begin
				tx_data_ready <= 1'b0;
			end
		else if(state == S_IDLE)
			if(tx_data_valid == 1'b1)
				tx_data_ready <= 1'b0;
			else
				tx_data_ready <= 1'b1;
		else if(state == S_STOP && cycle_cnt == CYCLE - 1)
				tx_data_ready <= 1'b1;
	end

	always_ff @(posedge clk or negedge rstn) begin
		if(rstn == 1'b0)
			begin
				tx_data_latch <= 'd0;
			end
		else if(state == S_IDLE && tx_data_valid == 1'b1)
				tx_data_latch <= tx_data;
			
	end

	always_ff @(posedge clk or negedge rstn) begin
		if(rstn == 1'b0)
			begin
				bit_cnt <= 'd0;
			end
		else if(state == S_SEND_BYTE)
			if(cycle_cnt == CYCLE - 1)
				bit_cnt <= bit_cnt + 'd1;
			else
				bit_cnt <= bit_cnt;
		else
			bit_cnt <= 'd0;
	end

	always_ff @(posedge clk or negedge rstn) begin
		if(rstn == 1'b0)
			cycle_cnt <= 16'd0;
		else if((state == S_SEND_BYTE && cycle_cnt == CYCLE - 1) || next_state != state)
			cycle_cnt <= 16'd0;
		else
			cycle_cnt <= cycle_cnt + 16'd1;	
	end

	always_ff @(posedge clk or negedge rstn) begin
		if(rstn == 1'b0)
			tx_reg <= 1'b1;
		else
			case(state)
				S_IDLE,S_STOP:
					tx_reg <= 1'b1; 
				S_START:
					tx_reg <= 1'b0; 
				S_SEND_BYTE:
					tx_reg <= tx_data_latch[bit_cnt];
				default:
					tx_reg <= 1'b1; 
			endcase
	end

endmodule