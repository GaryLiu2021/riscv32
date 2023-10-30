`include "inst_define.v"

module reg_pc (
    input               clk,
    input               rstn,

    input       [5:0]   op_type,
    input       [31:0]  alu_data_out,
    input       [31:0]  alu_pc_out,
    input       [31:0]  alu_pc_seq,

    output  reg [31:0]  pc_out
);

    reg [31:0] pc_new;

    always @(*) begin
        case(op_type)
            `op_type_beq, `op_type_bge, `op_type_bgeu:
                pc_new = alu_data_out[0] ? alu_pc_seq : alu_pc_out;
            `op_type_bne, `op_type_blt, `op_type_bltu:
                pc_new = alu_data_out[0] ? alu_pc_out : alu_pc_seq;
            `op_type_jal, `op_type_jalr:
                pc_new = alu_pc_out;
            default:
                pc_new = alu_pc_seq;
        endcase
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            pc_out <= `zero_word + `RESET_VECTOR;
        else begin
            pc_out <= pc_new;
        end
    end

endmodule //reg_pc