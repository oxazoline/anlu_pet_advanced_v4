`timescale 1ns/1ps
module tb_expression_temporal;
 reg clk=0,rst=0,sof=0;always #5 clk=~clk;reg[31:0] face=0;wire[31:0] status;reg[167:0] diag;
 ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.BALANCED_POLICY(0),.ENABLE_AU(0)) dut(clk,rst,96'd0,1'b0,sof,face,status,,,,,,);
 task fs;begin @(negedge clk);sof=1;@(negedge clk);sof=0;#1;end endtask
 task result(input[1:0] value,input[31:0] margin);begin
  @(negedge clk);diag=0;diag[167]=1;diag[31:0]=margin;force dut.core_diagnostic=diag;force dut.done=1;force dut.result=value;force dut.result_allowed=1;
  @(negedge clk);release dut.core_diagnostic;release dut.done;release dut.result;release dut.result_allowed;#1;
 end endtask
 integer i;
 initial begin
  repeat(3)@(negedge clk);rst=1;face={1'b1,1'b0,8'd30,7'd20,7'd32,8'd6};fs;force dut.capture=0;
  result(2,4000);if(status[1:0]!=2)$fatal(1,"neutral start");
  result(1,1);if(status[1:0]!=2)$fatal(1,"one weak smile replaced neutral");
  result(0,0);result(1,1);if(status[1:0]!=2)$fatal(1,"nonconsecutive smile support accepted");
  result(1,1);if(status[1:0]!=1)$fatal(1,"two fresh weak smile results not accepted");
  result(3,4000);if(status[1:0]!=1)$fatal(1,"one tense glitch overrode HAPPY");result(0,0);result(3,4000);if(status[1:0]!=1)$fatal(1,"interrupted tense accumulated");result(3,4000);if(status[1:0]!=3)$fatal(1,"tense result left stale HAPPY visible");
  result(1,32'h7fffffff);if(status[1:0]!=3)$fatal(1,"single HAPPY glitch overrode nervous");
  result(1,32'h7fffffff);if(status[1:0]!=1)$fatal(1,"persistent smile cannot exit nervous");
  result(2,4000);if(status[1:0]!=1)$fatal(1,"one neutral glitch flickered");
  result(2,4000);if(status[1:0]!=2)$fatal(1,"neutral needs more than two fresh results");
  result(1,32'h7fffffff);if(status[1:0]!=1)$fatal(1,"strong smile onset");
  result(0,0);result(0,0);if(status[1:0]!=1)$fatal(1,"brief uncertain result flickered");
  result(0,0);if(status[1:0]!=0)$fatal(1,"three uncertain results kept stale HAPPY");
  result(1,32'h7fffffff);if(status[1:0]!=1)$fatal(1,"strong smile reacquisition");
  face[6:0]=0;repeat(3)@(negedge clk);if(status[1:0]!=1)$fatal(1,"short detector coast lost label");
  for(i=0;i<9;i=i+1)fs;
  if(status[1:0]!=1)$fatal(1,"coast expired early");fs;repeat(2)@(negedge clk);if(status[1:0]!=0 || status[6] || status[15:12]!=10)$fatal(1,"ten-SOF coast unbounded");
  face[6:0]=6;fs;result(3,4000);result(3,4000);face[7]=1;#1;if(status[1:0]!=3 || !status[4] || !status[6])$fatal(1,"accepted profile result hidden");
  repeat(2)@(negedge clk);face[7]=0;fs;result(3,4000);result(3,4000);face[31]=0;#1;if(status[1:0]!=0)$fatal(1,"no-face retained nervous");
  release dut.capture;
  $display("PASS EXPRESSION TEMPORAL: two-result tense confirmation, two-result tense-to-smile/neutral confirmation, interrupted weak evidence reset, three-reject stale-HAPPY clear, ten-SOF detector-support coast independent of classification and immediate invalid suppression, accepted profile labels allowed");$finish;
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
