`timescale 1ns/1ps
module tb_expression_cbrow_temporal;
reg clk=0,rst=0,clear=0,fresh=0,candidate=0;reg[1:0] base=2;wire active;always #5 clk=~clk;
ext_expression_confused_overlay #(.BALANCED_POLICY(1),.STRICT_ENTRY(1)) dut(clk,rst,clear,fresh,candidate,base,active);
task obs(input c,input[1:0] b);begin @(negedge clk);candidate=c;base=b;fresh=1;@(negedge clk);fresh=0;#1;end endtask
initial begin
 repeat(3)@(negedge clk);rst=1;
 obs(1,0);obs(0,0);obs(0,0);obs(1,0);if(active)$fatal(1,"separated false spikes acquired C");
 obs(0,0);obs(0,0);obs(0,0);obs(1,0);if(active)$fatal(1,"single spike");obs(1,0);if(!active)$fatal(1,"consecutive true C");
 obs(0,0);obs(0,0);if(!active)$fatal(1,"short dropout lost C");obs(1,0);if(!active)$fatal(1,"recovery");obs(0,0);obs(0,0);obs(0,0);if(active)$fatal(1,"three misses stuck");
 obs(1,0);obs(1,0);obs(0,1);if(active)$fatal(1,"H protection lost");obs(1,3);obs(1,3);clear=1;@(negedge clk);#1;if(active)$fatal(1,"owner/quality clear failed");
 $display("PASS CBROW TEMPORAL:two consecutive C enter; separated1001 spikes cannot acquire; two misses hold/three exit, OTHER allowed and H/owner/quality clear immediate");$finish;
end
initial begin #100000;$fatal(1,"hang");end
endmodule
