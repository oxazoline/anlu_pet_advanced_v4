// V18 independent appearance support from current pixels, not expression labels.
// Orientation selects the mouth half only; a classifier score cannot refresh life.
module ext_expression_motion(input wire I_clk,I_rst_n,I_begin,I_write,I_finish,I_clean,I_rotate,
 input wire [5:0] I_x,I_y,input wire [7:0] I_pixel,input wire I_lowres,
 input wire [31:0] I_face,output reg O_match);
 (* ram_style="dram" *) reg [3:0] template[0:31];
 (* ram_style="dram" *) reg [7:0] previous_row[0:7];
 reg [7:0] previous_pixel;
 reg [2:0] gx;reg [1:0] gy;reg learn,valid,owned,rotation;
 reg [1:0] partial_seen;reg [5:0] left_errors,right_errors,left_texture,right_texture,left_template,right_template;
 reg [31:0] owner;reg [6:0] mismatches,texture,template_texture;
 function [8:0] distance;input [8:0] a,b;begin distance=a>b?a-b:b-a;end endfunction
 wire same=owner[31] && distance({1'b0,owner[29:22]},{1'b0,I_face[29:22]})<=({2'd0,owner[14:8]}>>3)+1 &&
 distance({2'd0,owner[21:15]},{2'd0,I_face[21:15]})<=({2'd0,owner[14:8]}>>3)+1 &&
 distance({2'd0,owner[14:8]},{2'd0,I_face[14:8]})<=({2'd0,owner[14:8]}>>3)+1 &&
 rotation==I_rotate;
 wire [5:0] tx=I_lowres?({gx,2'b0}+6'd2):({gx,2'b0}+{gx,1'b0}+6'd3);
 wire [5:0] ty=I_lowres?({gy,2'b0}+(rotation?6'd3:6'd16)):({gy,2'b0}+{gy,1'b0}+(rotation?6'd5:6'd24));
 function [1:0] token;input [7:0] a,b;reg signed [9:0] delta;begin
 delta=$signed({2'b0,a})-$signed({2'b0,b});
 token=delta>=4?2'd1:(delta<= -4?2'd2:2'd0);end endfunction
 wire [1:0] ht=gx==0?2'd0:token(I_pixel,previous_pixel);
 wire [1:0] vt=gy==0?2'd0:token(I_pixel,previous_row[gx]);
 wire [4:0] address={gy,gx};wire [3:0] old_token=template[address];
 wire [1:0] errors=(gx!=0 && ht!=old_token[1:0])+(gy!=0 && vt!=old_token[3:2]);
 wire [1:0] activity=(ht!=0)+(vt!=0);
 wire [1:0] half_errors=((gx!=0 && gx!=4) && ht!=old_token[1:0])+(gy!=0 && vt!=old_token[3:2]);
 wire [1:0] half_activity=((gx!=0 && gx!=4) && ht!=0)+(gy!=0 && vt!=0);
 wire full_match=texture>=16 && template_texture>=16 && mismatches<=14;
 wire [1:0] half_match={right_texture>=10 && right_template>=10 && right_errors<=4,
                        left_texture>=10 && left_template>=10 && left_errors<=4};
 always @(posedge I_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin O_match<=0;partial_seen<=0;left_errors<=0;right_errors<=0;left_texture<=0;right_texture<=0;left_template<=0;right_template<=0;gx<=0;gy<=0;learn<=0;valid<=0;owned<=0;owner<=0;rotation<=0;previous_pixel<=0;mismatches<=0;texture<=0;template_texture<=0;end
  else begin
   O_match<=0;
   if(!I_face[31])begin valid<=0;partial_seen<=0;end
   if(I_begin)begin
    gx<=0;gy<=0;mismatches<=0;texture<=0;left_errors<=0;right_errors<=0;left_texture<=0;right_texture<=0;owned<=valid && same;learn<=I_clean;
    if(!same)begin valid<=0;partial_seen<=0;end
    owner<=I_face;rotation<=I_rotate;
   end
   if(I_write && I_x==tx && I_y==ty)begin
    previous_row[gx]<=I_pixel;previous_pixel<=I_pixel;
    if(learn)template[address]<={vt,ht};
    mismatches<=mismatches+errors;texture<=texture+activity;
    if(gx<4)begin left_errors<=left_errors+half_errors;left_texture<=left_texture+half_activity;end
    else begin right_errors<=right_errors+half_errors;right_texture<=right_texture+half_activity;end
    if(gx==7)begin gx<=0;gy<=gy+1'b1;end else gx<=gx+1'b1;
   end
   if(I_finish)begin
    if(learn)begin valid<=texture>=16;template_texture<=texture;left_template<=left_texture;right_template<=right_texture;end
    O_match<=owned && same && (full_match || (|(partial_seen & half_match)));
    partial_seen<=owned && same && !full_match?half_match:2'd0;
   end
  end
 end
endmodule
