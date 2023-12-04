// `define __DEBUG
module single_cycle_cpu (
	input           clk,
	input           rstn
);

	/*
	 * Instruction Fetch Unit
	 */
	wire            ifu_rx_valid;
	wire    [31:0]  ifu_rx_pc;
	wire            ifu_tx_ready;
	wire            bus_rsp_valid;
	wire    [31:0]  bus_rsp_data;
	wire            ifu_rx_bc_done;
	wire            ifu_rx_bc_en;

	wire            ifu_rx_ready;
	wire            ifu_tx_valid;
	wire    [31:0]  ifu_tx_pc;
	wire    [31:0]  ifu_tx_inst;
	wire            bus_req_valid;
	wire    [31:0]  bus_req_addr;

	core_ifu_top  u_core_ifu_top (
		.clk                     ( clk               ),
		.rstn                    ( rstn              ),
		.ifu_rx_valid            ( ifu_rx_valid      ),
		.ifu_rx_pc               ( ifu_rx_pc         ),
		.ifu_tx_ready            ( ifu_tx_ready      ),
		.bus_rsp_valid           ( bus_rsp_valid     ),
		.bus_rsp_data            ( bus_rsp_data      ),
		.ifu_rx_bc_done          ( ifu_rx_bc_done    ),
		.ifu_rx_bc_en            ( ifu_rx_bc_en      ),

		.ifu_rx_ready            ( ifu_rx_ready      ),
		.ifu_tx_valid            ( ifu_tx_valid      ),
		.ifu_tx_pc               ( ifu_tx_pc         ),
		.ifu_tx_inst             ( ifu_tx_inst       ),
		.bus_req_valid           ( bus_req_valid     ),
		.bus_req_addr            ( bus_req_addr      )
	);

	assign	ifu_rx_valid	=	pcr_tx_valid;
	assign	ifu_rx_pc		=	pcr_tx_pc;
	assign	ifu_rx_bc_done	=	exu_tx_bc_done;
	// assign	bus_rsp_valid	=	;
	// assign	bus_rsp_data	=	;
	assign	ifu_rx_bc_en	=	exu_tx_bc_en;
	assign	ifu_tx_ready	=	idu_rx_ready;

	/*
	 * Instruction Decode Unit
	 */
	wire	[31:0]	idu_rx_pc;
	wire	[31:0]	idu_rx_inst;
	wire			idu_rx_valid;
	wire	[31:0]	idu_rx_rs1;
	wire	[31:0]	idu_rx_rs2;
	wire			idu_tx_ready;

	wire			idu_rx_ready;
	wire			idu_dec_rs1_vld;
	wire	[4:0]	idu_dec_rs1_idx;
	wire			idu_dec_rs2_vld;
	wire	[4:0]	idu_dec_rs2_idx;
	wire			idu_dec_rd_vld;
	wire	[4:0]	idu_dec_rd_idx;
	wire			idu_tx_valid;
	wire	[31:0]	idu_tx_pc;
	wire	[6:0]	idu_tx_opcode;
	wire	[2:0]	idu_tx_func3;
	wire			idu_tx_func7;
	wire	[31:0]	idu_tx_rs1;
	wire	[31:0]	idu_tx_rs2;
	wire	[4:0]	idu_tx_rd_idx;
	wire	[5:0]	idu_tx_op_type;
	wire	[31:0]	idu_tx_imme;
	wire			idu_tx_to_exu;
	wire			idu_tx_to_lsu;

	core_idu_top  u_core_idu_top (
		.clk                     ( clk               ),
		.rstn                    ( rstn              ),
		.idu_rx_pc               ( idu_rx_pc         ),
		.idu_rx_inst             ( idu_rx_inst       ),
		.idu_rx_valid            ( idu_rx_valid      ),
		.reg_rs_ready            ( reg_rs_ready      ),
		.idu_rx_rs1              ( idu_rx_rs1        ),
		.idu_rx_rs2              ( idu_rx_rs2        ),
		.idu_tx_ready            ( idu_tx_ready      ),

		.idu_rx_ready            ( idu_rx_ready      ),
		.idu_dec_rs1_vld         ( idu_dec_rs1_vld   ),
		.idu_dec_rs1_idx         ( idu_dec_rs1_idx   ),
		.idu_dec_rs2_vld         ( idu_dec_rs2_vld   ),
		.idu_dec_rs2_idx         ( idu_dec_rs2_idx   ),
		.idu_dec_rd_vld          ( idu_dec_rd_vld    ),
		.idu_dec_rd_idx          ( idu_dec_rd_idx    ),
		.idu_tx_valid            ( idu_tx_valid      ),
		.idu_tx_pc               ( idu_tx_pc         ),
		.idu_tx_opcode           ( idu_tx_opcode     ),
		.idu_tx_func3            ( idu_tx_func3      ),
		.idu_tx_func7            ( idu_tx_func7      ),
		.idu_tx_rs1              ( idu_tx_rs1        ),
		.idu_tx_rs2              ( idu_tx_rs2        ),
		.idu_tx_rd_idx           ( idu_tx_rd_idx     ),
		.idu_tx_op_type          ( idu_tx_op_type    ),
		.idu_tx_imme             ( idu_tx_imme       ),
		.idu_tx_to_exu           ( idu_tx_to_exu     ),
		.idu_tx_to_lsu           ( idu_tx_to_lsu     )
	);

	assign	idu_rx_pc		=	ifu_tx_pc;
	assign	idu_rx_inst		=	ifu_tx_inst;
	assign	idu_rx_valid	=	ifu_tx_valid;
	assign	idu_rx_rs1		=	gpr_tx_rs1;
	assign	idu_rx_rs2		=	gpr_tx_rs2;
	assign	idu_tx_ready	=	idu_tx_to_exu	?	exu_rx_ready	:
								idu_tx_to_lsu	?	lsu_rx_ready	:	
													exu_rx_ready && lsu_rx_ready;

	wire	idu_lsu_en	=	idu_tx_opcode == `load || idu_tx_opcode == `store;
	wire	idu_exu_en	=	~idu_lsu_en;

	/*
	 * Execution Unit
	 */

	wire			exu_rx_valid;
	wire	[6:0]	exu_rx_opcode;
	wire	[31:0]	exu_rx_imme;
	wire	[31:0]	exu_rx_rs1;
	wire	[31:0]	exu_rx_rs2;
	wire	[31:0]	exu_rx_pc;
	wire	[5:0]	exu_rx_op_type;
	wire	[4:0]	exu_rx_rd_idx;
	wire			exu_tx_ready;

	wire			exu_rx_ready;
	wire			exu_tx_valid;
	wire	[31:0]	exu_tx_exu_res;
	wire			exu_tx_bc_en;
	wire			exu_tx_bc_done;
	wire	[31:0]	exu_tx_bc_pc;
	wire			exu_tx_imme_valid;
	wire			exu_tx_pc_valid;
	wire			exu_tx_pc_seq_valid;
	wire			exu_tx_csr_valid;
	wire			exu_tx_alu_valid;
	wire	[4:0]	exu_tx_rd_idx;
	wire	[31:0]	exu_tx_pc;
	wire	[31:0]	exu_tx_pc_seq;
	wire	[31:0]	exu_tx_imme;

	core_exu_top  u_core_exu_top (
		.clk                     ( clk                   ),
		.rstn                    ( rstn                  ),
		.exu_rx_valid            ( exu_rx_valid          ),
		.exu_rx_opcode           ( exu_rx_opcode         ),
		.exu_rx_imme             ( exu_rx_imme           ),
		.exu_rx_rs1              ( exu_rx_rs1            ),
		.exu_rx_rs2              ( exu_rx_rs2            ),
		.exu_rx_pc               ( exu_rx_pc             ),
		.exu_rx_op_type          ( exu_rx_op_type        ),
		.exu_rx_rd_idx           ( exu_rx_rd_idx         ),
		.exu_tx_ready            ( exu_tx_ready          ),

		.exu_rx_ready            ( exu_rx_ready          ),
		.exu_tx_valid            ( exu_tx_valid          ),
		.exu_tx_exu_res          ( exu_tx_exu_res        ),
		.exu_tx_pc               ( exu_tx_pc             ),
		.exu_tx_pc_seq           ( exu_tx_pc_seq         ),
		.exu_tx_imme             ( exu_tx_imme           ),
		.exu_tx_imme_valid       ( exu_tx_imme_valid     ),
		.exu_tx_pc_valid         ( exu_tx_pc_valid       ),
		.exu_tx_pc_seq_valid     ( exu_tx_pc_seq_valid   ),
		.exu_tx_csr_valid        ( exu_tx_csr_valid      ),
		.exu_tx_alu_valid        ( exu_tx_alu_valid      ),
		.exu_tx_rd_idx           ( exu_tx_rd_idx         ),
		.exu_tx_bc_en            ( exu_tx_bc_en          ),
		.exu_tx_bc_done          ( exu_tx_bc_done        ),
		.exu_tx_bc_pc            ( exu_tx_bc_pc          )
	);

	assign	exu_rx_valid	=	idu_tx_valid && idu_exu_en;
	assign	exu_rx_opcode	=	idu_tx_opcode;
	assign	exu_rx_imme		=	idu_tx_imme;
	assign	exu_rx_rs1		=	idu_tx_rs1;
	assign	exu_rx_rs2		=	idu_tx_rs2;
	assign	exu_rx_pc		=	idu_tx_pc;
	assign	exu_rx_op_type	=	idu_tx_op_type;
	assign	exu_rx_rd_idx	=	idu_tx_rd_idx;
	assign	exu_tx_ready	=	exu_tx_bc_en ? pcr_rx_bc_ready : gpr_rx_ready; // todo: only jal and jalr need writing both pc and gpr

	/*
	 * Load Store Unit
	 */
	wire			lsu_rx_valid;
	wire	[6:0]	lsu_rx_opcode;
	wire	[2:0]	lsu_rx_func3;
	wire	[31:0]	lsu_rx_rs1_data;
	wire	[31:0]	lsu_rx_rs2_data;
	wire	[4:0]	lsu_rx_rd_idx;
	wire	[31:0]	lsu_rx_imme;
	wire	[31:0]	lsu_bus_rdata;
	wire	[31:0]	lsu_bus_rinst;
	wire			lsu_tx_ready;

	wire			lsu_rx_ready;
	wire			lsu_bus_wen;
	wire	[2:0]	lsu_bus_rwtyp;
	wire	[31:0]	lsu_bus_addr;
	wire	[31:0]	lsu_bus_wdata;
	wire			lsu_tx_valid;
	wire	[31:0]	lsu_tx_data;
	wire	[4:0]	lsu_tx_rd_idx;

	core_lsu_top  u_core_lsu_top (
		.clk                     ( clk               ),
		.rstn                    ( rstn              ),
		.lsu_rx_valid            ( lsu_rx_valid      ),
		.lsu_rx_opcode           ( lsu_rx_opcode     ),
		.lsu_rx_func3            ( lsu_rx_func3      ),
		.lsu_rx_rs1_data         ( lsu_rx_rs1_data   ),
		.lsu_rx_rs2_data         ( lsu_rx_rs2_data   ),
		.lsu_rx_rd_idx           ( lsu_rx_rd_idx     ),
		.lsu_rx_imme             ( lsu_rx_imme       ),
		.lsu_bus_rdata           ( lsu_bus_rdata     ),
		.lsu_tx_ready            ( lsu_tx_ready      ),

		.lsu_rx_ready            ( lsu_rx_ready      ),
		.lsu_bus_wen             ( lsu_bus_wen       ),
		.lsu_bus_rwtyp           ( lsu_bus_rwtyp     ),
		.lsu_bus_addr            ( lsu_bus_addr      ),
		.lsu_bus_wdata           ( lsu_bus_wdata     ),
		.lsu_tx_valid            ( lsu_tx_valid      ),
		.lsu_tx_data             ( lsu_tx_data       ),
		.lsu_tx_rd_idx           ( lsu_tx_rd_idx     )
	);

	assign	lsu_rx_valid	=	idu_tx_valid && idu_lsu_en;
	assign	lsu_rx_opcode	=	idu_tx_opcode;
	assign	lsu_rx_func3	=	idu_tx_func3;
	assign	lsu_rx_rs1_data	=	idu_tx_rs1;
	assign	lsu_rx_rs2_data	=	idu_tx_rs2;
	assign	lsu_rx_rd_idx	=	idu_tx_rd_idx;
	assign	lsu_rx_imme		=	idu_tx_imme;
	assign	lsu_bus_rdata	=	mem_bus_rdata;
	assign	lsu_bus_rinst	=	mem_bus_rinst;
	assign	lsu_tx_ready	=	gpr_rx_ready;

	/*
	 * Program Counter
	 */
	wire			pcr_rx_bc_valid;
	wire	[31:0]	pcr_rx_bc_pc;
	wire			pcr_tx_ready;

	wire			pcr_tx_valid;
	wire	[31:0]	pcr_tx_pc;

	reg_pcr  u_reg_pcr (
		.clk                     ( clk               ),
		.rstn                    ( rstn              ),
		.pcr_rx_bc_valid         ( pcr_rx_bc_valid   ),
		.pcr_rx_bc_pc            ( pcr_rx_bc_pc      ),
		.pcr_tx_ready            ( pcr_tx_ready      ),

		.pcr_rx_bc_ready         ( pcr_rx_bc_ready   ),
		.pcr_tx_valid            ( pcr_tx_valid      ),
		.pcr_tx_pc               ( pcr_tx_pc         )
	);

	assign	pcr_rx_bc_valid	=	exu_tx_bc_en;
	assign	pcr_rx_bc_pc	=	exu_tx_bc_pc;
	assign	pcr_tx_ready	=	ifu_rx_ready;

	/*
	 * General Purpose Registor
	 */
	wire	[4:0]	gpr_rx_rs1_idx;
	wire	[4:0]	gpr_rx_rs2_idx;
	wire	[4:0]	gpr_rx_rd_idx;
	wire	[31:0]	gpr_rx_exu_res;
	wire	[31:0]	gpr_rx_pc;
	wire	[31:0]	gpr_rx_imme;
	wire	[31:0]	gpr_rx_pc_seq;
	wire	[31:0]	gpr_rx_mem;
	wire	[31:0]	gpr_rx_csr;
	wire			gpr_rx_imme_valid;
	wire			gpr_rx_pc_valid;
	wire			gpr_rx_pc_seq_valid;
	wire			gpr_rx_csr_valid;
	wire			gpr_rx_mem_valid;
	wire			gpr_rx_alu_valid;

	wire	[31:0]	gpr_tx_rs1;
	wire	[31:0]	gpr_tx_rs2;
	wire			gpr_rx_ready;

	gpr  u_gpr (
		.clk                     ( clk                   ),
		.rstn                    ( rstn                  ),
		.gpr_rx_rs1_idx          ( gpr_rx_rs1_idx        ),
		.gpr_rx_rs2_idx          ( gpr_rx_rs2_idx        ),
		.gpr_rx_rd_idx           ( gpr_rx_rd_idx         ),
		.gpr_rx_exu_res          ( gpr_rx_exu_res        ),
		.gpr_rx_pc               ( gpr_rx_pc             ),
		.gpr_rx_imme             ( gpr_rx_imme           ),
		.gpr_rx_pc_seq           ( gpr_rx_pc_seq         ),
		.gpr_rx_mem              ( gpr_rx_mem            ),
		.gpr_rx_csr              ( gpr_rx_csr            ),
		.gpr_rx_imme_valid       ( gpr_rx_imme_valid     ),
		.gpr_rx_pc_valid         ( gpr_rx_pc_valid       ),
		.gpr_rx_pc_seq_valid     ( gpr_rx_pc_seq_valid   ),
		.gpr_rx_csr_valid        ( gpr_rx_csr_valid      ),
		.gpr_rx_mem_valid        ( gpr_rx_mem_valid      ),
		.gpr_rx_alu_valid        ( gpr_rx_alu_valid      ),

		.gpr_tx_rs1              ( gpr_tx_rs1            ),
		.gpr_tx_rs2              ( gpr_tx_rs2            ),
		.gpr_rx_ready            ( gpr_rx_ready          )
	);

	assign	gpr_rx_rs1_idx		=	idu_dec_rs1_idx;
	assign	gpr_rx_rs2_idx		=	idu_dec_rs2_idx;
	assign	gpr_rx_rd_idx		=	exu_tx_valid	?	exu_tx_rd_idx	:
									lsu_tx_valid	?	lsu_tx_rd_idx	:
														'd0				;
	assign	gpr_rx_exu_res		=	exu_tx_exu_res;
	assign	gpr_rx_pc			=	exu_tx_pc;
	assign	gpr_rx_imme			=	exu_tx_imme;
	assign	gpr_rx_pc_seq		=	exu_tx_pc_seq;
	assign	gpr_rx_mem			=	lsu_tx_data;
	//todo	assign	gpr_rx_csr			=	;
	assign	gpr_rx_imme_valid	=	exu_tx_imme_valid;
	assign	gpr_rx_pc_valid		=	exu_tx_pc_valid;
	assign	gpr_rx_pc_seq_valid	=	exu_tx_pc_seq_valid;
	assign	gpr_rx_csr_valid	=	exu_tx_csr_valid;
	assign	gpr_rx_mem_valid	=	lsu_tx_valid;
	assign	gpr_rx_alu_valid	=	exu_tx_alu_valid;

	/*
	 * Score Board
	 */
	wire			scb_emit_idx_valid;
	wire			scb_emit_rs1_vld;
	wire			scb_emit_rs2_vld;
	wire			scb_emit_rd_vld;
	wire	[4:0]	scb_emit_rs1_idx;
	wire	[4:0]	scb_emit_rs2_idx;
	wire	[4:0]	scb_emit_rd_idx;
	wire	[4:0]	scb_ret_reg_idx;
	wire			scb_ret_reg_valid;

	wire			reg_rs_ready;

	core_ctrl_scb  u_core_ctrl_scb (
		.clk                     ( clk                  ),
		.rstn                    ( rstn                 ),
		.scb_emit_idx_valid      ( scb_emit_idx_valid   ),
		.scb_emit_rs1_vld        ( scb_emit_rs1_vld     ),
		.scb_emit_rs1_idx        ( scb_emit_rs1_idx     ),
		.scb_emit_rs2_vld        ( scb_emit_rs2_vld     ),
		.scb_emit_rs2_idx        ( scb_emit_rs2_idx     ),
		.scb_emit_rd_vld         ( scb_emit_rd_vld      ),
		.scb_emit_rd_idx         ( scb_emit_rd_idx      ),
		.scb_ret_reg_idx         ( scb_ret_reg_idx      ),
		.scb_ret_reg_valid       ( scb_ret_reg_valid    ),

		.reg_rs_ready            ( reg_rs_ready         )
	);

	assign	scb_emit_idx_valid	=	idu_rx_valid;
	assign	scb_emit_rs1_vld	=	idu_dec_rs1_vld;
	assign	scb_emit_rs2_vld	=	idu_dec_rs2_vld;
	assign	scb_emit_rd_vld		=	idu_dec_rd_vld;
	assign	scb_emit_rs1_idx	=	idu_dec_rs1_idx;
	assign	scb_emit_rs2_idx	=	idu_dec_rs2_idx;
	assign	scb_emit_rd_idx		=	idu_dec_rd_idx;
	assign	scb_ret_reg_idx		=	exu_tx_valid	?	exu_tx_rd_idx	:
									lsu_tx_valid	?	lsu_tx_rd_idx	:
														'd0				; // todo: what if gpr is not ready to write
	assign	scb_ret_reg_valid	=	exu_tx_valid || lsu_tx_valid;

	/*
	 * Memory Controller
	 */
	wire			mem_bus_wen;
	wire	[2:0]	mem_bus_rwtyp;
	wire	[31:0]	mem_bus_addr;
	wire	[31:0]	mem_bus_wdata;
	wire	[31:0]	mem_bus_iaddr;

	wire	[31:0]	mem_bus_rdata;
	wire	[31:0]	mem_bus_rinst;

	mem_ctrl  u_mem_ctrl (
		.clk                     ( clk             ),
		.rstn                    ( rstn            ),
		.mem_bus_wen             ( mem_bus_wen     ),
		.mem_bus_rwtyp           ( mem_bus_rwtyp   ),
		.mem_bus_addr            ( mem_bus_addr    ),
		.mem_bus_wdata           ( mem_bus_wdata   ),
		.mem_bus_iaddr           ( mem_bus_iaddr   ),

		.mem_bus_rdata           ( mem_bus_rdata   ),
		.mem_bus_rinst           ( mem_bus_rinst   )
	);

	assign	mem_bus_wen		=	lsu_bus_wen;
	assign	mem_bus_rwtyp	=	lsu_bus_rwtyp;
	assign	mem_bus_addr	=	lsu_bus_addr;
	assign	mem_bus_wdata	=	lsu_bus_wdata;

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
        reg_name[0] <= "x0";
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

	wire	[31:0]	stats_pcr_tx_pc		=	pcr_tx_valid	?	pcr_tx_pc	:	32'hx;
	wire	[31:0]	stats_ifu_tx_inst	=	ifu_tx_valid	?	ifu_tx_inst	:	32'hx;
	wire	[31:0]	stats_idu_tx_rs1	=	idu_tx_valid	?	idu_tx_rs1	:	32'hx;
	wire	[31:0]	stats_idu_tx_rs2	=	idu_tx_valid	?	idu_tx_rs2	:	32'hx;
	wire	[31:0]	stats_idu_tx_imme	=	idu_tx_valid	?	idu_tx_imme	:	32'hx;
	wire	[31:0]	stats_exu_tx_exu_res=	exu_tx_alu_valid?	exu_tx_exu_res:	32'hx;
	wire	[31:0]	stats_lsu_tx_data	=	lsu_tx_valid	?	lsu_tx_data	:	32'hx;


	always @(posedge clk) begin
		$display("|PCR|-> %h ->|IFU|-> %h ->|IDU|-> %0s %0s %h %h %h ->|EXU|-- (%0h->%0s)/LSU (%0h->%0s)", stats_pcr_tx_pc,
		stats_ifu_tx_inst, inst_str[idu_tx_op_type], reg_name[idu_tx_rd_idx], stats_idu_tx_rs1, stats_idu_tx_rs2, stats_idu_tx_imme,
		stats_exu_tx_exu_res, reg_name[exu_tx_rd_idx], stats_lsu_tx_data, reg_name[lsu_tx_rd_idx]);

		if(ifu_rx_valid && ifu_rx_ready)
			$display("IFU: [0x%h] Begin fetching pc:\t%h", ifu_rx_pc, ifu_rx_pc);
		if(idu_rx_valid && idu_rx_ready)
			$display("IDU: [0x%h] Begin decoding inst:\t%h", idu_rx_pc, idu_rx_inst);
		if(exu_rx_valid && exu_rx_ready)
			$display("EXU: [0x%h] Begin executing...\t", exu_rx_pc);
		if(lsu_rx_valid && lsu_rx_ready)
			if(lsu_rx_opcode == `load)
				$display("LSU: [0x%h] Loading mem[%h]...", idu_tx_pc, lsu_bus_addr);
			if(lsu_rx_opcode == `store)
				$display("LSU: [0x%h] Storing mem[%h]...", idu_tx_pc, lsu_bus_addr);
	end

`ifdef __VERILATOR__
	import "DPI-C" function void set_ptr_pc(input logic [31:0] pc []);
	import "DPI-C" function void set_ptr_inst(input logic [31:0] ifu_tx_inst []);
	import "DPI-C" function void call_return();

	initial begin
		set_ptr_pc(pcr_tx_pc);
		set_ptr_inst(ifu_tx_inst);
	end

	always @(posedge clk) begin
        if(ifu_tx_inst == 32'b00000000000100000000000001110011) // ebreak
            call_return();
        if(ifu_tx_inst == 32'b00000000000000000000000001110011) // ecall
            call_return();
        if(ifu_tx_inst == 32'b00000000000000001000000001100111) // return
            call_return();
    end
`endif

	// dpi_verilator  u_dpi_verilator (
	// 	.clk                     ( clk             ),
	// 	.rstn                    ( rstn            ),
	// 	.mem_inst_out            ( mem_inst_out    ),
	// 	.mem_data_addr           ( mem_data_addr   ),
	// 	.mem_data_in             ( mem_data_in     ),
	// 	.mem_data_out            ( mem_data_out    ),
	// 	.pc_out                  ( pc_out          ),
	// 	.imme                    ( imme            ),
	// 	.reg_addr_rd             ( reg_addr_rd     ),
	// 	.reg_addr_rs1            ( reg_addr_rs1    ),
	// 	.reg_data_rs1            ( reg_data_rs1    ),
	// 	.reg_addr_rs2            ( reg_addr_rs2    ),
	// 	.opcode                  ( opcode          ),
	// 	.op_type                 ( op_type         )
	// );

endmodule //single_cycle_cpu