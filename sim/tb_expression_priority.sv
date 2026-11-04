`timescale 1ns/1ps
module tb_expression_priority;
 reg clk=0,rst=0,sof=0;always #5 clk=~clk;reg [31:0] face=0;wire[31:0] status;reg[167:0] diag;
 ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.BALANCED_POLICY(0)) dut(clk,rst,96'd0,1'b0,sof,face,status,,,,,,);
 task result(input [1:0] value);begin
 @(negedge clk);diag=0;diag[167]=1;diag[31:0]=4000;force dut.core_diagnostic=diag;force dut.done=1;force dut.result=value;force dut.result_allowed=1;
 @(negedge clk);release dut.core_diagnostic;release dut.done;release dut.result;release dut.result_allowed;#1;
 end endtask
 initial begin
 repeat(3)@(negedge clk);rst=1;face={2'b10,8'd30,7'd20,7'd32,8'd9};
 @(negedge clk);sof=1;@(negedge clk);sof=0;force dut.capture=0;
 result(2);result(1);if(status[1:0]!=1)$fatal(1,"Preferred strong HAPPY onset changed");
 result(2);result(2);result(2);if(status[1:0]!=1)$fatal(1,"Short neutral run broke smile");
 result(1);result(2);result(2);result(2);result(2);if(status[1:0]!=2)$fatal(1,"Stale HAPPY did not release after four neutral observations");
 result(1);result(3);if(status[1:0]!=1)$fatal(1,"Single tense glitch committed");
 result(3);if(status[1:0]!=3)$fatal(1,"NERVOUS did not preempt HAPPY on second fresh result");
 result(1);if(status[1:0]!=3)$fatal(1,"One HAPPY glitch preempted NERVOUS");result(1);if(status[1:0]!=1)$fatal(1,"Fresh persistent smile could not exit NERVOUS");
 face[31]=0;#1;if(status[1:0]!=0)$fatal(1,"Invalid face retained expression");
 release dut.capture;
 $display("PASS V18 PRIORITY: active action-head default, four-neutral smile release, two-fresh NERVOUS preemption, no single-glitch transitions, invalid suppression");$finish;
 end
 initial begin #100000;$fatal(1,"priority timeout");end
endmodule
