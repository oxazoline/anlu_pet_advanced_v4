`timescale 1ns/1ps
module tb_face_enlarge;
 reg clk=0,rst=0,done=0,found=1,timeout=0;always #5 clk=~clk;
 reg [7:0] x=50,votes=6;reg [6:0] y=20,w=24;wire [31:0] status;
 ext_face_track #(.HOLD_CYCLES(1000)) dut(clk,rst,done,found,timeout,x,y,w,votes,status);
 task hit(input [7:0] xx,input [6:0] yy,ww,input [7:0] vv);begin
  @(negedge clk);x=xx;y=yy;w=ww;votes=vv;done=1;@(negedge clk);done=0;#1;
 end endtask
 task acquire;begin hit(50,20,24,6);hit(50,20,24,6);hit(50,20,24,6);if(!status[31])$fatal(1,"entry");end endtask
 initial begin
  repeat(3)@(negedge clk);rst=1;acquire;
  hit(35,5,56,6);if(status[14:8]!=24 || dut.expand_hits!=1)$fatal(1,"one enlargement accepted");
  hit(36,6,56,6);if(status[14:8]!=24 || dut.expand_hits!=2)$fatal(1,"two enlargements accepted");
  hit(35,5,56,6);if(!status[31] || status[14:8]!=56 || status[29:22]!=35 || status[21:15]!=5)$fatal(1,"three independent enclosing hits failed");
  rst=0;repeat(2)@(negedge clk);rst=1;acquire;
  hit(35,5,56,6);hit(35,5,56,4);if(dut.expand_hits!=0 || status[14:8]!=24)$fatal(1,"weak hit continued enlargement");
  hit(35,5,56,6);hit(35,5,56,6);hit(35,5,56,8'h86);
  if(status[14:8]!=24 || dut.expand_hits!=0)$fatal(1,"profile pose enlarged frontal target");
  rst=0;repeat(2)@(negedge clk);rst=1;acquire;
  hit(70,5,56,9);hit(70,5,56,9);hit(70,5,56,9);
  if(status[14:8]!=24 || dut.expand_hits!=0)$fatal(1,"foreign non-enclosing target stole box");
  rst=0;repeat(2)@(negedge clk);rst=1;acquire;
  hit(35,5,56,6);hit(35,5,56,6);timeout=1;hit(35,5,56,6);
  if(status[31] || !status[30])$fatal(1,"timeout bypassed during enlargement");
  $display("PASS FACE ENLARGE: three fresh spatially consistent frontal enclosing detections, no one/two-hit expansion, weak/profile/foreign isolation and timeout cancellation; ordinary acquisition unchanged");$finish;
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
