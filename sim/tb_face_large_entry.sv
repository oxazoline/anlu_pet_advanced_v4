`timescale 1ns/1ps
module tb_face_large_entry;
 reg clk=0,rst=0,v=0,sof=0;always #5 clk=~clk;reg[95:0] data=0;wire[31:0] status;reg[7:0] pixels[0:14399];integer frame,y,x,index;
 ext_face_detector dut(clk,rst,data,v,sof,status);
 task tick(input bit valid,input bit fs);begin @(negedge clk);v=valid;sof=fs;end endtask
 initial begin
  $readmemh("large_0_pixels.hex",pixels);repeat(3)@(negedge clk);rst=1;force dut.prefer_large=1;
  for(frame=0;frame<3;frame=frame+1)begin
   tick(0,1);tick(0,0);if(!dut.large_scan || dut.zoom)$fatal(1,"near-face field not retained through fresh confirmation");
   for(y=0;y<720;y=y+1)for(x=0;x<320;x=x+1)begin
    if((x+y)%37==3)tick(0,0);
    tick(1,0);index=(y/8)*160+x/2;data={12{pixels[index]}};
   end
   tick(0,0);wait(dut.done);repeat(3)tick(0,0);
   if(dut.timeout || !dut.found || dut.neighbors[6:0]<5)$fatal(1,"large real pipeline lacked fresh strong evidence");
   if(frame<2 && status[31])$fatal(1,"large acquisition bypassed three hits");
   if(frame==0)release dut.prefer_large;
  end
  if(!status[31] || status[14:8]!=88 || {1'b0,status[29:22]}+status[14:8]>160 || {2'b0,status[21:15]}+status[14:8]>90)$fatal(1,"near-face overlay ROI not valid/clipped");
  $display("PASS FACE LARGE ENTRY: three real four-pixel frames through integral RAM, virtual20-stage cascade and tracker, retained hinted near mode, strict acquisition and bounded on-screen88-cell FER ROI");$finish;
 end
 initial begin #300000000;$fatal(1,"near-face entry timeout");end
endmodule
