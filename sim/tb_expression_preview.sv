`timescale 1ns/1ps
module tb_expression_preview;
 reg sc=0,dc=0,rst=0,w=0,commit=0,vs=0;always #5 sc=~sc;always #7 dc=~dc;
 reg [9:0] wa=0,ra=0;reg [7:0] pixel=0,id=0;wire [7:0] gray,shown;wire valid;
 ext_expression_preview dut(sc,dc,rst,w,wa,pixel,commit,id,vs,ra,gray,valid,shown);
 integer i;
 task patch(input integer salt,input integer n);begin
  for(i=0;i<n;i=i+1)begin @(negedge sc);w=1;wa=i;pixel=(i*7+salt)%256;end
  @(negedge sc);w=0;
 end endtask
 task publish(input [7:0] tag);begin @(negedge sc);commit=1;id=tag;@(negedge sc);commit=0;end endtask
 task frame;begin repeat(6)@(negedge dc);vs=1;@(negedge dc);vs=0;repeat(8)@(negedge sc);end endtask
 task check(input integer salt);begin
  for(i=0;i<1024;i=i+1)begin @(negedge dc);ra=i;@(posedge dc);#1;
   if(gray!==((i*7+salt)%256))$fatal(1,"preview pixel mismatch %0d got %d",i,gray);
  end
 end endtask
 initial begin
  repeat(4)@(negedge sc);rst=1;
  patch(11,1024);publish(8'h11);repeat(10)@(negedge dc);
  if(valid)$fatal(1,"preview switched before frame boundary");
  // The other bank is still displayed until VS acknowledges; an entire patch
  // arriving during the pending transfer must be dropped rather than tearing.
  patch(77,1024);publish(8'h77);frame;
  if(!valid || shown!=8'h11)$fatal(1,"pending transfer overwritten");
  check(11);
  patch(23,100);publish(8'h23);frame;if(shown!=8'h11)$fatal(1,"partial patch published");
  check(11);
  patch(31,1024);publish(8'h31);frame;if(shown!=8'h31)$fatal(1,"second patch missing");
  check(31);
  rst=0;repeat(4)@(negedge dc);if(valid || gray!=0)$fatal(1,"preview reset");
  $display("PASS EXPRESSION PREVIEW: asynchronous clocks, exact 1024 pixels, frame-only swap, pending/partial drops, bank safety and reset");$finish;
 end
 initial begin #300000;$fatal(1,"timeout");end
endmodule
