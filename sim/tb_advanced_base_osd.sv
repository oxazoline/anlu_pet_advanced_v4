`timescale 1ns/1ps
module tb_advanced_base_osd;
reg clk=0,rst=0,vs=0,de=0;always #5 clk=~clk;
wire[31:0]face={2'b10,8'd40,7'd30,7'd32,8'd9};wire[31:0]expression=32'd1;
wire nv,nh,nd,ov,oh,od;wire[23:0]nrgb,orgb;wire[9:0]addr;
adv_base_osd dut(clk,rst,vs,1'b0,de,24'h123456,face,expression,4'd0,nv,nh,nd,nrgb);
basic_osd golden(clk,rst,vs,1'b0,de,24'h123456,4'd0,64'd0,64'd0,1'b1,32'd0,71'd0,8'd64,ov,oh,od,orgb,2'd0,face,expression,168'd0,8'd0,1'b0,8'd0,addr);
integer x,y,ox=0,oy=0,checked=0;reg prev_de=0;
always @(negedge clk)if(rst)begin
 if(nd!==od || nv!==ov)$fatal(1,"base pipeline synchronization changed");
 if(nd)begin
  if((ox<176 && oy<176) || (oy>=180 && !(oy>=224 && oy<240) && !(ox>=704 && ox<720 && oy<240)))begin
   if(nrgb!==orgb)$fatal(1,"logo/face/expression/background changed at%0d,%0d %h/%h",ox,oy,nrgb,orgb);checked=checked+1;
  end
  ox=ox+1;
 end else if(prev_de)begin ox=0;oy=oy+1;end
 prev_de=nd;
end
initial begin repeat(3)@(negedge clk);rst=1;vs=1;@(negedge clk);vs=0;repeat(3)@(negedge clk);
 for(y=0;y<720;y=y+1)begin
  for(x=0;x<1280;x=x+1)begin @(negedge clk);de=1;end
  @(negedge clk);de=0;repeat(4)@(negedge clk);
 end
 repeat(6)@(negedge clk);if(checked<500000)$fatal(1,"insufficient pixel comparisons");
 $display("PASS ADVANCED BASE OSD: original logo alpha/RGB, face geometry, H label and background equal to V26 over%0d pixels; sync/DE preserved",checked);$finish;
end
initial begin #20000000;$fatal(1,"base OSD timeout");end
endmodule
