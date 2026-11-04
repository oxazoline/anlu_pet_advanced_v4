`timescale 1ns/1ps
module tb_advanced_v2_track;
reg clk=0,rst=0,done=0,keep=0,high_conf=0;reg[31:0]b=0;wire[31:0]out;
always #5 clk=~clk;
adv_stable_track #(.MAX_AGE(100),.MISS_LIMIT(6)) dut(clk,rst,done,b,keep,high_conf,out);
task evidence(input integer positive,input integer x);begin
 @(negedge clk);b={positive[0],1'b0,x[7:0],7'd15,8'd20,7'd40};done=1;
 @(negedge clk);done=0;@(negedge clk);end endtask
integer i;
initial begin
 repeat(3)@(negedge clk);rst=1;evidence(1,20);if(out[31])$fatal(1,"weak first hit");
 evidence(0,20);evidence(1,20);if(!out[31])$fatal(1,"two of three acquisition");
 for(i=0;i<5;i=i+1)evidence(0,20);if(!out[31])$fatal(1,"short misses flicker");
 keep=1;evidence(0,21);keep=0;if(!out[31] || out[29:22]!=20)$fatal(1,"hysteresis or coordinate deadband");
 evidence(1,24);if(out[29:22]!=22)$fatal(1,"position damping");
 evidence(1,90);if(out[29:22]!=22)$fatal(1,"one outlier jumps track");
 evidence(1,91);if(out[29:22]!=91)$fatal(1,"repeated distant target not acquired");
 for(i=0;i<6;i=i+1)evidence(0,91);if(out[31])$fatal(1,"withdrawal unbounded");
 high_conf=1;evidence(1,30);high_conf=0;if(!out[31])$fatal(1,"high_conf one-frame acquisition");
 repeat(101)@(negedge clk);if(out[31])$fatal(1,"stopped camera stale track");
 $display("PASS ADVANCED V2 TRACK: two of three/high_conf acquisition, six-miss withdrawal, score hysteresis, jitter deadband/damping, isolated jump rejection, reacquisition and age cap");$finish;
end
endmodule
