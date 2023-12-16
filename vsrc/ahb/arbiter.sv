`include "const_defines.v"

module arbiter (
    input clk,
    input rstn,

    input hbusreq_0,
    input hbusreq_1,

    output reg hgrant_0,
    output reg hgrant_1
);

    typedef enum logic {
        IDLE,
        BUSY
    } fsm_state_t;

    logic state, n_state;

    always_ff @(posedge clk or negedge rstn) begin : FSM
        if (!rstn) begin
        state <= IDLE; 
        end
        else begin
        state <= n_state;
        end
    end

    always_comb begin : STATE_BEHAVIOR
        case (state)
        IDLE: begin
            if (hbusreq_0 || hbusreq_1) begin
                n_state = BUSY;
            end
            hgrant_0 = 'b0;
            hgrant_1 = 'b0;
        end
            
        BUSY: begin
            if ((hgrant_0 && !hbusreq_0) || (hgrant_1 && !hbusreq_1)) begin
                n_state = IDLE;
            end
            hgrant_0 = hbusreq_0;
            hgrant_1 = hbusreq_0 ? 'b0 : hbusreq_1;
        end

        default: begin
            n_state = IDLE;
            hgrant_0 = 'b0;
            hgrant_1 = 'b0;
        end
        endcase
    end

endmodule