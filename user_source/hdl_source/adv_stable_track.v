// Fresh evidence only: hysteresis, bounded withdrawal and coordinate damping.
module adv_stable_track #(parameter integer MAX_AGE=51760000,MISS_LIMIT=6)(
 input wire I_clk,I_rst_n,I_done,input wire [31:0] I_box,
 input wire I_keep,I_strong,output wire [31:0] O_box);
 reg visible;reg [1:0] hits,jumps;reg [3:0] misses;reg [25:0] age;
 reg [7:0] x,w;reg [6:0] y,h;reg [29:0] pending;
 wire [7:0] nx=I_box[29:22],nw=I_box[14:7];wire [6:0] ny=I_box[21:15],nh=I_box[6:0];
 wire [8:0] dx=nx>x?nx-x:x-nx;wire [7:0] dy=ny>y?ny-y:y-ny;
 wire nearby=dx<=({1'b0,w}>>1)+8 && dy<=({1'b0,h}>>1)+6;
 wire evidence=I_box[31] || (visible && I_keep && nearby);
 wire [7:0] safe_w=({1'b0,x}+w>160)?160-x:w;wire [6:0] safe_h=({1'b0,y}+h>90)?90-y:h;
 assign O_box={visible,1'b0,x,y,safe_w,safe_h};
 always @(posedge I_clk or negedge I_rst_n)begin
 if(!I_rst_n)begin visible<=0;hits<=0;jumps<=0;misses<=0;age<=0;x<=0;y<=0;w<=0;h<=0;pending<=0;end
 else begin
  if(age<MAX_AGE)age<=age+1'b1;
  if(age>=MAX_AGE-1)begin visible<=0;hits<=0;jumps<=0;end
  if(I_done)begin
   if(evidence)begin
    if(!visible)begin
     x<=nx;y<=ny;w<=nw;h<=nh;misses<=0;age<=0;
     if(hits!=2)hits<=hits+1'b1;
     if(hits>=1 || I_strong)visible<=1;
    end else if(nearby)begin
     age<=0;misses<=0;jumps<=0;
     if(dx>1)x<=({1'b0,x}+nx+1)>>1;
     if(dy>1)y<=({1'b0,y}+ny+1)>>1;
     w<=({2'b0,w}+({2'b0,w}<<1)+nw+2)>>2;h<=({2'b0,h}+({2'b0,h}<<1)+nh+2)>>2;
    end else begin
     // A distant positive needs two nearby observations before re-acquisition.
     pending<=I_box[29:0];
     if(jumps!=0 && nx+8>=pending[29:22] && nx<=pending[29:22]+8 && ny+6>=pending[21:15] && ny<=pending[21:15]+6)begin
      x<=nx;y<=ny;w<=nw;h<=nh;age<=0;misses<=0;jumps<=0;
     end else jumps<=1;
    end
   end else begin
    if(misses<MISS_LIMIT)misses<=misses+1'b1;
    if(misses>=1)hits<=0;
    if(misses>=MISS_LIMIT-1)begin visible<=0;jumps<=0;end
   end
  end
 end end
endmodule
