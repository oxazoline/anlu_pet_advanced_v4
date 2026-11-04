`timescale 1ns/1ps
module tb_expression_balanced_temporal;
reg clk=0,rst=0,sof=0;always #5 clk=~clk;reg[31:0] face=0;wire[31:0] status;reg[167:0] diag;reg[1:0] value;integer j;
ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.V22_POLICY(0),.ENABLE_CBROW(0)) dut(clk,rst,96'd0,1'b0,sof,face,status,,,,,,);
task fs;begin @(negedge clk);sof=1;@(negedge clk);sof=0;#1;end endtask
task obs(input[1:0] v,input strong_flag,input c,input[3:0] reason,input[31:0] margin);begin
 @(negedge clk);value=v;diag=0;diag[167]=1;diag[129]=1;diag[152]=strong_flag;diag[135]=c;diag[31:0]=margin;diag[163:160]=reason;
 case(v)1:diag[165:164]=0;2:diag[165:164]=1;3:diag[165:164]=2;default:diag[165:164]=3;endcase
 force dut.core_diagnostic=diag;force dut.done=1;force dut.result=value;force dut.result_allowed=1;
 @(negedge clk);force dut.done=0;release dut.core_diagnostic;release dut.result;release dut.result_allowed;#1;
end endtask
task want(input[2:0] v);begin if({status[11],status[1:0]}!==v)$fatal(1,"responsive label got%0d want%0d",{status[11],status[1:0]},v);end endtask
task n;begin obs(2,0,0,0,4000);end endtask
initial begin
 repeat(3)@(negedge clk);rst=1;face={2'b10,8'd30,7'd20,7'd32,8'd9};fs;force dut.capture=0;force dut.done=0;
 n;want(2);
 for(j=0;j<100;j=j+1)begin obs(3,j[0],0,0,1);want(2);n;n;want(2);end
 obs(3,0,0,0,1);n;want(2);obs(3,0,0,0,1);want(3);
 n;obs(3,0,0,0,1);n;want(3);n;want(2);
 obs(3,0,0,0,1);want(2);obs(3,0,0,0,1);want(3);n;n;want(3);n;want(2);
 obs(3,1,0,0,1);obs(3,1,0,0,1);want(3);obs(1,0,0,0,4000);want(3);obs(1,0,0,0,4000);want(1);
 n;n;n;want(1);n;want(2);obs(1,0,0,0,1);n;obs(1,0,0,0,1);want(1);
 n;n;n;n;want(2);obs(1,0,0,0,2304);want(1);n;n;n;n;want(2);
 for(j=0;j<16;j=j+1)fs;want(0);
 for(j=0;j<2;j=j+1)begin obs(3,0,0,0,1);if(j==0)want(0);else want(3);repeat(4)fs;end
 n;n;n;want(2);
 obs(0,0,0,2,0);obs(0,0,0,2,0);obs(0,0,0,2,0);want(0);
 obs(0,0,1,2,0);want(0);obs(0,0,0,2,0);obs(0,0,0,2,0);want(0);obs(0,0,1,2,0);want(4);
 for(j=0;j<20;j=j+1)begin fs;obs(0,0,1,2,0);want(4);if(status[15:12]!=0 || !status[8] || dut.stale!=0 || dut.label!=0)$fatal(1,"OTHER C lost freshness or rewrote base");end
 obs(0,0,0,2,0);want(4);obs(0,0,0,2,0);want(4);obs(0,0,1,2,0);want(4);obs(0,0,0,2,0);obs(0,0,0,2,0);want(4);obs(0,0,0,2,0);want(0);
 obs(0,0,1,2,0);obs(0,0,1,2,0);want(4);obs(0,0,0,1,0);want(0);
 obs(0,0,1,2,0);obs(0,0,1,2,0);want(4);obs(1,0,0,0,4000);want(1);
 n;n;n;n;obs(0,0,0,2,0);obs(0,0,0,2,0);obs(0,0,0,2,0);obs(0,0,1,2,0);obs(0,0,1,2,0);want(4);
 face[6:0]=0;face[30]=0;for(j=0;j<9;j=j+1)begin fs;obs(0,0,1,2,0);want(4);end
 fs;want(0);obs(0,0,1,2,0);want(0);if(status[6])$fatal(1,"C refreshed detector coast");
 face=0;repeat(3)@(negedge clk);want(0);
 $display("PASS BALANCED TEMPORAL:sparse R and recovery:100 isolated R spikes rejected; R/N/R or weak RR confirmed; three-of4 neutral release, unchanged HAPPY2of3/fast/four-neutral behavior; expired weak-R reacquisition; C2of4, three misses exit; rejected OTHER freshness and independent10-SOF face expiry");$finish;
end
initial begin #1000000;$fatal(1,"hang");end
endmodule
