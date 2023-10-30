`include "inst_define.v"

module gpr (
    input               clk,
    input               rstn,

    // read
    input           [4:0]   reg_addr_rs1,
    input           [4:0]   reg_addr_rs2,
    output          [31:0]  reg_data_rs1,
    output          [31:0]  reg_data_rs2,

    // write
    input           [4:0]   reg_addr_rd,

    input           [31:0]  alu_data_out,
    input           [31:0]  alu_pc_out,
    input           [31:0]  imme,
    input           [31:0]  alu_pc_seq,
    input           [31:0]  mem_data_out,
    input           [31:0]  csr_data_out,

    input           [5:0]   op_type,
    input           [6:0]   opcode
);

    reg [31:0] gpr [31:0];
    import "DPI-C" function void set_ptr_gpr(input logic [31:0] gpr []);

    wire reg_wr_en;
    wire [31:0] reg_data_rd;

    assign reg_wr_en = (opcode != `branch) && (opcode != `store) && (opcode != `fence) && (op_type != `op_type_ecall) && (op_type != `op_type_ebreak);
    assign reg_data_rd = (op_type == `op_type_lui) ? imme :
                         (op_type == `op_type_auipc) ? alu_pc_out :
                         (op_type == `op_type_jal || op_type == `op_type_jalr) ? alu_pc_seq :
                         (opcode == `system && (op_type != `op_type_ecall) && (op_type != `op_type_ebreak)) ? csr_data_out :
                         (opcode == `load) ? mem_data_out : alu_data_out;

    integer i;
    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            for(i = 0 ; i < 32 ; i = i + 1)
                gpr[i] <= i == 5'd2 ? `RESET_VECTOR : 32'd0;
        else if(reg_wr_en)
            gpr[reg_addr_rd] <= (reg_addr_rd == 5'd0) ? 32'd0 : reg_data_rd;
    end

    assign reg_data_rs1 = gpr[reg_addr_rs1];
    assign reg_data_rs2 = gpr[reg_addr_rs2];

    // always @(posedge clk) begin
    //     if(reg_wr_en)
    //         $display("writing data %0d into %0d", $signed(reg_data_rd), reg_addr_rd);
    // end

    always @(posedge clk) begin
        if(op_type == `op_type_ecall && gpr[17] == 32'd93) begin
            if(gpr[10] == 'd0)
                $display("Pass!!!");
            else
                $display("Fail!!!");
            #(1) $finish;
        end
    end

    initial  begin
        set_ptr_gpr(gpr);
    end

endmodule //gpr