`timescale 1ns/1ps
module tb_expression_v21_temporal_equivalence;
reg clk=0,rst=0,sof=0;always #5 clk=~clk;reg[31:0] face=0;wire[31:0] status,gstatus;reg[167:0] diag;reg[1:0] value;integer n,random_state=210025,ct=0;reg[31:0] rv;
ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.BALANCED_POLICY(0)) dut(clk,rst,96'd0,1'b0,sof,face,status,,,,,,);
v21_expression_capture_gold gold(clk,rst,96'd0,1'b0,sof,face,gstatus,,,,,,);
task compare;begin
 #1;if(dut.label!==gold.label || dut.pending!==gold.pending || dut.pending_count!==gold.pending_count || dut.pending_gap!==gold.pending_gap || dut.rejected_count!==gold.rejected_count || dut.stale!==gold.stale || dut.diagnostic_valid!==gold.diagnostic_valid)$fatal(1,"base temporal state changed after%0d",ct);
 if(status[31:12]!==gstatus[31:12] || status[10:2]!==gstatus[10:2])$fatal(1,"V21 ownership/quality/status changed");
 if(status[11])begin if(status[1:0]!=0 || gstatus[1:0]!=3)$fatal(1,"overlay escaped existing base R");end
 else if(status[1:0]!==gstatus[1:0])$fatal(1,"base label changed");
end endtask
task fs;begin @(negedge clk);sof=1;@(negedge clk);sof=0;compare;end endtask
task observation(input[1:0] v,input c,input[31:0] margin);begin
 @(negedge clk);value=v;diag=0;diag[167]=1;diag[135]=c;diag[31:0]=margin;
 force dut.core_diagnostic=diag;force gold.core_diagnostic=diag;force dut.result=value;force gold.result=value;force dut.done=1;force gold.done=1;force dut.result_allowed=1;force gold.result_allowed=1;
 @(negedge clk);force dut.done=0;force gold.done=0;release dut.core_diagnostic;release gold.core_diagnostic;release dut.result;release gold.result;release dut.result_allowed;release gold.result_allowed;ct=ct+1;compare;
end endtask
task wantC(input c);begin if(status[11]!==c)$fatal(1,"C overlay support expected%0d got%0d",c,status[11]);end endtask
initial begin
 repeat(3)@(negedge clk);rst=1;face={2'b10,8'd30,7'd20,7'd32,8'd9};fs;force dut.capture=0;force gold.capture=0;force dut.done=0;force gold.done=0;
 observation(2,0,4000);observation(3,1,1);wantC(0);observation(3,1,1);wantC(1);
 observation(3,0,1);wantC(1);observation(3,1,1);wantC(1);observation(3,0,1);wantC(0);
 observation(3,1,1);wantC(1);observation(1,0,4000);wantC(0);observation(1,0,4000);
 observation(2,0,1);observation(2,0,1);observation(2,0,1);observation(2,0,1);
 observation(3,1,1);wantC(0);observation(0,0,0);observation(3,1,1);wantC(0);
 for(n=0;n<4096;n=n+1)begin
  rv=$random(random_state);observation(rv[1:0],rv[2],rv[3]?32'd4000:32'd1);
  if(n%97==0)begin face[31]=0;compare;repeat(2)@(negedge clk);compare;face={2'b10,8'd30,7'd20,7'd32,8'd9};fs;end
  if(n%113==0)begin face[29:22]=90;compare;repeat(2)@(negedge clk);compare;face={2'b10,8'd30,7'd20,7'd32,8'd9};fs;end
  if(n%251==0)repeat(14)fs;
 end
 face[31]=0;repeat(2)@(negedge clk);wantC(0);compare;
 $display("PASS V21 TEMPORAL EQUIVALENCE:4096 randomized fresh sequences against original V21 capture RTL; exact label/pending/gap/reject/stale states, independent C two-of-three entry/release, isolated/rejected spike suppression, immediate H/owner/stale clear and unchanged face eligibility");$finish;
end
initial begin #10000000;$fatal(1,"hang");end
endmodule
