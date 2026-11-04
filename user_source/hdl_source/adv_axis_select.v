// Projection-band selection: isolated support cannot enlarge the selected object.
module adv_axis_select(input wire I_clk,I_rst_n,I_start,I_valid,I_last,
 input wire [7:0] I_index,I_value,I_min_count,I_gap,I_min_width,
 output reg O_valid,output reg [7:0] O_lo,O_hi);
 reg active;reg [7:0] lo,hi,gaps;reg [15:0] mass,best;
 wire eligible=active && hi-lo+1>=I_min_width;
 always @(posedge I_clk or negedge I_rst_n)begin
 if(!I_rst_n)begin active<=0;lo<=0;hi<=0;gaps<=0;mass<=0;best<=0;O_valid<=0;O_lo<=0;O_hi<=0;end
 else if(I_start)begin active<=0;gaps<=0;mass<=0;best<=0;O_valid<=0;end
 else if(I_valid)begin
  if(I_last)begin if(eligible && mass>best)begin O_valid<=1;O_lo<=lo;O_hi<=hi;end active<=0;end
  else if(I_value>=I_min_count)begin
   if(!active)begin lo<=I_index;mass<=I_value;end else mass<=mass+I_value;
   hi<=I_index;gaps<=0;active<=1;
  end else if(active)begin
   if(gaps>=I_gap)begin
    if(eligible && mass>best)begin best<=mass;O_valid<=1;O_lo<=lo;O_hi<=hi;end
    active<=0;mass<=0;gaps<=0;
   end else gaps<=gaps+1'b1;
  end
 end end
endmodule
