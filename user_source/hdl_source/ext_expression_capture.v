// V16: native48/native32 expression input; the 32px preview is unchanged.
// Legal profile/coasting ROIs may be classified. Detection support, never
// expression results, bounds coasting; a changed owner invalidates old results.
module ext_expression_capture #(parameter integer ENABLE_AU=1, ENABLE_CONFUSED=1, BALANCED_POLICY=1, COMPACT_DEBUG=BALANCED_POLICY, V22_POLICY=BALANCED_POLICY, ENABLE_CBROW=BALANCED_POLICY, CONFUSED_GUARD=1)(input wire I_clk,I_rst_n,input wire [95:0] I_gray,
 input wire I_valid,I_sof,input wire [31:0] I_face,output wire [31:0] O_status,
 output reg [167:0] O_diagnostic,
 output wire O_patch_write,output wire [9:0] O_patch_address,
 output wire [7:0] O_patch_pixel,output wire O_patch_commit,output wire [7:0] O_patch_id,output wire O_visual);
 wire balanced=ENABLE_AU && BALANCED_POLICY;
 reg [2:0] neutral_votes;
 wire neutral_exit=(neutral_votes[2] && neutral_votes[1]) || (neutral_votes[2] && neutral_votes[0]) || (neutral_votes[1] && neutral_votes[0]);
 localparam integer FAST_HAPPY_MARGIN=V22_POLICY?2188:2304, FAST_HAPPY_MARGIN_LOW=V22_POLICY?2432:2560;
 reg [8:0] col;reg [9:0] row;wire [8:0] cc=I_sof?0:col;wire [9:0] rr=I_sof?0:row;
 reg [31:0] patch_face;reg capture,start,low_res;reg [5:0] sx,sy;
 reg [10:0] left,top;reg [9:0] x_offset,y_offset;
 reg [3:0] x_rem,y_rem,initial_rem,step_rem;reg [4:0] initial_quot,step_quot;
 reg [4:0] preview_x,preview_y;reg [1:0] x_mod,y_mod;
 reg [7:0] previous_gray;reg [5:0] upper_count;
 (* ram_style="dram" *) reg [8:0] upper[0:47];
 reg [7:0] darkest,brightest,contrast,last_contrast,patch_counter,active_id,result_id;
 localparam [3:0] COAST_FRAMES=10;
 reg pending_gap;reg [1:0] label,pending,pending_count,rejected_count;reg [3:0] stale,coast_age;
 reg diagnostic_valid,result_allowed,coast_supported;
 wire busy,done;wire [1:0] result;wire [167:0] core_diagnostic;
 function [3:0] div12;input [6:0] w;begin
  if(w>=120)div12=10;else if(w>=108)div12=9;else if(w>=96)div12=8;else if(w>=84)div12=7;
  else if(w>=72)div12=6;else if(w>=60)div12=5;else if(w>=48)div12=4;else if(w>=36)div12=3;
  else if(w>=24)div12=2;else if(w>=12)div12=1;else div12=0;
 end endfunction
 wire small_face=I_face[14:8]<24;wire [6:0] face_width=I_face[14:8];
 wire [3:0] q12=div12(face_width);
 wire [6:0] r12=face_width-({3'd0,q12}<<3)-({3'd0,q12}<<2);
 wire [4:0] init_q=small_face?{1'b0,face_width[6:3]}:{1'b0,q12};
 wire [3:0] init_r=small_face?{1'b0,face_width[2:0]}:r12[3:0];
 wire [4:0] step_q=small_face?face_width[6:2]:({q12,1'b0}+(r12>=6));
 wire [3:0] step_r=small_face?{1'b0,face_width[1:0],1'b0}:((r12>=6?r12-7'd6:r12)<<1);
 wire [10:0] face_left={I_face[29:22],3'b0},face_top={I_face[21:15],3'b0};
 wire [10:0] last_offset={1'b0,face_width,3'b0}-init_q-(init_r!=0);
 wire fits=({2'd0,face_left}+last_offset<1280) && ({2'd0,face_top}+last_offset<720);
 wire hard_valid=I_face[31] && face_width>=16 && fits;
 // Nonzero support is tracker evidence state, not a per-detection done pulse.
 // The tracker also enforces its independent absolute lifetime.
 wire detector_supported=hard_valid && I_face[6:0]!=0;
 wire visual_supported=hard_valid && I_face[30];
 wire eligible=hard_valid && (detector_supported || visual_supported || (coast_supported && coast_age<COAST_FRAMES));
 function [8:0] distance;input [8:0] a,b;begin distance=a>b?a-b:b-a;end endfunction
 wire [8:0] face_cx={1'b0,I_face[29:22]}+{3'd0,I_face[14:9]},face_cy={2'd0,I_face[21:15]}+{3'd0,I_face[14:9]};
 wire [8:0] patch_cx={1'b0,patch_face[29:22]}+{3'd0,patch_face[14:9]},patch_cy={2'd0,patch_face[21:15]}+{3'd0,patch_face[14:9]};
 wire roi_consistent=distance(face_cx,patch_cx)<=({2'd0,patch_face[14:8]}>>2)+2 &&
   distance(face_cy,patch_cy)<=({2'd0,patch_face[14:8]}>>2)+2 &&
   distance({2'd0,face_width},{2'd0,patch_face[14:8]})<=({2'd0,patch_face[14:8]}>>2)+2;
 wire [5:0] last_sample=low_res?6'd31:6'd47;
 wire [10:0] target_x=left+x_offset,target_y=top+y_offset;
 wire hit=I_valid && !I_sof && capture && {cc,2'b0}<=target_x && {cc,2'b0}+3>=target_x;
 wire upper_selected=hit && rr+11'd1==target_y;
 wire selected=hit && rr==target_y && upper_count==(low_res?32:48);
 reg [8:0] horizontal;
 always @(*)case(target_x[1:0])
  0:horizontal={1'b0,previous_gray}+{1'b0,I_gray[95:88]};
  1:horizontal={1'b0,I_gray[95:88]}+{1'b0,I_gray[71:64]};
  2:horizontal={1'b0,I_gray[71:64]}+{1'b0,I_gray[47:40]};
  default:horizontal={1'b0,I_gray[47:40]}+{1'b0,I_gray[23:16]};
 endcase
 wire [10:0] sum4={2'd0,upper[sx]}+{2'd0,horizontal}+11'd2;
 wire [7:0] pixel=sum4[9:2];
 always @(posedge I_clk)if(upper_selected)upper[sx]<=horizontal;
 // Separate 2x2 sample arithmetic from min/max and contrast reduction.
 reg [7:0] contrast_pixel;reg [5:0] contrast_x,contrast_y;reg contrast_valid,contrast_last;
 wire [7:0] new_min=contrast_pixel<darkest?contrast_pixel:darkest;
 wire [7:0] new_max=contrast_pixel>brightest?contrast_pixel:brightest;
 wire [11:0] core_address=low_res?{2'd0,sy[4:0],sx[4:0]}:(({6'd0,sy}<<5)+({6'd0,sy}<<4)+sx);
 ext_expression_core #(.ENABLE_AU(ENABLE_AU),.ENABLE_CUE(ENABLE_AU),.ENABLE_MOUTH(ENABLE_AU && ENABLE_CONFUSED),.BALANCED_POLICY(BALANCED_POLICY && ENABLE_AU),.FULL_SCORE_DEBUG(!COMPACT_DEBUG),.V22_POLICY(V22_POLICY && ENABLE_AU),.ENABLE_CBROW(ENABLE_CBROW && ENABLE_CONFUSED && ENABLE_AU),.CONFUSED_GUARD(CONFUSED_GUARD && ENABLE_CONFUSED)) core(I_clk,I_rst_n,start,selected,core_address,pixel,contrast,busy,done,result,core_diagnostic,low_res);
 ext_expression_motion motion(I_clk,I_rst_n,(I_sof && eligible && !busy && !start),
 (contrast_valid && !I_sof),(contrast_valid && contrast_last && eligible && roi_consistent && !I_sof),
 (detector_supported && !I_face[7] && I_face[6:0]>=5),(ENABLE_AU?O_diagnostic[128]:O_diagnostic[166]),
 contrast_x,contrast_y,contrast_pixel,low_res,I_face,O_visual);
 wire status_valid=diagnostic_valid && eligible && roi_consistent;
 wire debounce_pending=status_valid && pending!=0;
 // ROI ownership and validity mask label, VALID and RS in the same cycle.
 // RS F is owner mismatch; RS A is expired/unsupported coast; P is no rejection.
 wire [3:0] reason=!I_face[31]?4'd8:(face_width<16?4'd11:(!fits?4'd13:
      (!roi_consistent?4'd15:(!eligible?4'd10:(!diagnostic_valid?4'd12:
      (debounce_pending?4'd14:O_diagnostic[163:160]))))));
 // [6]=eligible, [5]=current ROI owns patch, [4]=detector profile/uncertain pose.
 // Bit11 is the C display tag; rotation remains in diagnostic[166].
 wire combo_active;
 wire fresh_result=done && eligible && result_allowed && roi_consistent;
 wire guarded_pose_ok=!CONFUSED_GUARD || !I_face[7] || core_diagnostic[155];
 wire combo_candidate=core_diagnostic[135] && guarded_pose_ok;
 wire combo_reset=!eligible || !roi_consistent || stale>=12 || (CONFUSED_GUARD && fresh_result && (!core_diagnostic[132] || !guarded_pose_ok)) ||
  (balanced && fresh_result && (!core_diagnostic[167] || core_diagnostic[163:160]==1 || !core_diagnostic[129]));
 ext_expression_confused_overlay #(.BALANCED_POLICY(BALANCED_POLICY && ENABLE_AU),.STRICT_ENTRY(ENABLE_CBROW)) combo(I_clk,I_rst_n,combo_reset,fresh_result,
  combo_candidate,result,combo_active);
 wire show_confused=ENABLE_AU && ENABLE_CONFUSED && combo_active && (balanced || label==3) && status_valid && (!CONFUSED_GUARD || (O_diagnostic[132] && (!I_face[7] || O_diagnostic[155])));
 wire [1:0] shown_label=show_confused?2'd0:((eligible && roi_consistent)?label:2'd0);
 wire [3:0] shown_reason=(balanced && show_confused)?4'd0:reason;
 assign O_status={result_id,last_contrast,shown_reason,show_confused,O_diagnostic[165:164],status_valid,(debounce_pending && !(balanced && show_confused)),
      eligible,(hard_valid && roi_consistent),I_face[7],busy,capture,shown_label};
 wire keep_x=low_res || x_mod!=1,keep_y=low_res || y_mod!=1;
 assign O_patch_write=selected && eligible && roi_consistent && keep_x && keep_y;
 assign O_patch_address={preview_y,preview_x};assign O_patch_pixel=pixel;
 assign O_patch_commit=done && eligible && result_allowed && roi_consistent;assign O_patch_id=active_id;
 wire [4:0] x_sum={1'b0,x_rem}+{1'b0,step_rem},y_sum={1'b0,y_rem}+{1'b0,step_rem};
 wire [4:0] divisor=low_res?5'd8:5'd12;
 wire [9:0] next_x=x_offset+step_quot+(x_sum>=divisor),next_y=y_offset+step_quot+(y_sum>=divisor);
 always @(posedge I_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin
   neutral_votes<=0;patch_face<=0;col<=0;row<=0;capture<=0;start<=0;low_res<=0;sx<=0;sy<=0;left<=0;top<=0;
   x_offset<=0;y_offset<=0;x_rem<=0;y_rem<=0;initial_rem<=0;step_rem<=0;initial_quot<=0;step_quot<=0;
   preview_x<=0;preview_y<=0;x_mod<=0;y_mod<=0;
   darkest<=255;brightest<=0;contrast<=0;last_contrast<=0;label<=0;pending<=0;pending_count<=0;pending_gap<=0;rejected_count<=0;stale<=0;
   previous_gray<=0;upper_count<=0;O_diagnostic<=0;diagnostic_valid<=0;patch_counter<=0;active_id<=0;result_id<=0;result_allowed<=0;
   coast_age<=COAST_FRAMES;coast_supported<=0;contrast_pixel<=0;contrast_x<=0;contrast_y<=0;contrast_valid<=0;contrast_last<=0;
  end else begin
   start<=0;
   contrast_valid<=selected && eligible && roi_consistent && !I_sof;
   contrast_last<=selected && sx==last_sample && sy==last_sample;
   if(selected)begin contrast_pixel<=pixel;contrast_x<=sx;contrast_y<=sy;end
   if(contrast_valid && !I_sof && eligible && roi_consistent)begin
    darkest<=new_min;brightest<=new_max;
    if(contrast_last)begin
     contrast<=new_max-new_min;start<=1;result_allowed<=1;
     active_id<=patch_counter;patch_counter<=patch_counter+1'b1;
    end
   end
   if(I_sof)begin
    col<=0;row<=0;capture<=eligible && !busy && !start;
    if(eligible && !busy && !start)begin
     patch_face<=I_face;low_res<=small_face;sx<=0;sy<=0;left<=face_left;top<=face_top;
     x_offset<=init_q;y_offset<=init_q;x_rem<=init_r;y_rem<=init_r;initial_quot<=init_q;initial_rem<=init_r;step_quot<=step_q;step_rem<=step_r;
     upper_count<=0;darkest<=255;brightest<=0;preview_x<=0;preview_y<=0;x_mod<=0;y_mod<=0;
    end
    if(stale>=12)begin label<=0;pending<=0;pending_count<=0;pending_gap<=0;rejected_count<=0;diagnostic_valid<=0;end else stale<=stale+1'b1;
   end
   if(I_valid)begin previous_gray<=I_gray[23:16];if(cc==319)begin col<=0;row<=rr==719?0:rr+1'b1;end else col<=cc+1'b1;end
   if(upper_selected)begin
    upper_count<=upper_count+1'b1;
    if(sx==last_sample)begin sx<=0;x_offset<=initial_quot;x_rem<=initial_rem;end
    else begin sx<=sx+1'b1;x_offset<=next_x;x_rem<=x_sum>=divisor?x_sum-divisor:x_sum;end
   end
   if(selected)begin
    if(O_patch_write)preview_x<=preview_x+1'b1;
    x_mod<=x_mod==2?0:x_mod+1'b1;
    if(sx==last_sample)begin
     sx<=0;x_offset<=initial_quot;x_rem<=initial_rem;upper_count<=0;x_mod<=0;
     if(keep_y)begin preview_x<=0;preview_y<=preview_y+1'b1;end
     y_mod<=y_mod==2?0:y_mod+1'b1;
     if(sy==last_sample)begin capture<=0;end
     else begin sy<=sy+1'b1;y_offset<=next_y;y_rem<=y_sum>=divisor?y_sum-divisor:y_sum;end
    end else begin sx<=sx+1'b1;x_offset<=next_x;x_rem<=x_sum>=divisor?x_sum-divisor:x_sum;end
   end
   if(done && eligible && result_allowed && roi_consistent)begin
    O_diagnostic<=core_diagnostic;last_contrast<=contrast;result_id<=active_id;diagnostic_valid<=1;
    if(result!=0)begin
     rejected_count<=0;
     if(balanced && !V22_POLICY && label==3 && result==2 && neutral_exit)begin
      label<=2;pending<=0;pending_count<=0;pending_gap<=0;stale<=0;
     end else if(result==label || (result==1 && label!=3 && $signed(core_diagnostic[31:0])>=(low_res?FAST_HAPPY_MARGIN_LOW:FAST_HAPPY_MARGIN)) || (label==0 && result==2))begin
      label<=result;stale<=0;
      // One matching-current observation may separate two fresh candidates.
      if(ENABLE_AU && result==label && pending!=0 && pending!=2 && pending!=label && !pending_gap)pending_gap<=1;
      else begin pending<=0;pending_count<=0;pending_gap<=0;end
     end else if(pending==result && pending_count>=((ENABLE_AU && label==1 && result==2)?3:((ENABLE_AU && label==3 && result==2)?3:1)))begin label<=result;pending<=0;pending_count<=0;pending_gap<=0;stale<=0;end
     else begin pending<=result;pending_count<=pending==result?pending_count+1'b1:1;pending_gap<=0;end
    end else begin
     // Rejected observations cannot count as consecutive smile support or
     // keep an obsolete HAPPY label while a tense expression is uncertain.
     pending<=0;pending_count<=0;pending_gap<=0;
     if(rejected_count==2)begin label<=0;rejected_count<=0;end
     else rejected_count<=rejected_count+1'b1;
    end
   end
   if(!balanced || V22_POLICY || !eligible || !roi_consistent || stale>=12)neutral_votes<=0;
   else if(fresh_result)begin
    if(label==3 && (result==2 || result==3))neutral_votes<={neutral_votes[1:0],result==2};
    else neutral_votes<=0;
   end
   // Fresh independent C is a classification result, even when base=OTHER.
   // It refreshes expression freshness only; never detector/coast lifetime.
   if(balanced && ENABLE_CONFUSED && fresh_result && core_diagnostic[135])stale<=0;
   // A fresh R candidate needs two supported updates, with one neutral gap allowed. It must not be
   // erased by the stale timer before confirmation arrives.
   // Existing HAPPY expiry is retained while no fresh HAPPY supports it.
   if(balanced && fresh_result && result==3 && label!=1)stale<=0;
   if(hard_valid && !roi_consistent && (patch_face[31] || capture || busy || diagnostic_valid))begin
    label<=0;pending<=0;pending_count<=0;pending_gap<=0;rejected_count<=0;diagnostic_valid<=0;result_allowed<=0;stale<=0;
    if(!(I_sof && eligible && !busy && !start))begin capture<=0;upper_count<=0;end
   end
   if(!eligible)begin capture<=0;result_allowed<=0;upper_count<=0;
    label<=0;pending<=0;pending_count<=0;pending_gap<=0;rejected_count<=0;stale<=0;diagnostic_valid<=0;
   end
   // A classifier result must never refresh this detector-support age.
   // Geometry loss clears the prior evidence; an unsupported foreign ROI cannot
   // bootstrap another coast episode after the previous owner was discarded.
   if(!hard_valid)begin coast_supported<=0;coast_age<=COAST_FRAMES;end
   else if(detector_supported)begin coast_supported<=1;coast_age<=0;end
   else if(I_sof && coast_age<COAST_FRAMES)coast_age<=coast_age+1'b1;
   if(hard_valid && !detector_supported && !roi_consistent && coast_supported)begin
    coast_supported<=0;coast_age<=COAST_FRAMES;
   end
  end
 end
endmodule

// No feedback into V21 label/pending/release or detector lifetime.
// Balanced: two of four fresh combined observations enter; three consecutive
// misses leave. Legacy: two of three entry/release. A lone spike cannot enter.
module ext_expression_confused_overlay #(parameter integer BALANCED_POLICY=0, STRICT_ENTRY=0)(input wire I_clk,I_rst_n,I_clear,I_fresh,
 input wire I_candidate,input wire [1:0] I_base_result,output reg O_active);
 reg [2:0] votes;
 wire positive=I_candidate && (BALANCED_POLICY || I_base_result==3);
 always @(posedge I_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin votes<=0;O_active<=0;end
  else if(I_clear)begin votes<=0;O_active<=0;end
  else if(I_fresh)begin
   if(I_base_result==1 || (!BALANCED_POLICY && I_base_result==0))begin votes<=0;O_active<=0;end
   else begin
    votes<={votes[1:0],positive};
    if(positive && (STRICT_ENTRY?votes[0]:(BALANCED_POLICY?(|votes):(|votes[1:0]))))O_active<=1;
    else if(!positive && (BALANCED_POLICY?!(|votes[1:0]):!(&votes[1:0])))O_active<=0;
   end
  end
 end
endmodule
