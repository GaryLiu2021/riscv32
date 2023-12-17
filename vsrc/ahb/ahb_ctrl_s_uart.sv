`include "const_defines.v"

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

    wire [`AHB_DATA_WIDTH - 1:0]        wd_buffer_i;
    wire [`AHB_DATA_WIDTH - 1:0]        wd_buffer_o;
    reg [3:0]                           wd_buffer_ren_t1;
    reg                                 wd_buffer_wen;
    wire [3:0]                          wd_buffer_full;
    wire [3:0]                          wd_buffer_empty;
    reg [3:0]                           wd_buffer_ren_tmp;
    wire [3:0]                          wd_buffer_ren;

    reg  [`AHB_DATA_WIDTH - 1:0]        rd_buffer_i;
    wire [`AHB_DATA_WIDTH - 1:0]        rd_buffer_o;
    reg                                 rd_buffer_ren;
    reg [3:0]                           rd_buffer_wen;
    wire [3:0]                          rd_buffer_full;
    wire [3:0]                          rd_buffer_empty;

    reg [`AHB_ADDR_WIDTH - 1:0]         addr; 
    reg [`AHB_DATA_WIDTH - 1:0]         rdata;
    reg [`AHB_DATA_WIDTH - 1:0]         wdata;
    reg                                 biu;
    reg                                 reg_resp;
    reg                                 buf_resp;
    reg [1:0]                           tx_cnt;
    reg [1:0]                           rx_cnt;
    wire [1:0]                          last_tx_cnt;
    wire [1:0]                          last_rx_cnt;

    reg [`AHB_ADDR_WIDTH - 1:0]         addr_s;
    reg [`AHB_DATA_WIDTH - 1:0]         wdata_s;
    reg [`AHB_DATA_WIDTH - 1:0]         rdata_s;
    reg                                 wd_buffer_wen_s;
    reg                                 rd_buffer_ren_s;
    reg                                 hready_s;
    reg                                 reg_resp_s;
    reg                                 buf_resp_s;

    wire                                scanf_reg; // rd_buffer非空，设置成1
    wire                                printf_reg; // wd_buffer非满，设置成1
    reg                                 rx_finish;
    reg                                 rx_finish_s;

    always_ff @(posedge clk or negedge rstn) begin : STORE
        if (!rstn) begin
            addr_s <= 'b0;
            wdata_s <= 'b0;
            rdata_s <= 'b0;
            wd_buffer_wen_s <= 'b0;
            rd_buffer_ren_s <= 'b0;
            hready_s <= 'b0;
            reg_resp_s <= 'b0;
            buf_resp_s <= 'b0;
            rx_finish_s <= 'b0;
            wd_buffer_ren_tmp <= 'b0;
        end
        else begin
            addr_s <= addr;
            wdata_s <= wdata;
            rdata_s <= rdata;
            wd_buffer_wen_s <= wd_buffer_wen;
            rd_buffer_ren_s <= rd_buffer_ren;
            hready_s <= hready;
            reg_resp_s <= reg_resp;
            buf_resp_s <= buf_resp;
            rx_finish_s <= rx_finish;
            wd_buffer_ren_tmp <= wd_buffer_ren_t1;
        end
    end

    assign tx_data      = wd_buffer_o[tx_cnt*8 +: 8];
    assign rx_ready     = !(&rd_buffer_full);
    assign hrdata       = rdata;
    assign hresp        = buf_resp | reg_resp;
    assign last_rx_cnt  = rx_cnt + 2'b1;
    assign last_tx_cnt  = tx_cnt + 2'b1;
    assign wd_buffer_i  = wdata;
    assign wd_buffer_ren = wd_buffer_ren_t1 & ~wd_buffer_ren_tmp;

    assign scanf_reg    = !(|rd_buffer_empty);
    assign printf_reg   = !(|wd_buffer_full);

    typedef enum logic [2:0] {
        IDLE,
        WADDR,
        RADDR,
        RREG,
        WRITE,
        READ
    } h2u_fsm_state_t;

    logic [2:0] a2u_state, n_a2u_state;

    always_ff @(posedge clk or negedge rstn) begin : H2U_FSM
        if (!rstn) begin
            a2u_state <= IDLE; 
        end
        else begin
            a2u_state <= n_a2u_state;
        end
    end
    
    // data/addr sample
    always_comb begin : H2U_STATE_BEHAVIOR
        case (a2u_state)
        IDLE: begin
            if (hsel && hwrite) n_a2u_state = WADDR;
            else if (hsel && !hwrite) n_a2u_state = RADDR;
            else n_a2u_state = IDLE;
            addr = 'b0;
            wdata = 'b0;
            rdata = 'b0;
            wd_buffer_wen = 'b0;
            rd_buffer_ren = 'b0;
            hready = 'b0;
            reg_resp = 'b0;
            buf_resp = 'b0;
        end            
        WADDR: begin
            if (!(|wd_buffer_full)) n_a2u_state = WRITE;
            else n_a2u_state = WADDR;
            hready = haddr[30] | !(|wd_buffer_full);
            addr = haddr;
            wdata = wdata_s;
            rdata = rdata_s;
            wd_buffer_wen = wd_buffer_wen_s;
            rd_buffer_ren = rd_buffer_ren_s;
            reg_resp = reg_resp_s;
            buf_resp = buf_resp_s;
        end
        RADDR: begin
            if (!(haddr[1] && haddr[2])) begin
                n_a2u_state = RREG;
                rd_buffer_ren = rd_buffer_ren_s;
            end
            else if (!(|rd_buffer_empty)) begin
                n_a2u_state = READ;
                rd_buffer_ren = !haddr[30] && !(|rd_buffer_empty);
            end
            else begin
                n_a2u_state = RADDR;
                rd_buffer_ren = rd_buffer_ren_s;
            end
            addr = haddr;
            hready = hready_s;
            wdata = wdata_s;
            rdata = rdata_s;
            wd_buffer_wen = wd_buffer_wen_s;
            reg_resp = reg_resp_s;
            buf_resp = buf_resp_s;
        end
        RREG: begin
            n_a2u_state = IDLE;
            if (addr_s[1]) rdata = {31'b0, printf_reg};
            else rdata = {31'b0, scanf_reg};
            hready = 'b1;
            addr = addr_s;
            reg_resp = reg_resp_s;
            buf_resp = buf_resp_s;
            wdata = wdata_s;
            wd_buffer_wen = wd_buffer_wen_s;
            rd_buffer_ren = rd_buffer_ren_s;
        end
        WRITE: begin
            n_a2u_state = IDLE;
            wdata = hwdata;
            wd_buffer_wen = 'b1;
            buf_resp = 'b1;
            hready = 'b0;
            addr = addr_s;
            reg_resp = reg_resp_s;
            rd_buffer_ren = rd_buffer_ren_s;
            rdata = rdata_s;
            $display("UART: Recved string %h", hwdata);
        end
        READ: begin
            n_a2u_state = IDLE;
            rdata = rd_buffer_o;
            rd_buffer_ren = 'b0;
            hready = 'b1;
            addr = addr_s;
            reg_resp = reg_resp_s;
            buf_resp = buf_resp_s;
            wdata = wdata_s;
            wd_buffer_wen = wd_buffer_wen_s;
        end
        default: begin
            n_a2u_state = IDLE;
            addr = addr_s;
            rdata = rdata_s;
            rd_buffer_ren = rd_buffer_ren_s;
            hready = hready_s;
            reg_resp = reg_resp_s;
            buf_resp = buf_resp_s;
            wdata = wdata_s;
            wd_buffer_wen = wd_buffer_wen_s;
        end
        endcase
    end

    // tx
    always_ff @( posedge clk or negedge rstn ) begin : TX_COUNTER
        if (!rstn) begin
            tx_cnt <= ~'b0;
        end
        else if (tx_valid && tx_ready) tx_cnt <= tx_cnt - 'b1;
    end
    always_ff @( posedge clk or negedge rstn ) begin : TX_TRANS
        if (!rstn) begin
            tx_valid <= 'b0;
            wd_buffer_ren_t1 <= 'b0;
            biu <= 'b0;
        end
        else begin
            wd_buffer_ren_t1[tx_cnt] <= tx_ready & !(&wd_buffer_empty);
            wd_buffer_ren_t1[last_tx_cnt] <= 1'b0;
            biu <= wd_buffer_ren_t1[tx_cnt];   
            tx_valid <= wd_buffer_ren_t1[tx_cnt]; // 1 cycle after wd_buffer_ren_t1 
        end
    end

    // rx
    typedef enum logic {
        ON_SCANF,
        END_SCANF
    } rx_fsm_state_t;
    logic rx_state, n_rx_state;

    always_ff @(posedge clk or negedge rstn) begin : RX_FSM
        if (!rstn) begin
            rx_state <= ON_SCANF; 
        end
        else begin
            rx_state <= n_rx_state;
        end
    end

    always_comb begin : RX_STATE_BEHAVIOR
        case (rx_state)
        ON_SCANF:
        begin
            if (rx_data == `RX_END && rx_valid && rx_cnt != 'b0) n_rx_state = END_SCANF;
            else n_rx_state = ON_SCANF;
            rx_finish = 'b0;
        end
        END_SCANF:
        begin
            if (rx_cnt == 'b0) n_rx_state = ON_SCANF;
            else n_rx_state = END_SCANF;
            rx_finish = rx_cnt == 'b0;
        end  
        default: 
        begin
            n_rx_state = ON_SCANF;
            rx_finish = 'b0;
        end
        endcase
    end

    always_ff @( posedge clk or negedge rstn ) begin : RX_COUNTER
        if (!rstn) begin
            rx_cnt <= ~'b0;
        end
        else begin
            case (rx_state)
                ON_SCANF: if (rx_valid && rx_ready) rx_cnt <= rx_cnt - 'b1;
                END_SCANF: if (|rd_buffer_wen) rx_cnt <= rx_cnt - 'b1;
                default: ;
            endcase
        end
    end
    
    always_ff @( posedge clk or negedge rstn ) begin : RX_TRANS
        if (!rstn) begin
            rd_buffer_wen <= 'b0;
            rd_buffer_i <= 'b0;
        end
        else begin
            case (rx_state)
                ON_SCANF: begin
                    rd_buffer_wen[rx_cnt] <= rx_valid;
                    rd_buffer_wen[last_rx_cnt] <= 1'b0;
                    rd_buffer_i[rx_cnt*8 +: 8] <= rx_data;                
                end
                END_SCANF: begin
                    rd_buffer_wen[rx_cnt] <= 1'b1;
                    rd_buffer_wen[last_rx_cnt] <= 1'b0;
                    rd_buffer_i[rx_cnt*8 +: 8] <= 'b0; 
                end
                default: ;
            endcase
        end
    end

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : READ_DATA_BUFFER
            fifo #(
                .DATA_WIDTH     (8),
                .DATA_DEPTH     (8)
            ) rd_buffer_bank (
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
    endgenerate

    generate
        for (i = 0; i < 4; i++) begin : WRITE_DATA_BUFFER
            fifo #(
                .DATA_WIDTH     (8),
                .DATA_DEPTH     (8)
            ) wd_buffer_bank (
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
    endgenerate

endmodule