`include "const_defines.svh"

module ahb2uart (
    // global
    input                               clk,
    input                               rstn,

    // uart_if
    input                               tx_ready,
    output reg                          tx_valid,
    output [7:0]                        tx_data,
    output                              rx_ready,
    input                               rx_valid,
    input [7:0]                         rx_data,

    // ahb if
    input [`AHB_DATA_WIDTH - 1:0]       hwdata,
    input [`AHB_ADDR_WIDTH - 1:0]       haddr,
    input                               hwrite,
    input                               hsel,
    output reg                          hready,
    output                              hresp,
    output [`AHB_DATA_WIDTH - 1:0]      hrdata 
);

    reg                                 is_scanf;

    wire [`AHB_DATA_WIDTH - 1:0]        wd_buffer_i;
    wire [`AHB_DATA_WIDTH - 1:0]        wd_buffer_o;
    reg [3:0]                           wd_buffer_ren;
    reg                                 wd_buffer_wen;
    wire [3:0]                          wd_buffer_full;
    wire [3:0]                          wd_buffer_empty;

    reg  [`AHB_DATA_WIDTH - 1:0]        rd_buffer_i;
    wire [`AHB_DATA_WIDTH - 1:0]        rd_buffer_o;
    reg                                 rd_buffer_ren;
    reg [3:0]                           rd_buffer_wen;
    wire [3:0]                          rd_buffer_full;
    wire [3:0]                          rd_buffer_empty;

    reg [`AHB_DATA_WIDTH - 1:0]         rdata;
    reg [`AHB_DATA_WIDTH - 1:0]         wdata;
    reg                                 biu;
    reg                                 reg_resp;
    reg                                 buf_resp;
    reg [1:0]                           tx_cnt;
    reg [1:0]                           rx_cnt;
    wire [1:0]                          last_tx_cnt;
    wire [1:0]                          last_rx_cnt;

    assign tx_data      = wd_buffer_o[tx_cnt*8 +: 8];
    assign rx_ready     = is_scanf;
    assign hrdata       = rdata;
    assign hresp        = buf_resp | reg_resp;
    assign last_rx_cnt  = rx_cnt + 2'b11;
    assign last_tx_cnt  = tx_cnt + 2'b11;
    assign wd_buffer_i  = wdata;

    typedef enum logic [2:0] {
        IDLE,
        WADDR,
        RADDR,
        WREG,
        RREG,
        WRITE,
        READ
    } h2u_fsm_state_t;

    logic [2:0] state, n_state;

    always_ff @(posedge clk or negedge rstn) begin : H2U_FSM
        if (!rstn) begin
            state <= IDLE; 
        end
        else begin
            state <= n_state;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin : UPD_REG
        if (!rstn) is_scanf = 0;
        else if (state == WREG) is_scanf = hwdata[0];
    end
    
    // data sample
    always_comb begin : H2U_STATE_BEHAVIOR
        case (state)
        IDLE: begin
            if (hsel && hwrite) n_state = WADDR;
            else if (hsel && !hwrite) n_state = RADDR;
            wdata = 'b0;
            rdata = 'b0;
            wd_buffer_wen = 'b0;
            rd_buffer_ren = 'b0;
            hready = 'b0;
            reg_resp = 'b0;
            buf_resp = 'b0;
        end            
        WADDR: begin
            if (haddr[30]) n_state = WREG;
            else if (!(|wd_buffer_full)) n_state = WRITE;
            hready = haddr[30] | !(|wd_buffer_full);
        end
        RADDR: begin
            if (haddr[30]) n_state = RREG;
            else if (!(|rd_buffer_empty)) n_state = READ;
            rd_buffer_ren = !haddr[30] && !(|rd_buffer_empty);
        end
        WREG: begin
            n_state = IDLE;
            reg_resp = 'b1;
            hready = 'b0;
        end
        RREG: begin
            n_state = IDLE;
            rdata = {31'b0, is_scanf};
            hready = 'b1;
        end
        WRITE: begin
            n_state = IDLE;
            wdata = hwdata;
            wd_buffer_wen = 'b1;
            buf_resp = 'b1;
            hready = 'b0;
        end
        READ: begin
            n_state = IDLE;
            rdata = rd_buffer_o;
            rd_buffer_ren = 'b0;
            hready = 'b1;
        end
        default: begin
            n_state = IDLE;
        end
        endcase
    end

    
    // tx
    always_ff @( posedge clk or negedge rstn ) begin : TX_COUNTER
        if (!rstn) begin
            tx_cnt <= 'b0;
        end
        else if (tx_valid && tx_ready) tx_cnt <= tx_cnt + 'b1;
    end
    always_ff @( posedge clk or negedge rstn ) begin : TX_TRANS
        if (!rstn) begin
            tx_valid <= 'b0;
            wd_buffer_ren <= 'b0;
            biu <= 'b0;
        end
        else begin
            wd_buffer_ren[tx_cnt] <= tx_ready & !(&wd_buffer_empty);
            wd_buffer_ren[last_tx_cnt] <= 1'b0;
            biu <= wd_buffer_ren[tx_cnt];   
            tx_valid <= wd_buffer_ren[tx_cnt]; // 1 cycle after wd_buffer_ren 
        end
    end

    // rx
    always_ff @( posedge clk or negedge rstn ) begin : RX_COUNTER
        if (!rstn) begin
            rx_cnt <= 'b0;
        end
        else if (rx_valid && rx_ready) rx_cnt <= rx_cnt + 'b1;
    end
    always_ff @( posedge clk or negedge rstn ) begin : RX_TRANS
        if (!rstn) begin
            rd_buffer_wen <= 'b0;
            rd_buffer_i <= 'b0;
        end
        else begin
            rd_buffer_wen[rx_cnt] <= rx_valid;
            rd_buffer_wen[last_rx_cnt] <= 1'b0;
            rd_buffer_i[rx_cnt*8 +: 8] <= rx_data;
        end
    end

    for (genvar i = 0; i < 4; i++) begin : READ_DATA_BUFFER
        fifo #(
            .DATA_WIDTH     (8),
            .DATA_DEPTH     (8)
        ) rd_buffer (
            .clk            (clk),
            .rstn           (rstn),
            .data_in        (rd_buffer_i[i*8 +: 8]),
            .rd_en          (rd_buffer_ren),
            .wr_en          (rd_buffer_wen[i]),
            .data_out       (rd_buffer_o[i*8 +: 8]),
            .full           (rd_buffer_full[i]),
            .empty          (rd_buffer_empty[i])
        );
    end

    for (genvar i = 0; i < 4; i++) begin : WRITE_DATA_BUFFER
        fifo #(
            .DATA_WIDTH     (8),
            .DATA_DEPTH     (8)
        ) wd_buffer (
            .clk            (clk),
            .rstn           (rstn),
            .data_in        (wd_buffer_i[i*8 +: 8]),
            .rd_en          (wd_buffer_ren[i]),
            .wr_en          (wd_buffer_wen),
            .data_out       (wd_buffer_o[i*8 +: 8]),
            .full           (wd_buffer_full[i]),
            .empty          (wd_buffer_empty[i])
        );
    end

endmodule