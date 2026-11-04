`timescale 1ns/1ps
module tb_advanced_ui_preserve;
reg clk=0,rst=0,vs=0,de=0;reg[31:0]face=0,status=0;wire ov,oh,od;wire[23:0]rgb;
always #5 clk=~clk;
adv_base_osd dut(clk,rst,vs,1'b0,de,24'h123456,face,status,4'd0,ov,oh,od,rgb);
task latch;begin @(negedge clk);vs=1;@(negedge clk);vs=0;repeat(3)@(negedge clk);end endtask
integer i;
initial begin repeat(3)@(negedge clk);rst=1;face={2'b10,8'd40,7'd20,7'd32,8'd9};
 for(i=1;i<4;i=i+1)begin status=i;latch;if(dut.expression[1:0]!=i)$fatal(1,"H/N/R UI label changed");end
 status=32'h00000960;latch;if(!dut.c_label)$fatal(1,"C UI removed");
 status=0;latch;if(dut.c_label)$fatal(1,"C stale");
 
 if(dut.fx!=320 || dut.fy!=160 || dut.fw!=256)$fatal(1,"face coordinate mapping");
 $display("PASS ADVANCED UI: production lite configuration retains H/N/R/C labels and face geometry while replacing legacy detailed diagnostics");$finish;end
endmodule
