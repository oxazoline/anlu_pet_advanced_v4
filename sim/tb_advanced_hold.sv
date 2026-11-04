`timescale 1ns/1ps
module tb_advanced_hold;
reg clk=0,rst=0,done=0;reg [31:0] box=0;wire [31:0] out;
always #5 clk=~clk;adv_target_hold #(.MAX_AGE(50))dut(clk,rst,done,box,out);
task result(input bit found);begin @(negedge clk);done=1;box={found,1'b0,8'd20,7'd12,8'd30,7'd40};@(negedge clk);done=0;end endtask
initial begin repeat(3)@(negedge clk);rst=1;result(1);if(out[31])$fatal(1,"one hit acquired");result(1);if(!out[31])$fatal(1,"two hits failed");
 result(0);result(0);if(!out[31])$fatal(1,"early withdrawal");result(0);if(out[31])$fatal(1,"stale held");
 result(1);result(1);repeat(52)@(negedge clk);if(out[31])$fatal(1,"no-camera timeout failed");
 rst=0;@(negedge clk);if(out[31])$fatal(1,"reset failed");
 $display("PASS ADVANCED HOLD: two fresh positives, three misses, bounded wall-clock age and reset");$finish;end
endmodule
