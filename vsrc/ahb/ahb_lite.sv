`include "const_defines.v"

module ahb_lite (
// GLOBAL
    input                               clk,
    input                               rstn,

// MASTER TO AHB
    input [`AHB_ADDR_WIDTH - 1:0]       haddr,
    input                               haddr_ctrl,
    input                               hwrite,
    input [`AHB_DATA_WIDTH - 1:0]       hwdata,
    input                               hbusreq, // r/w data, prior

// SLAVE TO AHB
    input                               hready,
    input                               hresp,
    input [`AHB_DATA_WIDTH - 1:0]       hrdata,

// AHB TO MASTER
    output reg                          hgrant,
    output [`AHB_DATA_WIDTH - 1:0]      hdata_s2m,
    output                              hresp_s2m,
    output                              hready_s2m,

// AHB TO SLAVE
    output [`AHB_DATA_WIDTH - 1:0]      hwdata_m2s,
    output [`AHB_ADDR_WIDTH - 1:0]      haddr_m2s,
    output                              hwrite_m2s,
    output                              hsel_0, // io
    output                              hsel_1  // ram
);
    
    logic [`AHB_ADDR_WIDTH - 1:0]       addr_channel;
    logic [`AHB_DATA_WIDTH - 1:0]       wdata_channel;
    logic [`AHB_DATA_WIDTH - 1:0]       rdata_channel;
    wire                                sel_0;
    wire                                sel_1;
    reg                                 sel_0_r;
    reg                                 sel_1_r;
    
    reg                                 sel_0_s;
    reg                                 sel_1_s;
    reg                                 grant_s;

    assign haddr_m2s = addr_channel;
    assign hwdata_m2s = wdata_channel;
    assign hdata_s2m = rdata_channel;
    assign hwrite_m2s = hwrite;
    assign hresp_s2m = hresp;
    assign hready_s2m = hready;
    assign hsel_0 = sel_0_r;
    assign hsel_1 = sel_1_r;

    typedef enum logic [2:0] {
        IDLE,
        ADDR,
        WRITE,
        READ,
        WHOLD,
        RHOLD,
        FINISH
    } ahb_state_t;

    logic [2:0] state, n_state;

    always_ff @(posedge clk or negedge rstn) begin : AHB_FSM
        if (!rstn) begin
            state <= IDLE; 
        end
        else begin
            state <= n_state;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin : ADDR_SAMPLE
        if (!rstn) begin
            addr_channel <= 'b0;
        end
        else begin
            if (state == ADDR) addr_channel <= haddr;
            else if (state == FINISH) addr_channel <= 'b0;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin : WDATA_SAMPLE
        if (!rstn) begin
            wdata_channel <= 'b0;
        end
        else begin
            if (state == WRITE || state == WHOLD) wdata_channel <= hready ? hwdata : 'b0;
            else if (state == FINISH) wdata_channel <= 'b0;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin : RDATA_SAMPLE
        if (!rstn) begin
            rdata_channel <= 'b0;
        end
        else begin
            if (state == READ || state == RHOLD) rdata_channel <= hready ? hrdata : 'b0;
            else if (state == FINISH) rdata_channel <= 'b0;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin : STORE
        if (!rstn) begin
            sel_0_s <= 'b0; 
            sel_1_s <= 'b0; 
            grant_s <= 'b0;
        end
        else begin
            sel_0_s <= sel_0_r; 
            sel_1_s <= sel_1_r;
            grant_s <= hgrant; 
        end
    end

    always_comb begin : STATE_BEHAVIOR
        case (state)
        IDLE: begin
            if (hbusreq) n_state = ADDR;
            else n_state = IDLE;
            sel_0_r = 'b0;
            sel_1_r = 'b0;
            hgrant = hbusreq;
        end
        ADDR: begin
            if (hgrant) begin
                if (haddr_ctrl && hwrite) n_state = WRITE;
                else if (haddr_ctrl && !hwrite) n_state = READ;
                else n_state = ADDR;
            end
            else n_state = IDLE;
            sel_0_r = sel_0;
            sel_1_r = sel_1;
            hgrant = grant_s;
        end
        WRITE: begin
            if (!hgrant) n_state = FINISH;
            else n_state = WHOLD;
            sel_0_r = sel_0_s;
            sel_1_r = sel_1_s;
            hgrant = grant_s;
        end
        READ: begin
            if (!hgrant) n_state = FINISH;
            else n_state = RHOLD;
            sel_0_r = sel_0_s;
            sel_1_r = sel_1_s;
            hgrant = grant_s;
        end
        WHOLD: begin
            n_state = FINISH;
            hgrant = 'b0;
            sel_0_r = sel_0_s;
            sel_1_r = sel_1_s;
        end
        RHOLD: begin
            if (hready) n_state = FINISH;
            else n_state = RHOLD;
            hgrant = 'b0;
            sel_0_r = sel_0_s;
            sel_1_r = sel_1_s;
        end
        FINISH: begin
            n_state = IDLE;
            hgrant = 'b0;
            sel_0_r = 'b0;
            sel_1_r = 'b0;
        end
        default: begin
            n_state = IDLE;
            hgrant = 'b0;
            sel_0_r = 'b0;
            sel_1_r = 'b0;
        end
        endcase
    end

    addr_decoder u_decoder (
        .addr       ( haddr         ),
        .addr_ctrl  ( haddr_ctrl    ),
        .hsel_0     ( sel_0         ),
        .hsel_1     ( sel_1         )
    );
    
endmodule