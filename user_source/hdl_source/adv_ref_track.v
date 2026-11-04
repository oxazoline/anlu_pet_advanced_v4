// Printed-reference tracker: strict identity refresh, local weak measurements,
// two-frame bounded prediction. bit30 marks weak/predicted state, never fresh ID.
module adv_ref_track #(parameter integer MAX_AGE=41408000,MISS_LIMIT=8)(
 input wire I_clk,I_rst_n,I_done,input wire [31:0] I_full,I_weak,input wire I_strong,
 output wire [31:0] O_box);
 reg visible,coast,jump_pending;reg [1:0] hits,predictions;reg [3:0] misses;reg [25:0] age;
 reg [7:0] x,w;reg [6:0] y,h;reg [29:0] pending;reg signed [7:0] vx,vy;
 wire [31:0] measurement=I_full[31] ? I_full:I_weak;
 wire [7:0] nx=measurement[29:22],nw=measurement[14:7];wire [6:0] ny=measurement[21:15],nh=measurement[6:0];
 wire [8:0] dx=nx>x ? nx-x:x-nx;wire [7:0] dy=ny>y ? ny-y:y-ny;
 wire nearby=dx<=({1'b0,w}>>1)+9'd8 && dy<=({1'b0,h}>>1)+8'd6;
 wire [7:0] safe_w=({1'b0,x}+w>160) ? 160-x:w;wire [6:0] safe_h=({1'b0,y}+h>90) ? 90-y:h;
 wire signed [8:0] ddx=$signed({1'b0,nx})-$signed({1'b0,x});
 wire signed [8:0] ddy=$signed({2'b0,ny})-$signed({2'b0,y});
 wire signed [9:0] px=$signed({2'b0,x})+vx,py=$signed({3'b0,y})+vy;
 function signed [7:0] velocity;input signed [8:0] d;begin if(d>4)velocity=8'sd4;else if(d< -4)velocity=-8'sd4;else velocity=d[7:0];end endfunction
 function [7:0] clipx;input signed [9:0] p;input [7:0] width;reg [8:0] limit;begin limit=9'd160-width;if(p<0)clipx=0;else if(p>$signed({1'b0,limit}))clipx=limit[7:0];else clipx=p[7:0];end endfunction
 function [6:0] clipy;input signed [9:0] p;input [6:0] height;reg [7:0] limit;begin limit=8'd90-height;if(p<0)clipy=0;else if(p>$signed({2'b0,limit}))clipy=limit[6:0];else clipy=p[6:0];end endfunction
 assign O_box={visible,coast,x,y,safe_w,safe_h};
 always @(posedge I_clk or negedge I_rst_n)begin
 if(!I_rst_n)begin visible<=0;coast<=0;jump_pending<=0;hits<=0;predictions<=0;misses<=0;age<=MAX_AGE;x<=0;y<=0;w<=0;h<=0;pending<=0;vx<=0;vy<=0;end
 else begin
 if(age<MAX_AGE)age<=age+1'b1;
 if(age>=MAX_AGE-1)begin visible<=0;hits<=0;jump_pending<=0;end
 if(I_done)begin
  if(I_full[31])begin
   if(!visible)begin
    x<=nx;y<=ny;w<=nw;h<=nh;vx<=0;vy<=0;misses<=0;predictions<=0;coast<=0;age<=0;
    if(hits>=1 && nearby || I_strong)begin visible<=1;hits<=2;end else hits<=1;
   end else if(nearby || (jump_pending && nx+9'd8>=pending[29:22] && nx<={1'b0,pending[29:22]}+9'd8 && ny+8'd6>=pending[21:15] && ny<={1'b0,pending[21:15]}+8'd6))begin
    visible<=1;coast<=0;age<=0;misses<=0;predictions<=0;jump_pending<=0;hits<=2;
    x<=nx;y<=ny;w<=({1'b0,w}+nw+9'd1)>>1;h<=({1'b0,h}+nh+8'd1)>>1;
    vx<=nearby ? velocity(ddx):8'sd0;vy<=nearby ? velocity(ddy):8'sd0;
   end else begin pending<=I_full[29:0];jump_pending<=1;coast<=1;if(misses<MISS_LIMIT)misses<=misses+1'b1;if(misses>=MISS_LIMIT-1)visible<=0;end
  end else begin
   coast<=visible;
   if(misses<MISS_LIMIT)misses<=misses+1'b1;
   if(misses>=1)hits<=0;
   if(misses>=MISS_LIMIT-1)begin visible<=0;jump_pending<=0;end
   if(visible && I_weak[31] && nearby)begin x<=nx;y<=ny;vx<=velocity(ddx);vy<=velocity(ddy);predictions<=0;end
   else if(visible && predictions<2)begin x<=clipx(px,w);y<=clipy(py,h);predictions<=predictions+1'b1;end
  end
 end end end
endmodule
