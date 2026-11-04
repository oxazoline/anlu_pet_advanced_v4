`timescale 1ns/1ps
module tb_expression_temporal_v20;
reg clk=0,rst=0,sof=0;always #5 clk=~clk;
reg[31:0] face=0;wire[31:0] status;reg[167:0] diag;
ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.BALANCED_POLICY(0)) dut(clk,rst,96'd0,1'b0,sof,face,status,,,,,,);
task fs;begin @(negedge clk);sof=1;@(negedge clk);sof=0;#1;end endtask
task observation(input[1:0] value,input[31:0] margin);begin
 @(negedge clk);diag=0;diag[167]=1;diag[31:0]=margin;
 force dut.core_diagnostic=diag;force dut.done=1;force dut.result=value;force dut.result_allowed=1;
 @(negedge clk);force dut.done=0;release dut.core_diagnostic;release dut.result;release dut.result_allowed;#1;
end endtask
task expect_label(input[1:0] v);begin if(status[1:0]!==v)$fatal(1,"V20 temporal label got%0d want%0d",status[1:0],v);end endtask
task neutral;begin observation(2,4000);end endtask
initial begin
 repeat(3)@(negedge clk);rst=1;face={2'b10,8'd30,7'd20,7'd32,8'd9};fs;force dut.capture=0;force dut.done=0;
 neutral;expect_label(2);
 observation(3,1);expect_label(2);neutral;expect_label(2);observation(3,1);expect_label(3);
 neutral;expect_label(3);neutral;expect_label(3);neutral;expect_label(3);neutral;expect_label(2);
 observation(3,1);neutral;neutral;observation(3,1);expect_label(2);
 observation(0,0);observation(3,1);expect_label(2);observation(3,1);expect_label(3);
 observation(1,2304);expect_label(3);observation(1,2304);expect_label(1);
 neutral;neutral;neutral;expect_label(1);observation(1,4000);neutral;expect_label(1);
 neutral;neutral;neutral;expect_label(2);
 observation(1,2304);expect_label(1);neutral;neutral;neutral;neutral;expect_label(2);
 observation(1,1);neutral;expect_label(2);observation(1,1);expect_label(1);
 face[31]=0;#1;expect_label(0);repeat(2)@(negedge clk);
 face={2'b10,8'd30,7'd20,7'd32,8'd9};fs;neutral;expect_label(2);
 observation(3,1);face[29:22]=90;#1;expect_label(0);repeat(2)@(negedge clk);
 if(dut.pending!=0 || dut.pending_gap!=0)$fatal(1,"old owner candidate survived");
 release dut.capture;release dut.done;
 $display("PASS V20 TEMPORAL: two-of-three fresh positive evidence, four-neutral nervous release, four-consecutive smile release, rejected/gap/owner invalidation, native48 fast happy2304");$finish;
end
initial begin #100000;$fatal(1,"timeout");end
endmodule
