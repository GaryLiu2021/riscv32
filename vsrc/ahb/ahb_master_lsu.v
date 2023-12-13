module ahb_lsu_master(
	input				clk,
	input				rstn,

	//	LSU INTERFACE
	input				ahbm_lsu_req_vld,
	output				ahbm_lsu_req_rdy,
	input				ahbm_lsu_req_wen,
	input		[2:0]	ahbm_lsu_req_rwtyp,
	input		[31:0]	ahbm_lsu_req_addr,
	input		[31:0]	ahbm_lsu_req_wdata,

	output				ahbm_lsu_rsp_vld,
	input				ahbm_lsu_rsp_rdy,
	output		[31:0]	ahbm_lsu_rsp_rdata,

	//	AHB INTERFACE
	output	reg	[31:0]	haddr_m2h,
	output	reg			haddr_ctrl_m2h,
	output	reg			hwrite_m2h,
	output	reg			hwdata_m2h,
	output	reg			hbusreq_m2h,

	input		[31:0]	hdata_s2m,
	input				hgrant_h2m,
	input				hresp_s2m,
	input				hready_s2m
);
	
	reg	ahb_req_rdy;	//	AHB READY

	localparam	S_IDLE	=	0,
				S_GRANT	=	1,
				S_ADDR	=	2,
				S_READ	=	3,
				S_WRITE	=	4;

	reg	[2:0]	s_pres;
	reg	[2:0]	s_next;

	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			s_pres	<=	S_IDLE;
		else
			s_pres	<=	s_next;
	end

	wire	ahbm_lsu_req_ena	=	ahbm_lsu_req_vld && ahbm_lsu_req_rdy;

	always @(*) begin
		case(s_pres)
			S_IDLE:
				s_next	=	ahbm_lsu_req_ena	?	S_ADDR	:	S_IDLE;
			S_GRANT:
				s_next	=	hgrant_h2m			?	S_ADDR	:	S_GRANT;
			S_ADDR:
				s_next	=	hwrite_m2h			?	S_WRITE	:	S_READ;
			S_WRITE:
				s_next	=	~hready_s2m			?	S_WRITE	:
							ahbm_lsu_req_ena	?	S_GRANT	:	S_WRITE;
			S_READ:
				s_next	=	~hready_s2m			?	S_READ	:
							ahbm_lsu_req_ena	?	S_GRANT	:	S_READ;
			default:
				s_next	=	S_IDLE;
		endcase
	end

	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			haddr_m2h		<=	'd0;
			haddr_ctrl_m2h	<=	'd0;
			hwrite_m2h		<=	'd0;
			hwdata_m2h		<=	'd0;
			hbusreq_m2h		<=	'd0;
			ahb_req_rdy		<=	1'b1;
		end
		else case(s_next)
			S_IDLE: begin
				haddr_ctrl_m2h	<=	'd0;
				hwrite_m2h		<=	'd0;
				hbusreq_m2h		<=	'd0;
			end
			S_GRANT: begin
				ahb_req_rdy		<=	1'b0;
				haddr_m2h		<=	{2'b00, ahbm_lsu_req_rwtyp, ahbm_lsu_req_addr[26:0]};
				hwrite_m2h		<=	ahbm_lsu_req_wen;
				hwdata_m2h		<=	ahbm_lsu_req_wdata;
				hbusreq_m2h		<=	1'b1;
			end
			S_ADDR:	begin
				haddr_ctrl_m2h	<=	1'b1;
			end
			S_WRITE: begin
				ahb_req_rdy		<=	1'b1;
			end
			S_READ: begin
				ahb_req_rdy		<=	1'b1;
			end
		endcase
	end

	assign	ahbm_lsu_rsp_vld	=	hready_s2m;
	assign	ahbm_lsu_rsp_rdata	=	hdata_s2m;
	assign	ahbm_lsu_req_rdy	=	ahbm_lsu_rsp_rdy && ahb_req_rdy;

endmodule

	