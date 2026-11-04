`timescale 1ns/1ps
module tb_face_tiles;
 reg clk=0,rst=0,sof=0,v=0;always #5 clk=~clk;wire [31:0] status;
 defparam dut.ENABLE_LARGE=0;
 ext_face_detector dut(clk,rst,96'd0,v,sof,status);
 integer k,i,j,xx,yy,count;integer xs[0:8],ys[0:8];
 task fs;begin @(negedge clk);sof=1;@(negedge clk);sof=0;end endtask
 task finish_capture;begin
  @(negedge clk);force dut.valid2=1;force dut.last2=1;@(negedge clk);release dut.valid2;release dut.last2;
  force dut.done=1;@(negedge clk);release dut.done;repeat(3)@(negedge clk);
 end endtask
 initial begin
  xs[0]=320;ys[0]=176;xs[1]=0;ys[1]=0;xs[2]=320;ys[2]=0;xs[3]=640;ys[3]=0;
  xs[4]=0;ys[4]=176;xs[5]=640;ys[5]=176;xs[6]=0;ys[6]=360;xs[7]=320;ys[7]=360;xs[8]=640;ys[8]=360;
  repeat(3)@(negedge clk);rst=1;
  force dut.busy=0;force dut.start=0;force dut.found=0;force dut.timeout=0;force dut.O_status=0;
  for(k=0;k<9;k=k+1)begin
   fs;if(dut.zoom)$fatal(1,"global refresh missing");finish_capture;
   fs;if(!dut.zoom || dut.crop_x*8!=xs[k] || dut.crop_y*8!=ys[k])$fatal(1,"tile origin %0d got %0d,%0d",k,dut.crop_x*8,dut.crop_y*8);
   force dut.col=xs[k]/4;force dut.row=ys[k]+3;v=1;#1;
   if(!dut.sample || dut.sx!=0 || dut.sy!=0)$fatal(1,"tile first sample");
   force dut.col=xs[k]/4+159;force dut.row=ys[k]+359;#1;
   if(!dut.sample || dut.sx!=159 || dut.sy!=89)$fatal(1,"tile last sample");
   force dut.col=xs[k]/4+160;#1;if(dut.sample)$fatal(1,"tile right boundary leaked");
   v=0;release dut.col;release dut.row;finish_capture;
  end
  if(dut.tile_index!=0)$fatal(1,"tile cycle did not wrap");
  // Geometric coverage is independent of the RTL tile-index lookup.
  for(yy=0;yy<=540;yy=yy+4)for(xx=0;xx<=1100;xx=xx+4)begin
   count=0;for(i=0;i<9;i=i+1)if(xx>=xs[i] && yy>=ys[i] && xx+180<=xs[i]+640 && yy+180<=ys[i]+360)count=count+1;
   if(count==0)$fatal(1,"180x180 candidate has uncovered position %0d,%0d",xx,yy);
  end
  // V9 restores detail after a strong full-view small-face seed.
  force dut.pending_hint={1'b1,1'b0,8'd52,7'd25,7'd32,8'd9};force dut.zoom=0;#1;
  if(!dut.choose_zoom)$fatal(1,"first small-face hit did not restore zoom detail");
  force dut.pending_hint={1'b1,1'b0,8'd52,7'd25,7'd36,8'd9};#1;
  if(dut.choose_zoom)$fatal(1,"full-view scale changed unnecessarily");
  force dut.zoom=1;#1;if(!dut.choose_zoom)$fatal(1,"zoom exit hysteresis");
  force dut.pending_hint={1'b1,1'b0,8'd52,7'd25,7'd41,8'd9};#1;if(dut.choose_zoom)$fatal(1,"large tracked face stuck in zoom");
  $display("PASS FACE TILES: nine overlapping 640x360 views, 180px-square coverage on tested 4px lattice (not all pixels), sample boundaries, global alternation and small-face detail restoration and zoom exit at40 units");$finish;
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
