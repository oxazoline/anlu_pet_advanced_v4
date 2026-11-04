`timescale 1ns/1ps
module tb_advanced_motion;
reg clk=0,rst=0,valid=0,sof=0;reg[95:0]rgb=0;wire[31:0]refbox,yeah,motion,info;
always #5 clk=~clk;adv_vision dut(clk,rst,rgb,valid,sof,32'd0,refbox,yeah,motion,info,16'd7,,);
integer y,x,n;reg salt=0;reg[7:0]v;
task frame(input integer offset,input integer brightness);begin
 @(negedge clk);sof=1;valid=0;@(negedge clk);sof=0;
 for(y=0;y<720;y=y+1)begin
  for(x=0;x<320;x=x+1)begin
   @(negedge clk);valid=1;
   v=(x*4>=offset && x*4<offset+160 && y>=240 && y<400)?8'd30:brightness;
   if(salt && y>=80 && y<88 && (x==9 || x==33 || x==71 || x==121 || x==181 || x==241 || x==281 || x==309))v=8'd10;
   rgb={12{v}};
  end
  @(negedge clk);valid=0;repeat(2)@(negedge clk);
 end
 wait(dut.state==0 && !dut.capture);repeat(8)@(negedge clk);
end endtask
initial begin
 repeat(4)@(negedge clk);rst=1;
 frame(320,180);frame(320,180);frame(320,180);if(motion[31])$fatal(1,"static scene detected as motion");
 frame(352,180);frame(384,180);frame(416,180);
 if(!motion[31] || info[7:0]==0)$fatal(1,"moving object not reported");
 frame(416,180);frame(416,180);frame(416,180);if(motion[31])$fatal(1,"stationary region persisted");
 frame(416,250);if(dut.raw_motion[31])$fatal(1,"global illumination classified as object motion");
 frame(416,180);frame(416,180);frame(416,180);salt=1;
 frame(416,180);frame(416,180);salt=0;frame(416,180);
 if(motion[31] || dut.raw_motion[31])$fatal(1,"isolated motion noise displayed as target");
 $display("PASS ADVANCED MOTION: complete720p streams, initialization, static rejection, translated object bbox/event, bounded withdrawal, global illumination veto");$finish;
end
initial begin #1000000000;$fatal(1,"motion timeout");end
endmodule
