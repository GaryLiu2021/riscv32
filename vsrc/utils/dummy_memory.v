module mem_ctrl (
    input               clk,
    input               rstn,
    input               mem_bus_wen,
    input       [2:0]   mem_bus_rwtyp,

    input       [31:0]  mem_bus_addr,
    input       [31:0]  mem_bus_wdata,
    output      [31:0]  mem_bus_rdata,

    input       [31:0]  mem_bus_iaddr,
    output      [31:0]  mem_bus_rinst
);

    reg [31:0] mem [(1<<17)-1:0]; // 0x80000000 -> 0x8001ffff

    initial begin
        // set_ptr_mem(mem);
        // $readmemb("/home/sgap/ysyx-workbench/npc/vsrc/mem.init", mem);
    end
    
    wire    [31:0] rd_data;
    reg     [31:0] wr_data_byte;
    wire    [31:0] wr_data_half_word;
    wire    [31:0] wr_data;

    assign rd_data = mem[mem_bus_addr[31:2]];

    always @(*) begin
        case(mem_bus_addr[1:0])
            2'b00:  wr_data_byte = {rd_data[31:8], mem_bus_wdata[7:0]};
            2'b01:  wr_data_byte = {rd_data[31:16], mem_bus_wdata[7:0], rd_data[7:0]};
            2'b10:  wr_data_byte = {rd_data[31:24], mem_bus_wdata[7:0], rd_data[15:0]};
            2'b11:  wr_data_byte = {mem_bus_wdata[7:0], rd_data[23:0]};
        endcase
    end

    assign wr_data_half_word = (mem_bus_addr[1]) ? {mem_bus_wdata[15:0], rd_data[15:0]} : {rd_data[31:16], mem_bus_wdata[15:0]};

    assign wr_data = (mem_bus_rwtyp[1:0] == 2'b00) ? wr_data_byte :
                     (mem_bus_rwtyp[1:0] == 2'b01) ? wr_data_half_word :
                     mem_bus_wdata;

    always @(posedge clk) begin
        if(mem_bus_wen)
            mem[mem_bus_addr[31:2]] <= wr_data;
    end

    reg     [7:0] rd_data_byte;
    wire    [15:0] rd_data_half_word;

    // extended read data
    wire    [31:0] rd_data_byte_ext;
    wire    [31:0] rd_data_half_word_ext;

    always @(*) begin
        case(mem_bus_addr[1:0])
            2'b00:  rd_data_byte = rd_data[7:0];
            2'b01:  rd_data_byte = rd_data[15:8];
            2'b10:  rd_data_byte = rd_data[23:16];
            2'b11:  rd_data_byte = rd_data[31:24];
        endcase
    end

    assign rd_data_half_word = (mem_bus_addr[1]) ? rd_data[31:16] : rd_data[15:0];

    assign rd_data_byte_ext = (mem_bus_rwtyp[2]) ? {24'd0, rd_data_byte} : {{24{rd_data_byte[7]}}, rd_data_byte};
    assign rd_data_half_word_ext = (mem_bus_rwtyp[2]) ? {16'd0, rd_data_half_word} : {{16{rd_data_half_word[15]}}, rd_data_half_word};

    assign mem_bus_rdata = (mem_bus_rwtyp[1:0] == 2'b00) ? rd_data_byte_ext :
                          (mem_bus_rwtyp[1:0] == 2'b01) ? rd_data_half_word_ext :
                          rd_data;

    assign mem_bus_rinst = mem[mem_bus_iaddr[31:2]];

    always @(posedge clk) begin
        if(rstn)
            if(mem_bus_wen)
                $display("MEM: Writing %h to %h", wr_data, mem_bus_addr);
    end

endmodule //mem_ctrl