`include "inst_define.v"

module core_idu_dec (
    input       [31:0]  inst,
    output      [6:0]   opcode,
    output      [2:0]   func3,
    output              func7,
    output      [4:0]   reg_addr_rs1,
    output      [4:0]   reg_addr_rs2,
    output      [4:0]   reg_addr_rd,
    output  reg [5:0]   op_type,
    output  reg [31:0]  imme
);

    assign  opcode       = inst[6:0];
    assign  func3        = inst[14:12];
    assign  func7        = inst[30];
    assign  reg_addr_rs1 = inst[19:15];
    assign  reg_addr_rs2 = inst[24:20];
    assign  reg_addr_rd  = inst[11:7];

    wire inst_is_I_type, inst_is_U_type, inst_is_J_type, inst_is_B_type, inst_is_S_type, inst_is_R_type, inst_type_error;

    assign inst_is_I_type = (opcode == `jalr) | (inst[6:0] == `load) | (opcode == `alui) | (opcode == `fence);
    assign inst_is_U_type = (opcode == `lui) | (opcode == `auipc);
    assign inst_is_J_type = opcode == `jal;
    assign inst_is_B_type = opcode == `branch;
    assign inst_is_S_type = opcode == `store;
    assign inst_is_R_type = opcode == `alur;
    assign inst_is_csr_op = opcode == `system;
    assign inst_type_error = ~(inst_is_I_type || inst_is_U_type || inst_is_J_type || inst_is_B_type || inst_is_S_type || inst_is_R_type || inst_is_csr_op);

    always @(*) begin
        case(1)
            inst_is_I_type: imme = {{20{inst[31]}}, inst[31:20]};
            inst_is_U_type: imme = {inst[31:12], {12{1'b0}}};
            inst_is_J_type: imme = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            inst_is_B_type: imme = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            inst_is_S_type: imme = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            inst_is_csr_op: imme = {{15{inst[31]}}, inst[31:15]};
            inst_type_error:imme = 32'd0;
        endcase
    end

    always @(*) begin
        case(opcode)
            `auipc:
                op_type = `op_type_auipc;
            `lui:
                op_type = `op_type_lui;
            `alui:
                op_type = (func3 == 3'b000) ? `op_type_addi :
                          (func3 == 3'b010) ? `op_type_slti :
                          (func3 == 3'b011) ? `op_type_sltiu:
                          (func3 == 3'b100) ? `op_type_xori :
                          (func3 == 3'b110) ? `op_type_ori  :
                          (func3 == 3'b111) ? `op_type_andi :
                          (func3 == 3'b001) ? `op_type_slli :
                          (func7 == 1'b0)   ? `op_type_srli : `op_type_srai ;
            `alur:
                op_type = (func3 == 3'b000) ? ((func7 == 1'b0) ? `op_type_add : `op_type_sub) : 
                          (func3 == 3'b001) ? `op_type_sll :
                          (func3 == 3'b010) ? `op_type_slt :
                          (func3 == 3'b011) ? `op_type_sltu:
                          (func3 == 3'b100) ? `op_type_xor :
                          (func3 == 3'b110) ? `op_type_or  :
                          (func3 == 3'b111) ? `op_type_and :
                          (func7 == 1'b0)   ? `op_type_srl : `op_type_sra ;
            `branch:
                op_type = (func3 == 3'b000) ? `op_type_beq :
                          (func3 == 3'b001) ? `op_type_bne:
                          (func3 == 3'b100) ? `op_type_blt :
                          (func3 == 3'b101) ? `op_type_bge  :
                          (func3 == 3'b110) ? `op_type_bltu :
                          (func3 == 3'b111) ? `op_type_bgeu : `op_type_error;
            `jal:
                op_type = `op_type_jal;
            `jalr:
                op_type = `op_type_jalr;
            `load:
                op_type = (func3 == 3'b000) ? `op_type_lb :
                          (func3 == 3'b001) ? `op_type_lh :
                          (func3 == 3'b010) ? `op_type_lw :
                          (func3 == 3'b100) ? `op_type_lbu:
                          (func3 == 3'b101) ? `op_type_lhu: `op_type_error;
            `store:
                op_type = (func3 == 3'b000) ? `op_type_sb :
                          (func3 == 3'b001) ? `op_type_sh :
                          (func3 == 3'b010) ? `op_type_sw : `op_type_error;
            `fence:
                op_type = (func3 == 3'b000) ? `op_type_fence :
                          (func3 == 3'b001) ? `op_type_fencei: `op_type_error;
            `system:
                op_type = (func3 == 3'b000) ? ( inst[20] ? `op_type_ebreak : `op_type_ecall) :
                          (func3 == 3'b001) ? `op_type_csrrw :
                          (func3 == 3'b010) ? `op_type_csrrs :
                          (func3 == 3'b011) ? `op_type_csrrc :
                          (func3 == 3'b101) ? `op_type_csrrwi:
                          (func3 == 3'b110) ? `op_type_csrrsi:
                          (func3 == 3'b111) ? `op_type_csrrci: `op_type_error;
            default:
                op_type = `op_type_error;
        endcase
    end

endmodule //core_idu_dec
