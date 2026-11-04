// Activity status with V2 two-of-three entry and three fresh misses to exit.
// Geometry is retained for diagnostics, without unused object-association math.
module adv_motion_hold #(parameter integer MAX_AGE=51760000)(
 input wire I_clk,I_rst_n,I_done,input wire [31:0] I_box,output wire [31:0] O_box);
 reg visible;reg [1:0]hits,misses;reg [25:0]age;reg [29:0]geometry;
 assign O_box={visible,1'b0,geometry};
 always @(posedge I_clk or negedge I_rst_n)begin
 if(!I_rst_n)begin visible<=0;hits<=0;misses<=0;age<=0;geometry<=0;end
 else begin
 if(age<MAX_AGE)age<=age+1'b1;
 if(age>=MAX_AGE-1)begin visible<=0;hits<=0;end
 if(I_done)begin
  if(I_box[31])begin geometry<=I_box[29:0];age<=0;misses<=0;if(!visible)begin if(hits!=2)hits<=hits+1'b1;if(hits>=1)visible<=1;end end
  else begin if(misses!=3)misses<=misses+1'b1;if(misses>=1)hits<=0;if(misses>=2)visible<=0;end
 end end end
endmodule
