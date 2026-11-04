// V2: local-contrast reference, projection-selected hand, spatial motion support.
// Analysis never stalls the RGB96 camera stream. Grid boxes use 8-pixel units.
module adv_vision #(parameter integer V4_MODE=0,HAND_BIAS=-441,REF_FOREGROUND=106,HAND_ENTER=0,HAND_KEEP=-512,REF1_FOREGROUND=95,REF2_FOREGROUND=120)(
 input wire I_clk,I_rst_n,input wire [95:0] I_rgb,input wire I_valid,I_sof,
 input wire [31:0] I_face,output wire [31:0] O_ref,O_yeah,O_motion,
 output reg [31:0] O_info,input wire [15:0] I_frame_id,output reg [31:0] O_debug,output reg [31:0] O_meter);
 reg [8:0] col;reg [9:0] row;reg capture;
 wire [8:0] cc=I_sof?9'd0:col;wire [9:0] rr=I_sof?10'd0:row;
 // Two registered preprocessing stages break AWB->contrast->ERAM timing.
 // All arithmetic and sampling coordinates are unchanged; valid travels with data.
 wire [7:0] raw_x=cc[8:1];wire [6:0] raw_y=rr[9:3];
 wire raw_sample=I_valid && capture && cc[0] && rr[2:0]==3 && raw_x<160 && raw_y<90;
 wire [8:0] rs01={1'b0,I_rgb[95:88]}+I_rgb[71:64],rs23={1'b0,I_rgb[47:40]}+I_rgb[23:16];
 wire [9:0] rs={1'b0,rs01}+{1'b0,rs23}+10'd2;
 wire [8:0] gs01={1'b0,I_rgb[87:80]}+I_rgb[63:56],gs23={1'b0,I_rgb[39:32]}+I_rgb[15:8];
 wire [9:0] gs={1'b0,gs01}+{1'b0,gs23}+10'd2;
 wire [8:0] bs01={1'b0,I_rgb[79:72]}+I_rgb[55:48],bs23={1'b0,I_rgb[31:24]}+I_rgb[7:0];
 wire [9:0] bs={1'b0,bs01}+{1'b0,bs23}+10'd2;
 wire [9:0] ls0={2'd0,I_rgb[95:88]}+{1'd0,I_rgb[87:80],1'b0}+I_rgb[79:72];
 wire [9:0] ls1={2'd0,I_rgb[71:64]}+{1'd0,I_rgb[63:56],1'b0}+I_rgb[55:48];
 wire [9:0] ls2={2'd0,I_rgb[47:40]}+{1'd0,I_rgb[39:32],1'b0}+I_rgb[31:24];
 wire [9:0] ls3={2'd0,I_rgb[23:16]}+{1'd0,I_rgb[15:8],1'b0}+I_rgb[7:0];
 reg [31:0] face_snapshot;reg dark_scene;
 wire in_face=face_snapshot[31] && raw_x>=face_snapshot[29:22] &&
 {1'b0,raw_x}<={1'b0,face_snapshot[29:22]}+face_snapshot[14:8] && raw_y>=face_snapshot[21:15] &&
 {1'b0,raw_y}<={1'b0,face_snapshot[21:15]}+face_snapshot[14:8];
 reg va,sa,first_a,face_a;reg [7:0] xa,red,green,blue,l0,l1,l2,l3;reg [6:0] ya;
 wire [9:0] lsum={2'd0,l0}+l1+l2+l3+10'd2;wire [7:0] lum_a=lsum[9:2];
 reg [7:0] max01,max23,min01,min23;
 wire [7:0] lmax=max01>max23?max01:max23,lmin_a=min01<min23?min01:min23;
 wire [7:0] maxrg=red>green?red:green,minrg=red<green?red:green;
 wire [7:0] rgbmax=maxrg>blue?maxrg:blue,rgbmin=minrg<blue?minrg:blue;
 wire legacy_skin=red>50 && green>25 && blue>12 && {1'b0,red}>{1'b0,green}+9'd4 && {1'b0,red}>{1'b0,blue}+9'd8 && rgbmax-rgbmin>14 && !face_a;
 wire relaxed_skin=(red>28 && green>16 && blue>8 && {1'b0,red}>{1'b0,green}+({1'b0,green}>>4) && {1'b0,red}>{1'b0,blue}+({1'b0,blue}>>3) && rgbmax-rgbmin>(red>>3) && !face_a);
 wire skin_a=V4_MODE && dark_scene ? relaxed_skin : legacy_skin;
 reg [7:0] horizontal_peak;
 (* ram_style="distributed" *) reg [7:0] prev_y[0:159],prev2_y[0:159];
 wire [7:0] decay=horizontal_peak>8?horizontal_peak-8'd8:8'd0;
 wire [7:0] hp=first_a?lmax:(lmax>decay?lmax:decay);
 wire [7:0] p1=ya==0?8'd0:prev_y[xa],p2=ya<2?8'd0:prev2_y[xa];
 wire [7:0] bp=p1>p2?p1:p2,bg_a=hp>bp?hp:bp;
 reg sample,is_skin;reg [7:0] sx,lum,bg,bl0,bl1,bl2,bl3,lmin;reg [6:0] sy;
 wire [7:0] delta=bg[7:3]>12?{3'd0,bg[7:3]}:8'd12;
 wire [2:0] darks=({1'b0,bl0}+delta<bg)+{2'd0,({1'b0,bl1}+delta<bg)}+{2'd0,({1'b0,bl2}+delta<bg)}+{2'd0,({1'b0,bl3}+delta<bg)};
 wire [7:0] relative_ink_cap=(bg>>1)+(bg>>2);wire [7:0] ink_cap=relative_ink_cap<48 ? 8'd48 : relative_ink_cap;
 wire is_ink=lum<ink_cap && (darks>=2 || {1'b0,lmin}+{delta,1'b0}<bg) && sx>=3 && sx<157 && sy>=3 && sy<87;
 always @(posedge I_clk or negedge I_rst_n)begin
 if(!I_rst_n)begin va<=0;sa<=0;first_a<=0;face_a<=0;xa<=0;ya<=0;red<=0;green<=0;blue<=0;l0<=0;l1<=0;l2<=0;l3<=0;max01<=0;max23<=0;min01<=0;min23<=0;
 sample<=0;is_skin<=0;sx<=0;sy<=0;lum<=0;bg<=0;bl0<=0;bl1<=0;bl2<=0;bl3<=0;lmin<=0;horizontal_peak<=0;end
 else begin
 va<=I_valid;sa<=raw_sample;first_a<=cc==0;face_a<=in_face;xa<=raw_x;ya<=raw_y;
 red<=rs[9:2];green<=gs[9:2];blue<=bs[9:2];l0<=ls0[9:2];l1<=ls1[9:2];l2<=ls2[9:2];l3<=ls3[9:2];
 max01<=ls0[9:2]>ls1[9:2]?ls0[9:2]:ls1[9:2];max23<=ls2[9:2]>ls3[9:2]?ls2[9:2]:ls3[9:2];
 min01<=ls0[9:2]<ls1[9:2]?ls0[9:2]:ls1[9:2];min23<=ls2[9:2]<ls3[9:2]?ls2[9:2]:ls3[9:2];
 sample<=sa;is_skin<=skin_a;sx<=xa;sy<=ya;lum<=lum_a;bg<=bg_a;bl0<=l0;bl1<=l1;bl2<=l2;bl3<=l3;lmin<=lmin_a;
 if(va)horizontal_peak<=hp;
 end end
 always @(posedge I_clk)if(sa)begin prev_y[xa]<=lum_a;prev2_y[xa]<=p1;end
 (* ram_style="block" *) reg [1:0] frame_mask[0:16383];
 wire [13:0] write_address=({7'd0,sy}<<7)+({7'd0,sy}<<5)+sx;
 reg [13:0] read_address;reg [1:0] mask_q;
 always @(posedge I_clk)begin if(sample)frame_mask[write_address]<={is_skin,is_ink};mask_q<=frame_mask[read_address];end
 (* ram_style="block" *) reg [4:0] history[0:4095];
 wire motion_sample=sample && !sx[0] && !sy[0];
 wire [11:0] hist_address=({6'd0,sy[6:1]}<<6)+({6'd0,sy[6:1]}<<4)+sx[7:1];
 reg [4:0] hist_q;reg [3:0] motion_y;reg motion_valid;reg [11:0] motion_address;reg history_valid;
 wire [3:0] mdiff=hist_q[3:0]>motion_y?hist_q[3:0]-motion_y:motion_y-hist_q[3:0];
 reg [11:0] motion_read;
 wire [11:0] history_read=motion_sample?hist_address:motion_read;
 // One 4096x5 ERAM stores previous luma and the current spatial-filter flag.
 always @(posedge I_clk)begin
  hist_q<=history[history_read];
  if(motion_valid)history[motion_address]<={history_valid && mdiff>=2,motion_y};
 end
 wire [31:0] hold_ref,hold_hand,hold_motion;
 reg [19:0] meter_left,meter_right;reg [13:0] meter_clip;
 wire meter_region=sx>=16 && sx<144 && sy>=13 && sy<77;
 wire [7:0] meter_l=(meter_left+20'd2048)>>12,meter_r=(meter_right+20'd2048)>>12;
 wire [8:0] hand_centre={1'b0,hold_hand[29:22]}+{2'b0,hold_hand[14:8]};
 reg [11:0] motion_raw_count,motion_count;
 reg [7:0] mx0,mx1;reg [6:0] my0,my1;reg [3:0] kernel;reg [3:0] neighbors;
 reg centre;
 reg [7:0] previous_mean,current_mean;reg illumination_jump;
 wire [7:0] mean_diff=current_mean>previous_mean?current_mean-previous_mean:previous_mean-current_mean;
 wire [14:0] motion_area=(mx1-mx0+8'd1)*(my1-my0+7'd1);
 wire [7:0] motion_w=(mx1-mx0+8'd1)<<1;wire [6:0] motion_h=(my1-my0+7'd1)<<1;
 wire motion_ok=motion_count>=12 && motion_raw_count<2400 && !illumination_jump && ({4'd0,motion_count}<<4)>=motion_area;
 (* ram_style="distributed" *) reg [6:0] column_ink[0:159];
 (* ram_style="distributed" *) reg [7:0] row_ink[0:89];
 reg [7:0] xx,clear_index;reg [6:0] yy;reg [7:0] row_count;
 reg [7:0] ix0,ix1,hx0,hx1;reg [6:0] iy0,iy1,hy0,hy1;
 reg [13:0] skin_count,sample_count;reg [21:0] lum_total;
 reg [5:0] state;reg [2:0] pass;reg [1:0] roi;reg [31:0] ref_hint;
 wire local_roi=ref_hint[31] && roi==0;
 wire [1:0] global_roi=ref_hint[31] && roi!=0 ? roi-1'b1 : roi;
 wire [7:0] margin_x=(ref_hint[14:7]>>2)+8'd4;wire [6:0] margin_y=(ref_hint[6:0]>>2)+7'd4;
 wire [8:0] end_x={1'b0,ref_hint[29:22]}+ref_hint[14:7]+margin_x;
 wire [7:0] end_y={1'b0,ref_hint[21:15]}+ref_hint[6:0]+margin_y;
 wire [7:0] local_x0=ref_hint[29:22]>margin_x+9'd4 ? ref_hint[29:22]-margin_x : 8'd4;
 wire [6:0] local_y0=ref_hint[21:15]>margin_y+8'd3 ? ref_hint[21:15]-margin_y : 7'd3;
 wire [7:0] roi_x0=local_roi ? local_x0 : global_roi==1 ? 8'd56 : global_roi==2 ? 8'd20 : 8'd4;
 wire [7:0] roi_x1=local_roi ? (end_x>156 ? 8'd155 : end_x[7:0]-8'd1) : global_roi==2 ? 8'd139 : 8'd155;
 wire [6:0] roi_y0=local_roi ? local_y0 : global_roi==2 ? 7'd8 : 7'd3;
 wire [6:0] roi_y1=local_roi ? (end_y>87 ? 7'd86 : end_y[6:0]-7'd1) : global_roi==2 ? 7'd83 : 7'd86;
 wire region=pass<2 ? (xx>=4 && xx<96 && yy>=6 && yy<86) :
 (xx>=roi_x0 && xx<=roi_x1 && yy>=roi_y0 && yy<=roi_y1 && (pass!=4 || (yy>=iy0 && yy<=iy1)));
 wire x_region=pass==1?(xx>=hx0 && xx<=hx1):(xx>=ix0 && xx<=ix1);
 wire selected_bit=pass<2?mask_q[1]:mask_q[0];
 wire column_write=state==1 || (state==4 && !pass[0] && region && selected_bit);
 wire [7:0] column_address=state==1?clear_index:xx;
 always @(posedge I_clk)if(I_rst_n && column_write)column_ink[column_address]<=state==1?7'd0:column_ink[xx]+7'd1;
 wire axis_start=state==1 && clear_index==159;
 wire axis_valid=state==5;
 wire axis_last=pass[0]?clear_index==90:clear_index==160;
 reg [7:0] axis_min,axis_max;
 wire [7:0] rice_span_x=ix1-ix0+8'd1;wire [6:0] rice_span_y=iy1-iy0+7'd1;
 wire [7:0] axis_raw=axis_last ? 8'd0 : pass[0] ? row_ink[clear_index] : {1'b0,column_ink[clear_index]};
 wire [7:0] axis_value=axis_raw>=axis_max ? 8'd0 : axis_raw;
 wire axis_ok;wire [7:0] axis_lo,axis_hi;
 adv_axis_select axis(I_clk,I_rst_n,axis_start,axis_valid,axis_last,clear_index,axis_value,
 axis_min,pass<2 ? (pass[0] ? 8'd3 : 8'd2) : (pass[0] ? 8'd3 : 8'd12),
 pass==0 ? 8'd6 : pass==1 ? 8'd12 : pass[0] ? 8'd10 : 8'd16,axis_ok,axis_lo,axis_hi);
 reg [7:0] rw,hw;reg [6:0] rh,hh;reg [4:0] nx,ny;reg [13:0] ax,ay;
 reg [9:0] hand_fill;
 reg [9:0] ref_tp,ref_bad,ref_fg,tp1,bad1,tp2,bad2;reg signed [15:0] hand_score;
 reg [3:0] hidden_index;reg [9:0] weight_word;reg [2:0] weight_lane;
 reg signed [31:0] head_total;reg signed [23:0] head_product;
 reg [15:0] captured_id;reg [31:0] published_ref,published_hand,published_motion;reg [25:0] result_age;

 assign O_ref=result_age>=51760000?32'd0:published_ref;
 assign O_yeah=result_age>=51760000?32'd0:published_hand;
 assign O_motion=result_age>=51760000?32'd0:published_motion;
 reg [31:0] raw_ref_weak;reg ref_strong,best_full,best_weak,best_strong,win_mode;
 reg raw_done;reg [31:0] raw_ref,raw_hand,raw_motion;reg hand_keep,hand_strong,hand_candidate;
 reg [7:0] motion_events;reg motion_previous;
 wire [31:0] ref_exact,ref_support,exact1,support1,exact2,support2;adv_ref_rows ref_rom(ny,ref_exact,ref_support,exact1,support1,exact2,support2);
 wire [17:0] weight_data;wire signed [15:0] hidden_bias;wire signed [7:0] head_weight;
 wire signed [2:0] hand_weight=weight_data[17-weight_lane*3-:3];
 adv_hand_weights hand_rom(I_clk,weight_word,hidden_index,weight_data,hidden_bias,head_weight);
 adv_ref_track ref_hold(I_clk,I_rst_n,raw_done,raw_ref,raw_ref_weak,ref_strong,hold_ref);
 adv_stable_track hand_hold(I_clk,I_rst_n,raw_done,raw_hand,hand_keep,hand_strong,hold_hand);
 adv_motion_hold motion_hold(I_clk,I_rst_n,raw_done,raw_motion,hold_motion);
 wire [7:0] ref_x=ix0+ax[13:6];wire [6:0] ref_y=iy0+ay[11:5];
 wire [7:0] hand_x=hx0+ax[12:5];wire [6:0] hand_y=hy0+ay[12:6];
 reg [29:0] best_geometry;reg [7:0] best_tp;reg signed [14:0] best_quality,quality;
 reg [4:0] window_index;reg [1:0] score_bank;
 reg [9:0] selected_tp,selected_bad,full_min,weak_min,strong_min,fg_min,weak_fg_min,fg_max;
 reg [3:0] coefficient;
 reg [14:0] score_product,score_penalty;reg score_full,score_weak,score_strong;
 always @(*)begin
  case(score_bank)
  0:begin selected_tp=ref_tp;selected_bad=ref_bad;coefficient=9;full_min=REF_FOREGROUND*2/5;weak_min=REF_FOREGROUND/3;strong_min=REF_FOREGROUND*3/5;fg_min=REF_FOREGROUND/2;weak_fg_min=REF_FOREGROUND/3;fg_max=REF_FOREGROUND*2;end
  1:begin selected_tp=tp1;selected_bad=bad1;coefficient=10;full_min=REF1_FOREGROUND*2/5;weak_min=REF1_FOREGROUND/3;strong_min=REF1_FOREGROUND*3/5;fg_min=REF1_FOREGROUND/2;weak_fg_min=REF1_FOREGROUND/3;fg_max=REF1_FOREGROUND*2;end
  default:begin selected_tp=tp2;selected_bad=bad2;coefficient=8;full_min=REF2_FOREGROUND*2/5;weak_min=REF2_FOREGROUND/3;strong_min=REF2_FOREGROUND*3/5;fg_min=REF2_FOREGROUND/2;weak_fg_min=REF2_FOREGROUND/3;fg_max=REF2_FOREGROUND*2;end
  endcase
 end
 reg signed [3:0] win_dx,win_dy;
 always @(*)begin case(window_index)
 5'd0:begin win_dx=4'sd0;win_dy=4'sd0;end
 5'd1:begin win_dx=-4'sd2;win_dy=-4'sd2;end
 5'd2:begin win_dx=-4'sd1;win_dy=-4'sd2;end
 5'd3:begin win_dx=4'sd0;win_dy=-4'sd2;end
 5'd4:begin win_dx=4'sd1;win_dy=-4'sd2;end
 5'd5:begin win_dx=4'sd2;win_dy=-4'sd2;end
 5'd6:begin win_dx=-4'sd2;win_dy=-4'sd1;end
 5'd7:begin win_dx=-4'sd1;win_dy=-4'sd1;end
 5'd8:begin win_dx=4'sd0;win_dy=-4'sd1;end
 5'd9:begin win_dx=4'sd1;win_dy=-4'sd1;end
 5'd10:begin win_dx=4'sd2;win_dy=-4'sd1;end
 5'd11:begin win_dx=-4'sd2;win_dy=4'sd0;end
 5'd12:begin win_dx=-4'sd1;win_dy=4'sd0;end
 5'd13:begin win_dx=4'sd0;win_dy=4'sd0;end
 5'd14:begin win_dx=4'sd1;win_dy=4'sd0;end
 5'd15:begin win_dx=4'sd2;win_dy=4'sd0;end
 5'd16:begin win_dx=-4'sd2;win_dy=4'sd1;end
 5'd17:begin win_dx=-4'sd1;win_dy=4'sd1;end
 5'd18:begin win_dx=4'sd0;win_dy=4'sd1;end
 5'd19:begin win_dx=4'sd1;win_dy=4'sd1;end
 5'd20:begin win_dx=4'sd2;win_dy=4'sd1;end
 5'd21:begin win_dx=-4'sd2;win_dy=4'sd2;end
 5'd22:begin win_dx=-4'sd1;win_dy=4'sd2;end
 5'd23:begin win_dx=4'sd0;win_dy=4'sd2;end
 5'd24:begin win_dx=4'sd1;win_dy=4'sd2;end
 5'd25:begin win_dx=4'sd2;win_dy=4'sd2;end
 default:begin win_dx=0;win_dy=0;end endcase end
 function [7:0] clamp_ref_x;input signed [9:0] p;input [7:0] width;reg [8:0] limit;begin limit=9'd160-width;if(p<0)clamp_ref_x=0;else if(p>$signed({1'b0,limit}))clamp_ref_x=limit[7:0];else clamp_ref_x=p[7:0];end endfunction
 function [6:0] clamp_ref_y;input signed [9:0] p;input [6:0] height;reg [7:0] limit;begin limit=8'd90-height;if(p<0)clamp_ref_y=0;else if(p>$signed({2'b0,limit}))clamp_ref_y=limit[6:0];else clamp_ref_y=p[6:0];end endfunction
 wire signed [4:0] local_dx=V4_MODE ? $signed(win_dx)*2 : $signed(win_dx);
 wire signed [4:0] local_dy=V4_MODE ? $signed(win_dy)*2 : $signed(win_dy);
 wire [7:0] win_left=clamp_ref_x($signed({2'b0,ref_hint[29:22]})+local_dx,ref_hint[14:7]);
 wire [6:0] win_top=clamp_ref_y($signed({3'b0,ref_hint[21:15]})+local_dy,ref_hint[6:0]);
 always @(posedge I_clk or negedge I_rst_n)begin
 if(!I_rst_n)begin
 col<=0;row<=0;capture<=0;face_snapshot<=0;dark_scene<=1;motion_valid<=0;motion_y<=0;motion_address<=0;history_valid<=0;
 motion_raw_count<=0;motion_count<=0;meter_left<=0;meter_right<=0;meter_clip<=0;O_meter<=0;mx0<=79;mx1<=0;my0<=44;my1<=0;kernel<=0;neighbors<=0;centre<=0;motion_read<=0;
 previous_mean<=0;current_mean<=0;illumination_jump<=0;xx<=0;yy<=0;clear_index<=0;row_count<=0;
 ix0<=159;ix1<=0;iy0<=89;iy1<=0;hx0<=159;hx1<=0;hy0<=89;hy1<=0;skin_count<=0;sample_count<=0;lum_total<=0;
 state<=0;pass<=0;roi<=0;ref_hint<=0;axis_min<=3;axis_max<=255;
 raw_ref_weak<=0;ref_strong<=0;best_full<=0;best_weak<=0;best_strong<=0;win_mode<=0;best_geometry<=0;best_tp<=0;best_quality<=-15'sd16000;quality<=0;
 window_index<=0;score_bank<=0;score_product<=0;score_penalty<=0;score_full<=0;score_weak<=0;score_strong<=0;rw<=0;rh<=0;hw<=0;hh<=0;nx<=0;ny<=0;ax<=0;ay<=0;
 ref_tp<=0;ref_bad<=0;ref_fg<=0;tp1<=0;bad1<=0;tp2<=0;bad2<=0;hand_score<=HAND_BIAS;raw_done<=0;raw_ref<=0;raw_hand<=0;raw_motion<=0;
 hand_keep<=0;hand_strong<=0;hand_candidate<=0;O_info<=0;O_debug<=0;motion_events<=0;motion_previous<=0;
 captured_id<=0;published_ref<=0;published_hand<=0;published_motion<=0;result_age<=51760000;
 read_address<=0;hidden_index<=0;weight_word<=0;weight_lane<=0;head_total<=HAND_BIAS;head_product<=0;hand_fill<=0;
 end else begin
 raw_done<=0;if(result_age<51760000)result_age<=result_age+1'b1;
 motion_valid<=motion_sample;
 if(motion_sample)begin motion_y<=lum[7:4];motion_address<=hist_address;end
 if(motion_valid && history_valid && mdiff>=2)motion_raw_count<=motion_raw_count+1'b1;
 if(I_sof)begin col<=0;row<=0;capture<=state==0;if(state==0)begin captured_id<=I_frame_id;face_snapshot<=I_face;dark_scene<=current_mean<56;ref_hint<=hold_ref;sample_count<=0;lum_total<=0;motion_raw_count<=0;meter_left<=0;meter_right<=0;meter_clip<=0;end end
 if(I_valid)begin if(cc==319)begin col<=0;row<=rr==719?0:rr+1'b1;end else col<=cc+1'b1;end
 if(sample)begin
 if(meter_region)begin
  if(sx<80)meter_left<=meter_left+lum;else meter_right<=meter_right+lum;
  if(lum>=250)meter_clip<=meter_clip+1'b1;
 end
 sample_count<=sample_count+1'b1;lum_total<=lum_total+lum;
 if(sx==159 && sy==89)begin
  capture<=0;
  if(sample_count==14399)begin
   O_meter<={captured_id[7:0],meter_l,meter_r,1'b1,hold_hand[31],(hand_centre>=80),(meter_clip>=1024),(meter_clip>=256),3'd0};
   history_valid<=1;state<=1;pass<=0;clear_index<=0;skin_count<=0;head_total<=-32768;hand_fill<=0;
   previous_mean<=current_mean;current_mean<=(lum_total+lum)>>14;
   raw_ref<=0;raw_ref_weak<=0;ref_strong<=0;best_full<=0;best_weak<=0;best_strong<=0;best_quality<=-15'sd16000;best_tp<=0;win_mode<=0;window_index<=0;raw_hand<=0;raw_motion<=0;hand_keep<=0;hand_strong<=0;hand_candidate<=0;
  end else begin O_meter<=0;history_valid<=0;raw_ref<=0;raw_hand<=0;raw_motion<=0;raw_done<=1;end
 end end
 case(state)
 0:begin end
 1:begin if(clear_index==159)begin xx<=0;yy<=0;row_count<=0;
 axis_min<=pass<2 ? (pass[0] ? 8'd2 : 8'd3) : pass[0] ? ((rice_span_x>>4)<3 ? 8'd3 : rice_span_x>>4) : 8'd3;
 axis_max<=pass<2 ? 8'd255 : pass==4 ? {1'b0,rice_span_y}-(rice_span_y>>3) : pass[0] ? rice_span_x-(rice_span_x>>3) : 8'd127;
 state<=2;end else clear_index<=clear_index+1'b1;end
 2:begin read_address<=({7'd0,yy}<<7)+({7'd0,yy}<<5)+xx;state<=3;end
 3:state<=4;
 4:begin
  if(region && selected_bit && (!pass[0] || x_region))begin row_count<=row_count+1'b1;if(pass==1)skin_count<=skin_count+1'b1;end
  if(xx==159)begin row_ink[yy]<=row_count+(region && selected_bit && (!pass[0] || x_region));row_count<=0;xx<=0;
   if(yy==89)begin state<=5;clear_index<=0;end else begin yy<=yy+1'b1;state<=2;end
  end else begin xx<=xx+1'b1;state<=2;end
 end
 5:begin if(axis_last)state<=22;else clear_index<=clear_index+1'b1;end
 22:state<=23;
 23:begin
  if(axis_ok)begin case(pass)
   0:begin hx0<=axis_lo;hx1<=axis_hi;pass<=1;state<=1;clear_index<=0;end
   1:begin hy0<=axis_lo[6:0];hy1<=axis_hi[6:0];state<=11;end
   2:begin ix0<=axis_lo;ix1<=axis_hi;pass<=3;state<=1;clear_index<=0;end
   3:begin iy0<=axis_lo[6:0];iy1<=axis_hi[6:0];pass<=4;state<=1;clear_index<=0;end
   4:begin ix0<=axis_lo;ix1<=axis_hi;pass<=5;state<=1;clear_index<=0;end
   5:begin iy0<=axis_lo[6:0];iy1<=axis_hi[6:0];state<=6;end
   default:state<=32;
  endcase end
  else if(pass<2)begin roi<=0;pass<=2;state<=1;clear_index<=0;end
  else state<=32;
 end
 6:begin
  rw<=ix1-ix0+1'b1;rh<=iy1-iy0+1'b1;nx<=0;ny<=0;ax<={6'd0,ix1}-ix0+1'b1;ay<={7'd0,iy1}-iy0+1'b1;ref_tp<=0;ref_bad<=0;ref_fg<=0;tp1<=0;bad1<=0;tp2<=0;bad2<=0;
  if(ix1-ix0>=15 && iy1-iy0>=9 && ({1'b0,ix1}-ix0+1'b1)>=({2'd0,iy1}-iy0+1'b1) && ({1'b0,ix1}-ix0+1'b1)<=((({2'd0,iy1}-iy0+1'b1)<<1)+({2'd0,iy1}-iy0+1'b1)))state<=7;
  else state<=32;
 end
 7:begin read_address<=({7'd0,ref_y}<<7)+({7'd0,ref_y}<<5)+ref_x;state<=8;end
 8:state<=9;
 9:begin
  if(mask_q[0])begin ref_fg<=ref_fg+1'b1;if(ref_exact[nx])ref_tp<=ref_tp+1'b1;if(!ref_support[nx])ref_bad<=ref_bad+1'b1;if(exact1[nx])tp1<=tp1+1'b1;if(!support1[nx])bad1<=bad1+1'b1;if(exact2[nx])tp2<=tp2+1'b1;if(!support2[nx])bad2<=bad2+1'b1;end
  if(nx==31)begin nx<=0;ax<=rw;ay<=ay+({7'd0,rh}<<1);if(ny==15)state<=10;else begin ny<=ny+1'b1;state<=7;end end
  else begin nx<=nx+1'b1;ax<=ax+({6'd0,rw}<<1);state<=7;end
 end
 10:begin score_bank<=0;state<=30;end
 11:begin
  hw<=hx1-hx0+1'b1;hh<=hy1-hy0+1'b1;nx<=0;ny<=0;ax<={6'd0,hx1}-hx0+1'b1;ay<={7'd0,hy1}-hy0+1'b1;
  hidden_index<=0;weight_word<=0;weight_lane<=0;head_total<=HAND_BIAS;
  if(skin_count>=40 && ({1'b0,hx1}-hx0+1'b1)<=(({2'd0,hy1}-hy0+1'b1)<<1))begin hand_candidate<=1;state<=18;end
  else begin roi<=0;pass<=2;state<=1;clear_index<=0;end
 end
    12:begin read_address<=({7'd0,hand_y}<<7)+({7'd0,hand_y}<<5)+hand_x;state<=13;end
    13:state<=14;
    14:begin
     if(mask_q[1])begin hand_score<=hand_score+hand_weight;if(hidden_index==0)hand_fill<=hand_fill+1'b1;end
     if(weight_lane==5)begin weight_lane<=0;weight_word<=weight_word+1'b1;end else weight_lane<=weight_lane+1'b1;
     if(nx==15)begin nx<=0;ax<=hw;ay<=ay+({7'd0,hh}<<1);if(ny==31)state<=15;else begin ny<=ny+1'b1;state<=12;end end
     else begin nx<=nx+1'b1;ax<=ax+({6'd0,hw}<<1);state<=12;end
    end
    15:begin head_product<=(hand_score>0?hand_score:16'sd0)*head_weight;state<=17;end
    17:begin
     head_total<=head_total+head_product;
     if(hidden_index==11)state<=19;
     else begin hidden_index<=hidden_index+1'b1;nx<=0;ny<=0;ax<=hw;ay<=hh;state<=18;end
    end
    18:begin hand_score<=hidden_bias;state<=12;end
    19:begin raw_hand<={head_total>=HAND_ENTER && (!V4_MODE || (hand_fill>=32 && hand_fill<=480)),1'b0,hx0,hy0,hw,hh};hand_keep<=head_total>=HAND_KEEP && (!V4_MODE || (hand_fill>=32 && hand_fill<=480));hand_strong<=head_total>=1536 && (!V4_MODE || (hand_fill>=32 && hand_fill<=480));roi<=0;pass<=2;state<=1;clear_index<=0;end

 // One shared registered multiplier evaluates the three contour banks.
 30:begin
 score_product<=selected_tp*coefficient;score_penalty<=({5'd0,selected_bad}<<3)+ref_fg;
 score_full<=selected_tp>=full_min && ({2'd0,selected_bad}<<2)<=ref_fg && ref_fg>=fg_min && ref_fg<=fg_max;
 score_weak<=local_roi && selected_tp>=weak_min && ({2'd0,selected_bad}<<2)<={2'd0,ref_fg}+({2'd0,ref_fg}>>2) && ref_fg>=weak_fg_min && ref_fg<=fg_max;
 score_strong<=selected_tp>=strong_min && ({3'd0,selected_bad}<<3)<=ref_fg;
 state<=31;
 end
 31:begin quality<=$signed(score_product)-$signed(score_penalty);state<=34;end
 34:begin
 if(score_full && quality>=160)begin
  if(!best_full || quality>best_quality)begin best_geometry<={ix0,iy0,rw,rh};best_quality<=quality;best_tp<=selected_tp[7:0];best_strong<=score_strong && quality>=360;end
  best_full<=1;
 end else if(score_weak && quality>=96 && !best_full)begin
  if(!best_weak || quality>best_quality)begin best_geometry<={ix0,iy0,rw,rh};best_quality<=quality;best_tp<=selected_tp[7:0];end
  best_weak<=1;
 end
 if(score_bank==2)state<=32;else begin score_bank<=score_bank+1'b1;state<=30;end
 end
 32:begin
 if(local_roi)begin
  if(!win_mode)begin win_mode<=1;window_index<=0;state<=33;end
  else if(window_index<25)begin window_index<=window_index+1'b1;state<=33;end
  else if(best_full)state<=35;
  else begin roi<=1;win_mode<=0;pass<=2;clear_index<=0;state<=1;end
 end else if(best_full || roi==(ref_hint[31] ? 2'd3 : 2'd2))state<=35;
 else begin roi<=roi+1'b1;pass<=2;clear_index<=0;state<=1;end
 end
 33:begin ix0<=win_left;iy0<=win_top;state<=37;end
 37:begin ix1<=ix0+ref_hint[14:7]-8'd1;iy1<=iy0+ref_hint[6:0]-7'd1;state<=6;end
 35:begin
 raw_ref<={best_full,1'b0,best_geometry};raw_ref_weak<={best_weak && !best_full,1'b1,best_geometry};ref_strong<=best_full && best_strong;
 if(V4_MODE && best_full && hx0<({1'b0,best_geometry[29:22]}+best_geometry[14:7]) && hx1>=best_geometry[29:22] && hy0<({1'b0,best_geometry[21:15]}+best_geometry[6:0]) && hy1>=best_geometry[21:15])begin raw_hand<=0;hand_keep<=0;hand_strong<=0;end
 state<=24;
 end
 24:begin xx<=1;yy<=1;kernel<=0;neighbors<=0;centre<=0;motion_count<=0;mx0<=79;mx1<=0;my0<=44;my1<=0;illumination_jump<=mean_diff>10;state<=25;end
 25:begin
 case(kernel)
 0:motion_read<=((yy-1)*80)+xx-1;1:motion_read<=((yy-1)*80)+xx;2:motion_read<=((yy-1)*80)+xx+1;
 3:motion_read<=yy*80+xx-1;4:motion_read<=yy*80+xx;5:motion_read<=yy*80+xx+1;
 6:motion_read<=((yy+1)*80)+xx-1;7:motion_read<=((yy+1)*80)+xx;8:motion_read<=((yy+1)*80)+xx+1;
 endcase state<=29;
 end
 29:state<=26;
 26:begin
  neighbors<=neighbors+hist_q[4];if(kernel==4)centre<=hist_q[4];
  if(kernel==8)state<=27;else begin kernel<=kernel+1'b1;state<=25;end
 end
 27:begin
  if(centre && neighbors>=3)begin motion_count<=motion_count+1'b1;if(xx<mx0)mx0<=xx;if(xx>mx1)mx1<=xx;if(yy<my0)my0<=yy;if(yy>my1)my1<=yy;end
  kernel<=0;neighbors<=0;centre<=0;
  if(xx==78)begin xx<=1;if(yy==43)state<=28;else begin yy<=yy+1'b1;state<=25;end end else begin xx<=xx+1'b1;state<=25;end
 end
 28:begin
 raw_motion<={motion_ok,1'b0,mx0[6:0],1'b0,my0[5:0],1'b0,motion_w,motion_h};
 if(motion_ok && !motion_previous)motion_events<=motion_events+1'b1;motion_previous<=motion_ok;state<=16;
 end
 16:begin raw_done<=1;state<=20;end
 20:state<=21;
 21:begin
 O_info<={captured_id,best_tp,motion_events};published_ref<=hold_ref;published_hand<=hold_hand;published_motion<=hold_motion;
 O_debug<={head_total[15:0],best_tp,hand_candidate,raw_hand[31],hold_hand[31],raw_ref[31],hold_ref[31],raw_motion[31],hold_motion[31],1'b0};
 result_age<=0;state<=0;
 end
 default:state<=0;
 endcase
 end end
endmodule
