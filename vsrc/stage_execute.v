`include "inst_define.v"

module stage_execute (
    input       [6:0]   opcode,
    input       [31:0]  imme,
    input       [31:0]  reg_data_rs1,
    input       [31:0]  reg_data_rs2,
    input       [31:0]  reg_data_pc,
    input       [5:0]   op_type,

    output      [31:0]  alu_data_out,
    output      [31:0]  alu_pc_out,
    output      [31:0]  alu_pc_seq
);

    // ADDER

    wire adder_enable;
    wire [31:0] adder_data_in1, adder_data_in2, adder_data_in2_sig;
    wire [31:0] adder_out, adder_data_out;
    wire adder_carry_in, adder_carry_out;
    wire lt_data_out, ltu_data_out, neq_data_out;
    
    assign adder_enable = ((op_type == `op_type_addi)  || (op_type == `op_type_add) || (op_type == `op_type_slti) || (op_type == `op_type_slt) ||
                          (op_type == `op_type_sltu) || (op_type == `op_type_sltiu) || (op_type == `op_type_auipc) || (op_type == `op_type_jal) || 
                          (op_type == `op_type_jalr) || (opcode == `branch) || (opcode == `store) || (opcode == `load) || (op_type == `op_type_sub));
    // adder in1可能是pc、rs1 ---- pc:auipc/jal/jalr/branch
    assign adder_data_in1 = reg_data_rs1;
    // adder in2可能是imme(auipc,jal,jalr,load,store,addi,slti,sltiu)
    assign adder_data_in2 = (opcode == `auipc || opcode == `jal || opcode == `jalr || opcode == `load || opcode == `store || op_type == `op_type_addi || op_type == `op_type_slti || op_type == `op_type_sltiu) ? imme : reg_data_rs2;
    // 减法(branch,slti,sltiu,slt,sub)
    // 减法情况下需要将data2取反
    assign adder_carry_in = (op_type == `op_type_sub || op_type == `op_type_slt || op_type == `op_type_slti || opcode == `branch || op_type == `op_type_sltu || op_type == `op_type_sltiu) ? 1'b1 : 1'b0;
    assign adder_data_in2_sig = adder_carry_in ? ~adder_data_in2 : adder_data_in2;
    assign {adder_carry_out, adder_out} = adder_data_in1 + adder_data_in2_sig + adder_carry_in;

    // 正-负=正、负-正=负、正-正 and 负-负：如果没有进位则=负，有进位则=正
    assign lt_data_out = (adder_data_in1[31] && ~adder_data_in2[31]) || ((adder_data_in1[31]==adder_data_in2[31]) && ~adder_carry_out);
    // 正-正 看进位
    assign ltu_data_out = ~adder_carry_out;
    assign neq_data_out = (|adder_out);

    assign adder_data_out = (op_type == `op_type_slt || op_type == `op_type_slti || op_type == `op_type_blt || op_type == `op_type_bge) ? {{31{1'b0}}, lt_data_out}  :
                            (op_type == `op_type_sltu || op_type == `op_type_sltiu || op_type == `op_type_bltu || op_type == `op_type_bgeu)                         ? {{31{1'b0}}, ltu_data_out} :
                            (op_type == `op_type_beq || op_type == `op_type_bne)                                                        ? {{31{1'b0}}, neq_data_out} : adder_out;

    // End of Adder

    // PC Adder

    assign alu_pc_out = (op_type == `op_type_jalr) ? (reg_data_rs1 + imme) & (~32'b1) : reg_data_pc + imme;
    assign alu_pc_seq = reg_data_pc + 4;

    // Logical Operation
    
    wire logic_enable;
    reg  [31:0] logic_data_out;

    always @(*) begin
        case(1)
            (op_type==`op_type_xori):
                logic_data_out = reg_data_rs1 ^ imme;
            (op_type==`op_type_xor):
                logic_data_out = reg_data_rs1 ^ reg_data_rs2;
            (op_type==`op_type_ori):
                logic_data_out = reg_data_rs1 | imme;
            (op_type==`op_type_or):
                logic_data_out = reg_data_rs1 | reg_data_rs2;
            (op_type==`op_type_andi):
                logic_data_out = reg_data_rs1 & imme;
            (op_type==`op_type_and):
                logic_data_out = reg_data_rs1 & reg_data_rs2;
            // default: logic_data_out = 32'd0;
        endcase
    end

    assign logic_enable = ((op_type==`op_type_xori) || (op_type==`op_type_xor) ||
                          (op_type==`op_type_or)  || (op_type==`op_type_ori) ||
                          (op_type==`op_type_andi) || (op_type==`op_type_and));
    
    // End of Logical Operation Module

    // Shift Operation

    wire shift_enable;
    reg  [31:0] shift_data_out;
    wire [4:0] shift_opnum = imme[4:0];
    wire signal_rs1 = reg_data_rs1[31];
    
    always @(*) begin
        case(1)
            (op_type==`op_type_sll):
                shift_data_out = reg_data_rs1 << reg_data_rs2[4:0];
            (op_type==`op_type_slli):
                shift_data_out = reg_data_rs1 << shift_opnum;
            (op_type==`op_type_srl):
                shift_data_out = reg_data_rs1 >> reg_data_rs2[4:0];
            (op_type==`op_type_srli):
                shift_data_out = reg_data_rs1 >> shift_opnum;
            (op_type==`op_type_sra):
                shift_data_out = {{32{signal_rs1}}, reg_data_rs1} >> (reg_data_rs2[4:0]);
            (op_type==`op_type_srai):
                shift_data_out = {{32{signal_rs1}}, reg_data_rs1} >> shift_opnum;
        endcase
    end

    assign shift_enable = ((op_type==`op_type_sll) || (op_type==`op_type_slli) ||
                          (op_type==`op_type_srl) || (op_type==`op_type_srli) ||
                          (op_type==`op_type_sra) || (op_type==`op_type_srai));

    // End of Shift Operation Module

    assign alu_data_out = adder_enable ? adder_data_out :
                          logic_enable ? logic_data_out :
                          shift_enable ? shift_data_out : `zero_word ;

endmodule //stage_execute