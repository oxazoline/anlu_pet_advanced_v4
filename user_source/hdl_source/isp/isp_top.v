module isp_top (
    input 			axi4s_video_aclk,
    input wire [1:0] I_sat_keys_n,
    output wire [6:0] O_saturation,
    output wire O_color_error,
    output wire [1:0] O_view,
    output wire [31:0] O_expression_status,
    output wire [167:0] O_expression_diagnostic,
    output wire O_patch_write,O_patch_commit,
    output wire [9:0] O_patch_address,
    output wire [7:0] O_patch_pixel,O_patch_id,
    output wire [31:0] O_face_status,
    input 			I_rst_n			,
    input 			I_tlast			,
    input 			I_tuser			,
    input [39:0] 	I_tdata			,
    input 			I_tvalid		,
    input [9:0] 	I_tdest			,
    input 			O_tready		,
    output [127:0] 	O_tdata			,
    output 			O_tlast			,
    output 			O_tuser			,
    output 			O_tvalid		,
    output 			I_tready,
    output wire [31:0] O_adv_ref,O_adv_yeah,O_adv_motion,O_adv_info,O_adv_debug,
    input wire [15:0] I_adv_frame_id,output wire [31:0] O_ae_meter
);
 
wire [95:0] cartoon_data;
wire cartoon_valid,cartoon_sof,cartoon_last;
wire [95:0] color_data;
wire cv,cs,cl;
wire [6:0] sat_target;
wire [1:0] view_target;
reg [1:0] view_active;
always @(posedge axi4s_video_aclk or negedge I_rst_n)
    if(!I_rst_n)view_active<=0;else if(cs)view_active<=view_target;
assign O_view=view_active;
wire [95:0] detail_data,tone_data;
wire dv,ds,dl,tv,ts,tl;
wire [95:0] gray_data;
wire gray_valid, gray_sof, gray_last;
wire [95:0] filtered_data;
wire filtered_valid,filtered_sof,filtered_last;
wire [95:0] denoised_data;
wire denoised_valid,denoised_sof,denoised_last;
wire         m_aixs_tvalid;  //synthesis keep 
  wire [127:0] m_aixs_tdata;  //synthesis keep 
  wire         m_aixs_tuser;  //synthesis keep 
  wire         m_aixs_tlast;  //synthesis keep 
  wire         m_aixs_tready;  //synthesis keep 
  
  wire [ 95:0] m_aixs_tdata_96;  //synthesis keep 


  wire         awb_O_tlast;  //synthesis keep 
  wire         awb_O_tuser;  //synthesis keep 
  wire [ 95:0] awb_O_tdata;  //synthesis keep 
  wire         awb_O_tvalid;  //synthesis keep 
  wire         awb_O_tready;  //synthesis keep 

  wire         awb_O_tuser_128;  //synthesis keep 
  wire         awb_O_tvalid_128;  //synthesis keep 
  wire [127:0] awb_O_tdata_128;  //synthesis keep 

  assign awb_O_tready = O_tready;
  assign O_tdata  = awb_O_tdata_128;
  assign O_tlast  = cartoon_last;
  assign O_tuser  = awb_O_tuser_128    ;
  assign O_tvalid = awb_O_tvalid_128   ;
  
  //assign m_aixs_tready = O_tready;
  //assign O_tdata  = m_aixs_tdata;
  //assign O_tlast  = m_aixs_tlast    ;
  //assign O_tuser  = m_aixs_tuser    ;
  //assign O_tvalid = m_aixs_tvalid   ;
 
 
demosaic #(
    .IMG_HEIGHT          (720 ),  // 图像高度
    .IMG_WIDTH           (1280),  // 图像宽度
    .data_complete_delay (50  ),
    .BAYER_MODE          ("BGGR")
)
u_demosaic
(
    .I_clk   			(axi4s_video_aclk)	,   // 时钟信号
    .I_rst_n 			(I_rst_n)	,   // 复位信号，低有效
    .axi4s_video_tdata 	(I_tdata)	,  // AXI4-Stream视频数据
    .axi4s_video_tdest 	(I_tdest)	,
    .axi4s_video_tlast 	(I_tlast)	,  // 行结束信号
    .axi4s_video_tvalid	(I_tvalid)	,  // 数据有效信号
    .axi4s_video_tuser 	(I_tuser)	,  // 帧开始信号
    .axi4s_video_tready	(I_tready)	,  // 从模块准备好接受数据
    .O_tlast  			(m_aixs_tlast)	,  // 输出行结束信号
    .O_tuser  			(m_aixs_tuser)	,  // 输出帧开始信号
    .O_tdata  			(m_aixs_tdata)	,  // 输出数据
    .O_tvalid 			(m_aixs_tvalid)	,  // 输出数据有效信号
    .O_tready   		(m_aixs_tready)	   // 输出数据准备好信号
);
 
data128_96 u_data128_96 (
    .I_tdata(m_aixs_tdata),
    .O_tdata(m_aixs_tdata_96)
);

awb #(
    .IMG_HEIGHT(720 ),
    .IMG_WIDTH (1280)
) u_awb (
    .I_clk   (axi4s_video_aclk),
    .I_rst_n (I_rst_n),
    .I_tlast (m_aixs_tlast),
    .I_tuser (m_aixs_tuser),
    .I_tdata (m_aixs_tdata_96),
    .I_tvalid(m_aixs_tvalid),
    .I_tready(m_aixs_tready),
    .O_tlast (awb_O_tlast ),
    .O_tuser (awb_O_tuser ),
    .O_tdata (awb_O_tdata ),
    .O_tvalid(awb_O_tvalid),
    .O_tready(awb_O_tready)
);

    adv_vision #(.V4_MODE(1),.HAND_BIAS(-441),.REF_FOREGROUND(106)) u_adv_vision(
        .I_clk(axi4s_video_aclk),.I_rst_n(I_rst_n),.I_rgb(awb_O_tdata),.I_valid(awb_O_tvalid),
        .I_sof(awb_O_tuser),.I_frame_id(I_adv_frame_id),.I_face(O_face_status),.O_ref(O_adv_ref),.O_yeah(O_adv_yeah),
        .O_motion(O_adv_motion),.O_info(O_adv_info),.O_debug(O_adv_debug),.O_meter(O_ae_meter));
    basic_gray_rgb96 u_basic_gray (
        .I_clk(axi4s_video_aclk), .I_rst_n(I_rst_n),
        .I_data(awb_O_tdata), .I_valid(awb_O_tvalid),
        .I_sof(awb_O_tuser), .I_last(awb_O_tlast),
        .O_data(gray_data), .O_valid(gray_valid), .O_sof(gray_sof), .O_last(gray_last)
    );
    basic_spatial_denoise u_spatial_denoise(
        .I_clk(axi4s_video_aclk),.I_rst_n(I_rst_n),.I_data(gray_data),
        .I_valid(gray_valid),.I_sof(gray_sof),.O_data(filtered_data),
        .O_valid(filtered_valid),.O_sof(filtered_sof),.O_last(filtered_last)
    );
    basic_vertical_denoise u_vertical_denoise(
        .I_clk(axi4s_video_aclk),.I_rst_n(I_rst_n),.I_data(filtered_data),
        .I_valid(filtered_valid),.I_sof(filtered_sof),.O_data(denoised_data),
        .O_valid(denoised_valid),.O_sof(denoised_sof),.O_last(denoised_last)
    );
    // Detector observes denoised luminance before tone, saturation and style.
    wire [31:0] raw_face;wire visual_match;
    ext_face_visual_hold u_visual_hold(axi4s_video_aclk,I_rst_n,raw_face,visual_match,O_face_status);
    ext_face_detector #(.ENABLE_HIGHLIGHT(1)) u_face_detector(
        .I_clk(axi4s_video_aclk),.I_rst_n(I_rst_n),.I_gray(denoised_data),
        .I_valid(denoised_valid),.I_sof(denoised_sof),.O_status(raw_face)
    );
    ext_expression_capture u_expression(axi4s_video_aclk,I_rst_n,denoised_data,denoised_valid,denoised_sof,O_face_status,O_expression_status,O_expression_diagnostic,O_patch_write,O_patch_address,O_patch_pixel,O_patch_commit,O_patch_id,visual_match);
    basic_detail_sharpen u_detail(
        .I_clk(axi4s_video_aclk),.I_rst_n(I_rst_n),.I_data(denoised_data),
        .I_valid(denoised_valid),.I_sof(denoised_sof),.O_data(detail_data),
        .O_valid(dv),.O_sof(ds),.O_last(dl)
    );
    basic_tone_map u_tone(
        .I_clk(axi4s_video_aclk),.I_rst_n(I_rst_n),.I_data(detail_data),
        .I_valid(dv),.I_sof(ds),.I_last(dl),.O_data(tone_data),
        .O_valid(tv),.O_sof(ts),.O_last(tl)
    );
    basic_saturation_keys #(.DEFAULT_TARGET(7'd64)) u_sat_keys(
        .I_clk(axi4s_video_aclk),.I_rst_n(I_rst_n),.I_keys_n(I_sat_keys_n),.O_target(sat_target),.O_mode(view_target)
    );
    basic_color_restore u_color(
        .I_clk(axi4s_video_aclk),.I_rst_n(I_rst_n),
        .I_color(awb_O_tdata),.I_color_valid(awb_O_tvalid),.I_color_sof(awb_O_tuser),
        .I_luma(tone_data),.I_luma_valid(tv),.I_luma_sof(ts),.I_luma_last(tl),
        .I_target(sat_target),.O_active(O_saturation),.O_data(color_data),
        .O_valid(cv),.O_sof(cs),.O_last(cl),.O_alignment_error(O_color_error)
    );
    // V3 frame-atomic view selection; enhanced color stays available.
    ext_cartoon_rgb96 u_cartoon(
        .I_clk(axi4s_video_aclk),.I_rst_n(I_rst_n),.I_data(color_data),
        .I_valid(cv),.I_sof(cs),.I_mode(view_target),
        .O_data(cartoon_data),.O_valid(cartoon_valid),
        .O_sof(cartoon_sof),.O_last(cartoon_last)
    );
    basic_rgb_packer u_data_96bit_to_128bit(
        .I_clk              ( axi4s_video_aclk  ),
        .I_rst_n            ( I_rst_n           ),
	
        .I_96b_frame_start  ( cartoon_sof           ),
        .I_96b_valid        ( cartoon_valid         ),
        .I_96b_data         ( cartoon_data          ),
	
        .O_128b_frame_start ( awb_O_tuser_128  	),
        .O_128b_valid       ( awb_O_tvalid_128 	),
        .O_128b_data        ( awb_O_tdata_128  	)
    );



//data96_128 u_data96_128 (
//    .I_tdata(awb_O_tdata),
//    .O_tdata(awb_O_tdata_128)
//);
	
endmodule
