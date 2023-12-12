`include "inst_define.v"

module csrs_csr (
    input               clk,
    input               rstn,

    output          [31:0]  csr_rd_data,

    // data source
    input           [31:0]  reg_data_rs1,
    input           [31:0]  imme,

    input           [5:0]   op_type,
    input           [6:0]   opcode
);

    reg [31:0] csrs [4095:0];

    wire csr_wr_en, csr_rd_en;
    wire [31:0] csr_wr_data;
    wire [31:0] zimm;
    wire [11:0] csr_addr;
    assign zimm = {{27{1'b0}}, imme[4:0]};
    assign csr_addr = imme[16:5];

    assign csr_wr_en = opcode == `system && op_type != `op_type_ecall && op_type != `op_type_ebreak;
    assign csr_wr_data = (op_type == `op_type_csrrw) ? reg_data_rs1 :
                         (op_type == `op_type_csrrs) ? (csr_rd_data | reg_data_rs1) :
                         (op_type == `op_type_csrrc) ? (csr_rd_data &~reg_data_rs1) :
                         (op_type == `op_type_csrrwi) ? zimm :
                         (op_type == `op_type_csrrsi) ? (csr_rd_data | zimm) :
                         (op_type == `op_type_csrrci) ? (csr_rd_data &~zimm) : 32'd0;

    integer i;
    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            for(i = 0 ; i < 4096 ; i = i + 1)
                csrs[i] = 32'd0;
        else if(csr_wr_en)
            csrs[csr_addr] <= csr_wr_data;
    end

    assign csr_rd_data = csrs[csr_addr];

    always @(posedge clk) begin
        if(csr_wr_en)
            $display("writing data %0d into CSR[%0d]", csr_wr_data, csr_addr);
    end

endmodule //csrs_csr