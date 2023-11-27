`include "inst_define.v"

module stage_loadstore (
    input       [31:0]  alu_data_out,
    input       [5:0]   op_type,
    input       [31:0]  reg_data_rs2,

    output      [31:0]  mem_data_in,
    output      [31:0]  mem_data_addr,

    // ddr controller signal
    output              mem_data_wr_en
);

    //**Store Logic

    assign mem_data_in = (op_type == `op_type_sb) ? reg_data_rs2[7:0] :
                         (op_type == `op_type_sh) ? reg_data_rs2[15:0]:
                         (op_type == `op_type_sw) ? reg_data_rs2      : `zero_word;
                        
    assign mem_data_addr = alu_data_out;
    assign mem_data_wr_en = (op_type == `op_type_sb) || (op_type == `op_type_sh) || (op_type == `op_type_sw);

    //**Load Logic


endmodule //stage_loadstore