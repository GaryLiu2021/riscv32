`include "inst_define.v"

import "DPI-C" function void set_ptr_pc(input logic [31:0] pc_out []);
import "DPI-C" function void set_ptr_inst(input logic [31:0] mem_inst_out []);
import "DPI-C" function void call_return();

module dpi_verilator(
    input                   clk,
    input                   rstn,
    input       [31:0]      mem_inst_out,
    input       [31:0]      mem_data_addr,
    input       [31:0]      mem_data_in,
    input       [31:0]      mem_data_out,
    input       [31:0]      pc_out,
    input       [31:0]      imme,
    input       [31:0]      reg_addr_rd,
    input       [31:0]      reg_addr_rs1,
    input       [31:0]      reg_data_rs1,
    input       [31:0]      reg_addr_rs2,
    input       [6:0]       opcode,
    input       [5:0]       op_type
);
    reg [63:0] inst_str [63:0];
    initial begin
        inst_str[`op_type_lui]      <= "lui";
        inst_str[`op_type_auipc]    <= "auipc";
        inst_str[`op_type_jal]      <= "jal";
        inst_str[`op_type_jalr]     <= "jalr";
        inst_str[`op_type_beq]      <= "beq";
        inst_str[`op_type_bne]      <= "bne";
        inst_str[`op_type_blt]      <= "blt";
        inst_str[`op_type_bge]      <= "bge";
        inst_str[`op_type_bltu]     <= "bltu";
        inst_str[`op_type_bgeu]     <= "bgeu";
        inst_str[`op_type_lb]       <= "lb";
        inst_str[`op_type_lh]       <= "lh";
        inst_str[`op_type_lw]       <= "lw";
        inst_str[`op_type_lbu]      <= "lbu";
        inst_str[`op_type_lhu]      <= "lhu";
        inst_str[`op_type_sb]       <= "sb";
        inst_str[`op_type_sh]       <= "sh";
        inst_str[`op_type_sw]       <= "sw";
        inst_str[`op_type_addi]     <= "addi";
        inst_str[`op_type_slti]     <= "slti";
        inst_str[`op_type_sltiu]    <= "sltiu";
        inst_str[`op_type_xori]     <= "xori";
        inst_str[`op_type_ori]      <= "ori";
        inst_str[`op_type_andi]     <= "andi";
        inst_str[`op_type_slli]     <= "slli";
        inst_str[`op_type_srli]     <= "srli";
        inst_str[`op_type_srai]     <= "srai";
        inst_str[`op_type_add]      <= "add";
        inst_str[`op_type_sub]      <= "sub";
        inst_str[`op_type_sll]      <= "sll";
        inst_str[`op_type_slt]      <= "slt";
        inst_str[`op_type_sltu]     <= "sltu";
        inst_str[`op_type_xor]      <= "xor";
        inst_str[`op_type_srl]      <= "srl";
        inst_str[`op_type_sra]      <= "sra";
        inst_str[`op_type_or]       <= "or";
        inst_str[`op_type_and]      <= "and";
        inst_str[`op_type_fence]    <= "fence";
        inst_str[`op_type_fencei]   <= "fencei";
        inst_str[`op_type_ecall]    <= "ecall";
        inst_str[`op_type_ebreak]   <= "ebreak";
        inst_str[`op_type_csrrw]    <= "csrrw";
        inst_str[`op_type_csrrs]    <= "csrrs";
        inst_str[`op_type_csrrc]    <= "csrrc";
        inst_str[`op_type_csrrwi]   <= "csrrwi";
        inst_str[`op_type_csrrsi]   <= "csrrsi";
        inst_str[`op_type_csrrci]   <= "csrrci";
        inst_str[`op_type_error]    <= "error";
    end

    reg [31:0] reg_name [31:0];
    initial begin
        reg_name[0] <= "zero";
        reg_name[1] <= "ra";
        reg_name[2] <= "sp";
        reg_name[3] <= "gp";
        reg_name[4] <= "tp";
        reg_name[5] <= "t0";
        reg_name[6] <= "t1";
        reg_name[7] <= "t2";
        reg_name[8] <= "s0";
        reg_name[9] <= "s1";
        reg_name[10] <= "a0";
        reg_name[11] <= "a1";
        reg_name[12] <= "a2";
        reg_name[13] <= "a3";
        reg_name[14] <= "a4";
        reg_name[15] <= "a5";
        reg_name[16] <= "a6";
        reg_name[17] <= "a7";
        reg_name[18] <= "s2";
        reg_name[19] <= "s3";
        reg_name[20] <= "s4";
        reg_name[21] <= "s5";
        reg_name[22] <= "s6";
        reg_name[23] <= "s7";
        reg_name[24] <= "s8";
        reg_name[25] <= "s9";
        reg_name[26] <= "s10";
        reg_name[27] <= "s11";
        reg_name[28] <= "t3";
        reg_name[29] <= "t4";
        reg_name[30] <= "t5";
        reg_name[31] <= "t6";
    end
    
    initial begin
        set_ptr_pc(pc_out);
        set_ptr_inst(mem_inst_out);
    end

    always @(posedge clk) begin
        if(mem_inst_out == 32'b00000000000100000000000001110011) // ebreak
            call_return();
        if(mem_inst_out == 32'b00000000000000000000000001110011) // ecall
            call_return();
        if(mem_inst_out == 32'b00000000000000001000000001100111) // return
            call_return();
    end

    reg [63:0] counter;
    initial begin
        counter = 'd0;
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            counter <= 'd1;
        else begin
            counter <= counter + 1'b1;
            // $display("\n\t\t\tCycle %0d\n", counter);
            case(opcode)
                `system:
                    case(op_type)
                        `op_type_csrrc,`op_type_csrrs,`op_type_csrrw:
                            $display("Addr: %h Inst: %b, %0s %0s,%0d,%0s\n%0s:%0d", pc_out, mem_inst_out, inst_str[op_type], reg_name[reg_addr_rd], $signed(imme[16:5]), reg_name[reg_addr_rs1], reg_name[reg_addr_rs1], reg_data_rs1);
                        `op_type_csrrci,`op_type_csrrsi,`op_type_csrrwi:
                            $display("Addr: %h Inst: %b, %0s %0s,%0d,%0d", pc_out, mem_inst_out, inst_str[op_type], reg_name[reg_addr_rd], $signed(imme[16:5]), $signed(imme[4:0]));
                        default:
                            $display("Addr: %h Inst: %b, %0s", pc_out, mem_inst_out, inst_str[op_type]);
                    endcase
                `alur:
                    $display("Addr: %h Inst: %b, %0s %0s,%0s,%0s", pc_out, mem_inst_out, inst_str[op_type], reg_name[reg_addr_rd], reg_name[reg_addr_rs1], reg_name[reg_addr_rs2]);
                `jalr, `load, `fence:
                    $display("Addr: %h Inst: %b, %0s %0s,%0d(%0s)", pc_out, mem_inst_out, inst_str[op_type], reg_name[reg_addr_rd], $signed(imme), reg_name[reg_addr_rs1]);
                `branch:
                    $display("Addr: %h Inst: %b, %0s %0s,%0s,%0d", pc_out, mem_inst_out, inst_str[op_type], reg_name[reg_addr_rs1], reg_name[reg_addr_rs2], $signed(imme));
                `store:
                    $display("Addr: %h Inst: %b, %0s %0s,%0d(%0s)", pc_out, mem_inst_out, inst_str[op_type], reg_name[reg_addr_rs2], $signed(imme), reg_name[reg_addr_rs1]);
                `jal, `auipc, `lui:
                    $display("Addr: %h Inst: %b, %0s %0s,%0d", pc_out, mem_inst_out, inst_str[op_type], reg_name[reg_addr_rd], $signed(imme));
                `alui:
                    $display("Addr: %h Inst: %b, %0s %0s,%0s,%0d", pc_out, mem_inst_out, inst_str[op_type], reg_name[reg_addr_rd], reg_name[reg_addr_rs1], $signed(imme));
                default:
                    $display("Addr: %h Inst: %b\nUnkwown Type!\n", pc_out, mem_inst_out);
            endcase
            if(opcode == `store)
                $display("mem_addr: %h, mem_data_in: %d, mem_data_out: %d", mem_data_addr, mem_data_in, mem_data_out);
            else if(opcode == `load)
                $display("mem_addr: %h, mem_data_out: %d", mem_data_addr, mem_data_out);
        end
    end

endmodule