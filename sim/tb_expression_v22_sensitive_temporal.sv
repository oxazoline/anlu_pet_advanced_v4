`timescale 1ns/1ps
module tb_expression_v22_sensitive_temporal;
reg clk=0,rst=0,sof=0;always #5 clk=~clk;reg[31:0] face=0;wire[31:0] status;reg[167:0] diag;reg[1:0] value;integer j;
ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1)) dut(clk,rst,96'd0,1'b0,sof,face,status,,,,,,);
task obs(input[1:0] v,input integer margin);begin
 @(negedge clk);value=v;diag=0;diag[167]=1;diag[129]=1;diag[31:0]=margin;diag[165:164]=v-1;
 force dut.core_diagnostic=diag;force dut.done=1;force dut.result=value;force dut.result_allowed=1;
 @(negedge clk);force dut.done=0;#1;
end endtask
task want(input[1:0] v);begin if(status[1:0]!==v)$fatal(1,"V22 temporal got%0d want%0d",status[1:0],v);end endtask
task n;begin obs(2,4000);end endtask
initial begin
 repeat(3)@(negedge clk);rst=1;face={2'b10,8'd30,7'd20,7'd32,8'd9};sof=1;@(negedge clk);sof=0;force dut.capture=0;force dut.done=0;
 n;want(2);obs(3,1);want(2);n;obs(3,1);want(3);
 for(j=0;j<8;j=j+1)begin n;obs(3,1);want(3);end
 n;n;n;want(3);n;want(2);
 obs(1,2187);want(2);n;n;want(2);obs(1,2188);want(1);
 n;n;n;want(1);n;want(2);
 force dut.low_res=1;obs(1,2431);want(2);n;n;obs(1,2432);want(1);release dut.low_res;
 n;n;n;n;obs(3,1);obs(3,1);want(3);obs(1,5000);want(3);obs(1,5000);want(1);
 face=0;repeat(2)@(negedge clk);want(0);
 if(dut.V22_POLICY!=1 || dut.core.V22_POLICY!=1)$fatal(1,"production V22 policy disconnected");
 $display("PASS V22 SENSITIVE TEMPORAL:actual production defaults V22 two-of3 H/R and four consecutive N release; fast H2188/native and2432/low exact boundaries, retained R-to-H two updates, no single-spike acquisition, owner loss clears");$finish;
end
initial begin #1000000;$fatal(1,"hang");end
endmodule
