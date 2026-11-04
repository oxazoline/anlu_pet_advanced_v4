// V17 bounded appearance bridge. It never acquires a new face by itself.
module ext_face_visual_hold #(parameter integer LIMIT_CYCLES=103520000, FRESH_CYCLES=10352000)(
 input wire I_clk,I_rst_n,input wire [31:0] I_face,input wire I_visual,
 output reg [31:0] O_face);
 reg [31:0] anchor;reg [26:0] detector_age;reg [23:0] visual_age;
 wire raw_supported=I_face[31] && I_face[6:0]!=0;
 wire timeout_now=!I_face[31] && I_face[30];
 wire bridge=anchor[31] && detector_age<LIMIT_CYCLES && visual_age<FRESH_CYCLES && !timeout_now;

 wire [6:0] aw=anchor[14:8],rw=I_face[14:8];
 wire [8:0] raw_cy={2'd0,I_face[21:15]}+{3'd0,rw[6:1]};
 wire contained={1'b0,I_face[29:22]}+9'd2>={1'b0,anchor[29:22]} &&
  {2'd0,I_face[21:15]}+9'd2>={2'd0,anchor[21:15]} &&
  {1'b0,I_face[29:22]}+rw<={1'b0,anchor[29:22]}+aw+9'd2 &&
  {2'd0,I_face[21:15]}+rw<={2'd0,anchor[21:15]}+aw+9'd2;
 wire eye_shrink=anchor[31] && !I_face[7] && {1'b0,rw}+8'd2<{1'b0,aw}-({1'b0,aw}>>2) &&
  contained && raw_cy<={2'd0,anchor[21:15]}+({2'd0,aw}>>1)-({2'd0,aw}>>3);
 // A newly reacquired upper lens box must not replace still-supported mouth geometry.
 // This geometry veto is bounded, and never applies to a confirmed profile.
 wire blocked=raw_supported && eye_shrink && detector_age<LIMIT_CYCLES;
 wire supported=raw_supported && !blocked;
 // Bit30 means appearance support only while visible; otherwise detector timeout.
 wire [31:0] next_face=supported?I_face:(bridge?{2'b11,anchor[29:8],8'd0}:(blocked?32'd0:I_face));
 always @(posedge I_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin O_face<=0;anchor<=0;detector_age<=LIMIT_CYCLES;visual_age<=FRESH_CYCLES;end
  else begin
   O_face<=next_face;
   if(detector_age<LIMIT_CYCLES)detector_age<=detector_age+1'b1;
   if(visual_age<FRESH_CYCLES)visual_age<=visual_age+1'b1;
   if(supported)begin anchor<=I_face;detector_age<=0;end
   if(I_visual && anchor[31])visual_age<=0;
   if(timeout_now)begin anchor<=0;visual_age<=FRESH_CYCLES;end
  end
 end
endmodule
