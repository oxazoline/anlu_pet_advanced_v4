`timescale 1ns/1ps
module tb_extension_mode_temporal;
localparam NO_C=0;reg clk=0,rst=0,sof=0;always #5 clk=~clk;reg[31:0] face=0;wire[31:0] status;wire[167:0] outdiag;reg[167:0] diag;reg[1:0] value;
ext_expression_capture dut(clk,rst,96'd0,1'b0,sof,face,status,outdiag,,,,,,);
task obs(input c,input mouth,input q);begin
 @(negedge clk);value=3;diag=0;diag[167]=1;diag[129]=1;diag[135]=c;diag[132]=mouth;diag[155]=q;diag[165:164]=2;
 force dut.core_diagnostic=diag;force dut.done=1;force dut.result=value;force dut.result_allowed=1;
 @(negedge clk);force dut.done=0;#1;
end endtask
task want(input c);begin if(status[11]!==c || (!c && status[1:0]!=3))$fatal(1,"mode temporal label mismatch C%0d R%0d",status[11],status[1:0]);end endtask
initial begin
 repeat(3)@(negedge clk);rst=1;face={2'b10,8'd30,7'd20,7'd32,8'd9};sof=1;@(negedge clk);sof=0;force dut.capture=0;force dut.done=0;
 obs(1,0,0);obs(1,0,0);want(0);obs(1,1,0);obs(1,1,0);want(!NO_C);
 obs(0,0,0);want(0);obs(1,1,0);obs(1,1,0);want(!NO_C);
 face[7]=1;#1;want(0);obs(1,1,0);obs(1,1,0);want(0);
 obs(1,1,1);obs(1,1,1);want(!NO_C);obs(0,0,1);want(0);
 if(NO_C && (dut.ENABLE_CONFUSED!=0 || dut.core.ENABLE_MOUTH!=0 || dut.core.ENABLE_CBROW!=0 || outdiag[135] || outdiag[132] || outdiag[159:152]!=0))$fatal(1,"no-C default or metadata leak");
 face=0;repeat(3)@(negedge clk);if(status[11] || status[1:0]!=0)$fatal(1,"owner loss not cleared");
 $display("PASS MODE TEMPORAL:actual defaults, mouth0 C immediately rejected/withdrawn with R fallback, weak profile cannot steal R, strong profile may confirm, owner clear; no-C metadata/runtime excludes C");$finish;
end
initial begin #1000000;$fatal(1,"hang");end
endmodule
