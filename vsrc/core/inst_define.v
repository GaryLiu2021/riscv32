`ifndef __INST_DEFINE
`define __INST_DEFINE

`define RESET_VECTOR 32'h80000000
// U type: long imme
`define lui     7'b0110111
`define auipc   7'b0010111

// J Type: jump
`define jal     7'b1101111

// I Type: short imme and load
`define jalr    7'b1100111
`define load    7'b0000011
`define alui    7'b0010011
`define fence   7'b0001111
`define system  7'b1110011

// S Type: store
`define store   7'b0100011

// B Type: branch
`define branch  7'b1100011

// R Type: execution
`define alur    7'b0110011


`define op_type_lui      6'd0
`define op_type_auipc    6'd1
`define op_type_jal      6'd2
`define op_type_jalr     6'd3

`define op_type_beq      6'd4
`define op_type_bne      6'd5
`define op_type_blt      6'd6
`define op_type_bge      6'd7
`define op_type_bltu     6'd8
`define op_type_bgeu     6'd9

`define op_type_lb       6'd10
`define op_type_lh       6'd11
`define op_type_lw       6'd12
`define op_type_lbu      6'd13
`define op_type_lhu      6'd14

`define op_type_sb       6'd15
`define op_type_sh       6'd16
`define op_type_sw       6'd17

`define op_type_addi     6'd18
`define op_type_slti     6'd19
`define op_type_sltiu    6'd20
`define op_type_xori     6'd21
`define op_type_ori      6'd22
`define op_type_andi     6'd23
`define op_type_slli     6'd24
`define op_type_srli     6'd25
`define op_type_srai     6'd26

`define op_type_add      6'd27
`define op_type_sub      6'd28
`define op_type_sll      6'd29
`define op_type_slt      6'd30
`define op_type_sltu     6'd31
`define op_type_xor      6'd32
`define op_type_srl      6'd33
`define op_type_sra      6'd34
`define op_type_or       6'd35
`define op_type_and      6'd36

`define op_type_fence    6'd37
`define op_type_fencei   6'd38
`define op_type_ecall    6'd39
`define op_type_ebreak   6'd40
`define op_type_csrrw    6'd41
`define op_type_csrrs    6'd42
`define op_type_csrrc    6'd43
`define op_type_csrrwi   6'd44
`define op_type_csrrsi   6'd45
`define op_type_csrrci   6'd46
`define op_type_error    6'd47

`define zero_word       32'd0

`endif