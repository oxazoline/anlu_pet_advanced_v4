`timescale 1ns/1ps
module tb_advanced_v2_axis;
reg clk=0,rst=0,start=0,valid=0,last=0;reg[7:0]i=0,v=0;wire ok;wire[7:0]lo,hi;
always #5 clk=~clk;
adv_axis_select dut(clk,rst,start,valid,last,i,v,8'd3,8'd2,8'd6,ok,lo,hi);
integer n;
initial begin repeat(3)@(negedge clk);rst=1;start=1;@(negedge clk);start=0;valid=1;
 for(n=0;n<160;n=n+1)begin i=n;v=(n>=30 && n<=47 && n!=38)?20:(n==4 || n==95)?1:0;@(negedge clk);end
 last=1;@(negedge clk);valid=0;repeat(3)@(negedge clk);
 if(!ok || lo!=30 || hi!=47)$fatal(1,"skin speckles enlarged projection candidate");
 $display("PASS ADVANCED V2 AXIS: supported run bridges short gaps and rejects isolated distant skin evidence");$finish;end
endmodule
