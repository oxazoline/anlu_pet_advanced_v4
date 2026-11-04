`timescale 1ns/1ps
module tb_face_zoom;
 reg clk=0,rst=0,v=0,sof=0;always #5 clk=~clk;reg [95:0] data=0;wire [31:0] status;
 defparam dut.ENABLE_LARGE=0;
 ext_face_detector dut(clk,rst,data,v,sof,status);
 defparam dut.classifier.MAX_CYCLES=100;
 defparam dut.ENABLE_PREFILTER=0; // This test isolates the legacy point-sample contract.
 integer frame,y,x,k,xx,yy,sx,sy,idx;integer expected[0:14399];integer row_sum,total;
 function [7:0] pixel(input integer x,input integer y);begin pixel=(x*7+y*11)%256;end endfunction
 task tick(input bit valid,input bit fs);begin @(negedge clk);v=valid;sof=fs;end endtask
 initial begin
  repeat(3)@(negedge clk);rst=1;
  for(frame=0;frame<4;frame=frame+1)begin
   tick(0,1);tick(0,0);
   if(dut.zoom!==((frame%2)==1))$fatal(1,"full/zoom round schedule");
   for(y=0;y<90;y=y+1)begin row_sum=0;
    for(x=0;x<160;x=x+1)begin
      xx=(frame%2)==0?x*8+3:(frame==1?320:0)+x*4+3;yy=(frame%2)==0?y*8+3:(frame==1?176:0)+y*4+3;
      row_sum=row_sum+pixel(xx,yy);expected[y*160+x]=row_sum+(y==0?0:expected[(y-1)*160+x]);
    end
   end
   for(y=0;y<720;y=y+1)for(x=0;x<320;x=x+1)begin
     if((x+y)%23==3)tick(0,0);
     tick(1,0);for(k=0;k<4;k=k+1)data[95-k*24-:24]={3{pixel(x*4+k,y)}};
   end
   tick(0,0);repeat(200)tick(0,0);
   for(k=0;k<14400;k=k+1)if(dut.image_ram.line_store.memory[k]!==expected[k])$fatal(1,"zoom integral mismatch frame=%0d address=%0d",frame,k);
  end
  // Mapping odd coordinates/sizes must enclose the low-resolution candidate in the global x8 units.
  force dut.box_x=8'd21;force dut.box_y=7'd13;force dut.box_size=7'd25;
  #1;if(dut.mapped_x!=10 || dut.mapped_y!=6 || dut.mapped_size!=13)$fatal(1,"global zoom coordinates");
  release dut.box_x;release dut.box_y;release dut.box_size;
  // Hint conversion is reciprocal for even coordinates and square sizes.
  force dut.pending_hint={1'b1,1'b0,8'd10,7'd6,7'd13,8'd9};
  #1;if(dut.converted_hint[29:22]!=20 || dut.converted_hint[21:15]!=12 || dut.converted_hint[14:8]!=26)$fatal(1,"local zoom hint");
  release dut.pending_hint;
  rst=0;repeat(2)@(negedge clk);
  $display("PASS FACE ZOOM: full/center/top-left 2x capture exact all 14400 integral values against independent four-lane/gap stream; alternating schedule, odd-coordinate global mapping, reciprocal hint conversion/reset");$finish;
 end
 initial begin #15000000;$fatal(1,"timeout");end
endmodule
