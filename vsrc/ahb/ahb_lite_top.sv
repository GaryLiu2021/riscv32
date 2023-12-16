`include "const_defines.v"

module ahb_lite_top (

// GLOBAL
	input                               clk,
	input                               rstn,

// LSU TO MASTER
	input								ahbm_lsu_req_vld,
	input								ahbm_lsu_req_wen,
	input	[2:0]						ahbm_lsu_req_rwtyp,
	input	[31:0]						ahbm_lsu_req_addr,
	input	[31:0]						ahbm_lsu_req_wdata,
	input								ahbm_lsu_rsp_rdy,

// MASTER TO LSU
	output								ahbm_lsu_req_rdy,  
	output								ahbm_lsu_rsp_vld,  
	output	[31:0]						ahbm_lsu_rsp_rdata,

// UART IO
	input                               rx_pin,
	output                              tx_pin
);

// MASTER TO AHB
	wire [`AHB_ADDR_WIDTH - 1:0]        haddr_m2h;
	wire                                haddr_ctrl_m2h;
	wire                                hwrite_m2h;
	wire [`AHB_DATA_WIDTH - 1:0]        hwdata_m2h;
	wire                                hbusreq_m2h;

// UART(SLAVE0) TO AHB
	wire                                hready_u2h;
	wire                                hresp_u2h;
	wire [`AHB_DATA_WIDTH - 1:0]        hrdata_u2h;
	
// RAM(SLAVE1) TO AHB
	wire                                hready_r2h;
	wire                                hresp_r2h;
	wire [`AHB_DATA_WIDTH - 1:0]        hrdata_r2h;

// AHB TO MASTER
	wire [`AHB_DATA_WIDTH - 1:0]        hdata_s2m;
	wire                                hgrant_h2m;
	wire                                hresp_s2m;
	wire                                hready_s2m;

// AHB TO SLAVE
	wire [`AHB_DATA_WIDTH - 1:0]        hwdata_m2s;
	wire [`AHB_ADDR_WIDTH - 1:0]        haddr_m2s;
	wire                                hwrite_m2s;
	wire                                hsel_u; 
	wire                                hsel_r; 


// internal signals
	wire [`AHB_DATA_WIDTH - 1:0]    rd_mux_in1;
	wire [`AHB_DATA_WIDTH - 1:0]    rd_mux_in2;
	wire [`AHB_DATA_WIDTH - 1:0]    rd_mux_out;

	wire [1:0]                      rsp_mux_in1;
	wire [1:0]                      rsp_mux_in2;
	wire [1:0]                      rsp_mux_out;

	wire [`AHB_ADDR_WIDTH - 1:0]    haddr;
	wire                            haddr_ctrl;
	wire                            hwrite;

	wire [`AHB_DATA_WIDTH - 1:0]    hwdata;
	wire [`AHB_DATA_WIDTH - 1:0]    hrdata;

	wire                            hready;
	wire                            hresp;

	assign haddr =                  haddr_m2h; 
	assign hwrite =                 hwrite_m2h;
	assign haddr_ctrl =             haddr_ctrl_m2h;
	assign hwdata =                 hwdata_m2h;

	assign rd_mux_in1 =             hrdata_u2h;
	assign rd_mux_in2 =             hrdata_r2h;
	assign hrdata =                 rd_mux_out;

	assign rsp_mux_in1 =            {hresp_u2h, hready_u2h};
	assign rsp_mux_in2 =            {hresp_r2h, hready_r2h};
	assign hresp =                  rsp_mux_out[1];
	assign hready =                 rsp_mux_out[0];

	// Instantiate the ahb module
	ahb_lite ahb_fabric (
		.clk            ( clk           ),
		.rstn           ( rstn          ),
		.haddr          ( haddr         ),
		.haddr_ctrl     ( haddr_ctrl    ),
		.hwrite         ( hwrite        ),
		.hwdata         ( hwdata        ),
		.hbusreq        ( hbusreq_m2h   ),
		.hready         ( hready        ),
		.hresp          ( hresp         ),
		.hrdata         ( hrdata        ),
		.hdata_s2m      ( hdata_s2m     ),
		.hgrant         ( hgrant_h2m    ),
		.hresp_s2m      ( hresp_s2m     ),
		.hready_s2m     ( hready_s2m    ),
		.hwdata_m2s     ( hwdata_m2s    ),
		.haddr_m2s      ( haddr_m2s     ),
		.hwrite_m2s     ( hwrite_m2s    ),
		.hsel_0         ( hsel_u        ),
		.hsel_1         ( hsel_r        )
	);

	ahb_mux #(
		.WIDTH          ( `AHB_DATA_WIDTH   )
	) read_data_mux (
		.in_1           ( rd_mux_in1        ),
		.in_2           ( rd_mux_in2        ),
		.sel            ( hsel_u          ),
		.out            ( rd_mux_out        )
	);

	ahb_mux #(
		.WIDTH          ( 2                 )
	) resp_mux (
		.in_1           ( rsp_mux_in1       ),
		.in_2           ( rsp_mux_in2       ),
		.sel            ( hsel_u          ),
		.out            ( rsp_mux_out       )
	);

	// master master0 (
	//     .clk(clk),
	//     .rstn(rstn),
	//     .haddr_i(haddr_i),
	//     .haddr_ctrl_i(haddr_ctrl_i),
	//     .hwrite_i(hwrite_i),
	//     .hwdata_i(hwdata_i),
	//     .hbusreq_i(hbusreq_i),
	//     .hdata_s2m(hdata_s2m),
	//     .hgrant(hgrant_h2m),
	//     .hresp_s2m(hresp_s2m),
	//     .hready_s2m(hready_s2m),
	//     .haddr(haddr_m2h),
	//     .haddr_ctrl(haddr_ctrl_m2h),
	//     .hwrite(hwrite_m2h),
	//     .hwdata(hwdata_m2h),
	//     .hbusreq(hbusreq_m2h)
	// );

	ahb_lsu_master  u_ahb_lsu_master (
		.clk					 ( clk ),
		.rstn					 ( rstn ),
		.ahbm_lsu_req_vld        ( ahbm_lsu_req_vld     ),
		.ahbm_lsu_req_wen        ( ahbm_lsu_req_wen     ),
		.ahbm_lsu_req_rwtyp      ( ahbm_lsu_req_rwtyp   ),
		.ahbm_lsu_req_addr       ( ahbm_lsu_req_addr    ),
		.ahbm_lsu_req_wdata      ( ahbm_lsu_req_wdata   ),
		.ahbm_lsu_rsp_rdy        ( ahbm_lsu_rsp_rdy     ),
		.hdata_s2m               ( hdata_s2m            ),
		.hgrant_h2m              ( hgrant_h2m           ),
		.hresp_s2m               ( hresp_s2m            ),
		.hready_s2m              ( hready_s2m           ),

		.ahbm_lsu_req_rdy        ( ahbm_lsu_req_rdy     ),
		.ahbm_lsu_rsp_vld        ( ahbm_lsu_rsp_vld     ),
		.ahbm_lsu_rsp_rdata      ( ahbm_lsu_rsp_rdata   ),
		.haddr_m2h               ( haddr_m2h            ),
		.haddr_ctrl_m2h          ( haddr_ctrl_m2h       ),
		.hwrite_m2h              ( hwrite_m2h           ),
		.hwdata_m2h              ( hwdata_m2h           ),
		.hbusreq_m2h             ( hbusreq_m2h          )
	);

	uart_top slave_uart (
		.clk        (clk),
		.rstn       (rstn),
		.hwdata     (hwdata_m2s),
		.haddr      (haddr_m2s),
		.hwrite     (hwrite_m2s),
		.hsel       (hsel_u),
		.hready     (hready_u2h),
		.hresp      (hresp_u2h),
		.hrdata     (hrdata_u2h),
		.rx_pin     (rx_pin),
		.tx_pin     (tx_pin)
	);

	ram_top slave_ram (
		.clk        (clk),
		.rstn       (rstn),
		.haddr      (haddr_m2s),
		.hwdata     (hwdata_m2s),
		.hwrite     (hwrite_m2s),
		.hsel       (hsel_r),
		.hready     (hready_r2h),
		.hresp      (hresp_r2h),
		.hrdata     (hrdata_r2h)
	);

endmodule