// 起始位和结束位需要持续整个元宽
// ready至少需要相较于起始位提前一个cycle

module uart_rx #(
	parameter CLK_FRE = 50,      //clock frequency(Mhz)
	parameter BAUD_RATE = 115200 //serial baud rate
)(
	input                        clk,            
	input                        rstn,        
	output reg [7:0]             rx_data,     
	output reg                   rx_data_valid,
	input                        rx_data_ready,  
	input                        rx_pin  
);

	//calculates the clock cycle for baud rate 
	localparam                   CYCLE = CLK_FRE * 1000000 / BAUD_RATE;
	//state machine code
	typedef enum logic [2:0] {
		S_IDLE,
		S_START,	//start bit
		S_REC_BYTE,	//data bits
		S_STOP, 	//stop bit
		S_DATA
	} rx_state_t;

	reg [2:0]                    state;
	reg [2:0]                    next_state;
	reg                          rx_d0;            //delay 1 clock for rx_pin
	reg                          rx_d1;            //delay 1 clock for rx_d0
	wire                         rx_negedge;       //negedge of rx_pin
	reg [7:0]                    rx_bits;          //temporary storage of received data
	reg [15:0]                   cycle_cnt;        //baud counter
	reg [2:0]                    bit_cnt;          //bit counter

	assign rx_negedge = rx_d1 && ~rx_d0;

	always_ff @(posedge clk or negedge rstn) begin
		if(rstn == 1'b0)
		begin
			rx_d0 <= 1'b0;
			rx_d1 <= 1'b0;	
		end
		else
		begin
			rx_d0 <= rx_pin;
			rx_d1 <= rx_d0;
		end
	end

	always_ff @(posedge clk or negedge rstn) begin
		if(rstn == 1'b0)
			state <= S_IDLE;
		else
			state <= next_state;
	end

	always_comb begin
		case(state)
			S_IDLE:
				if(rx_negedge)
					next_state <= S_START;
				else
					next_state <= S_IDLE;
			S_START:
				if(cycle_cnt == CYCLE - 1)//one data cycle 
					next_state <= S_REC_BYTE;
				else
					next_state <= S_START;
			S_REC_BYTE:
				if(cycle_cnt == CYCLE - 1  && bit_cnt == 3'd7)  //receive 8bit data
					next_state <= S_STOP;
				else
					next_state <= S_REC_BYTE;
			S_STOP:
				if(cycle_cnt == CYCLE/2 - 1)//half bit cycle,to avoid missing the next byte receiver
					next_state <= S_DATA;
				else
					next_state <= S_STOP;
			S_DATA:
				if(rx_data_ready)    //data receive complete
					next_state <= S_IDLE;
				else
					next_state <= S_DATA;
			default:
				next_state <= S_IDLE;
		endcase
	end

	always_ff @(posedge clk or negedge rstn) begin
		if(rstn == 1'b0)
			rx_data_valid <= 1'b0;
		else if(state == S_STOP && next_state != state)
			rx_data_valid <= 1'b1;
		else if(state == S_DATA && rx_data_ready)
			rx_data_valid <= 1'b0;
	end

	always_ff @(posedge clk or negedge rstn) begin
		if(rstn == 1'b0)
			rx_data <= 8'd0;
		else if(state == S_STOP && next_state != state)
			rx_data <= rx_bits;//latch received data
	end

	always_ff @(posedge clk or negedge rstn) begin
		if(rstn == 1'b0)
			begin
				bit_cnt <= 'd0;
			end
		else if(state == S_REC_BYTE)
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
		else if((state == S_REC_BYTE && cycle_cnt == CYCLE - 1) || next_state != state)
			cycle_cnt <= 16'd0;
		else
			cycle_cnt <= cycle_cnt + 16'd1;	
	end

	always_ff @(posedge clk or negedge rstn) begin
		if(rstn == 1'b0)
			rx_bits <= 'd0;
		else if(state == S_REC_BYTE && cycle_cnt == CYCLE/2 - 1)
			rx_bits[bit_cnt] <= rx_pin;
		else
			rx_bits <= rx_bits; 
	end

endmodule 