`include "const_defines.svh"

module ahb2ram (
    // global
    input clk,
    input rstn,

    // ram
    output [`AHB_ADDR_WIDTH-1:0]        address,
    output                              rden,
    input [`AHB_DATA_WIDTH-1:0]         q,
    output                              wren,
    output [`AHB_DATA_WIDTH-1:0]        data,
    output [2:0]                        rwtyp,

    // ahb
    input [`AHB_DATA_WIDTH - 1:0]       hwdata,
    input [`AHB_ADDR_WIDTH - 1:0]       haddr,
    input                               hwrite,
    input                               hsel,
    output reg                          hready,
    output                              hresp,
    output [`AHB_DATA_WIDTH - 1:0]      hrdata 
);

    reg [`AHB_DATA_WIDTH - 1:0]         rdata;
    reg [`AHB_DATA_WIDTH - 1:0]         wdata;
    reg [`AHB_ADDR_WIDTH - 1:0]         addr; //此地址保留了完整内容，包括内容部分和信息部分
    reg                                 ren;
    reg                                 wen;

    assign rwtyp = addr[29:27];
    assign wren = wen;
    assign rden = ren;
    assign data = wdata;
    assign address = {16'b0, addr[15:0]};
    assign hrdata = rdata;
    assign hresp = wen;
    
    typedef enum logic [2:0] {
        IDLE,
        WADDR,
        RADDR,
        WRITE,
        READ
    } h2r_fsm_state_t;

    logic [2:0] state, n_state;

    always_ff @(posedge clk or negedge rstn) begin : H2U_FSM
        if (!rstn) begin
            state <= IDLE; 
        end
        else begin
            state <= n_state;
        end
    end
    
    // data/addr sample
    always_comb begin : H2U_STATE_BEHAVIOR
        case (state)
        IDLE: begin
            if (hsel && hwrite) n_state = WADDR;
            else if (hsel && !hwrite) n_state = RADDR;
            addr = 'b0;
            wdata = 'b0;
            rdata = 'b0;
            hready = 'b0;
            ren = 'b0;
            wen = 'b0;
        end            
        WADDR: begin
            n_state = WRITE;
            addr = haddr;
            hready = 'b1;
        end
        RADDR: begin
            n_state = READ;
            addr = haddr;
            ren = 'b1;
        end
        WRITE: begin
            n_state = IDLE;
            wdata = hwdata;
            wen = 'b1;
            hready = 'b0;
        end
        READ: begin
            n_state = IDLE;
            rdata = q;
            ren = 'b0;
            hready = 'b1;
        end
        default: begin
            n_state = IDLE;
        end
        endcase
    end

endmodule