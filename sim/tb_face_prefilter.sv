`timescale 1ns/1ps
module tb_face_prefilter;
 reg clk=0,rst=0,v=0,sof=0;always #5 clk=~clk;reg [95:0] data=0;wire [31:0] status;
 defparam dut.ENABLE_LARGE=0;
 defparam dut.ENABLE_PREFILTER=1;
 ext_face_detector dut(clk,rst,data,v,sof,status);
 defparam dut.classifier.MAX_CYCLES=100;
 integer frame,y,x,k,dx,dy,xx,yy,n,total,row_sum;integer expected[0:14399];
 function [7:0] pixel(input integer x,input integer y,input integer f);begin
  pixel=((x*17+y*23+f*37)^((x%7==0 || y%11==0)?255:0))%256;
 end endfunction
 task tick(input bit valid,input bit fs);begin @(negedge clk);v=valid;sof=fs;end endtask
 initial begin
  repeat(3)@(negedge clk);rst=1;force dut.prefer_filter=1;
  for(frame=0;frame<2;frame=frame+1)begin
   tick(0,1);tick(0,0);
   if(!dut.filter_capture || dut.zoom!==frame[0])$fatal(1,"capture mode");
   for(y=0;y<90;y=y+1)begin row_sum=0;
    for(x=0;x<160;x=x+1)begin
     xx=frame==0?x*8:320+x*4;yy=frame==0?y*8:176+y*4;total=0;
     for(dy=0;dy<4;dy=dy+1)for(dx=0;dx<4;dx=dx+1)total=total+pixel(xx+dx,yy+dy,frame);
     row_sum=row_sum+((total+8)/16);expected[y*160+x]=row_sum+(y==0?0:expected[(y-1)*160+x]);
    end
   end
   for(y=0;y<720;y=y+1)for(x=0;x<320;x=x+1)begin
    if((x+y)%19==7)tick(0,0);
    tick(1,0);for(k=0;k<4;k=k+1)data[95-k*24-:24]={3{pixel(x*4+k,y,frame)}};
   end
   tick(0,0);repeat(200)tick(0,0);
   for(n=0;n<14400;n=n+1)if(dut.image_ram.line_store.memory[n]!==expected[n])$fatal(1,"mean integral frame%0d addr%0d got%h expected%h",frame,n,dut.image_ram.line_store.memory[n],expected[n]);
  end
  release dut.prefer_filter;
  // Fallback requires two empty scans, never one miss or a supported candidate.
  rst=0;repeat(3)tick(0,0);rst=1;
  force dut.done=1;force dut.found=0;force dut.O_status=0;force dut.pending_hint=0;
  tick(0,0);#1;if(dut.prefer_filter)$fatal(1,"single miss changed mode");
  tick(0,0);#1;if(!dut.prefer_filter)$fatal(1,"two misses did not enable fallback");
  force dut.found=1;force dut.neighbors=8'd6;repeat(3)tick(0,0);#1;
  if(!dut.prefer_filter || dut.empty_scans!=0)$fatal(1,"supported detection lost fallback mode");
  release dut.done;release dut.found;release dut.O_status;release dut.pending_hint;release dut.neighbors;
  $display("PASS FACE PREFILTER: all14400 integrals from independent 4x4 arithmetic in full and zoom fields, different consecutive frames, valid gaps, exact rounding, bounded empty-scan fallback and supported-mode retention");$finish;
 end
 initial begin #15000000;$fatal(1,"timeout");end
endmodule
