`timescale 1ns/1ps
module tb_advanced_v3_ref_track;
reg clk=0,rst=0,done=0,strong_hit=0;reg[31:0]full=0,local_box=0;wire[31:0]box;
always #5 clk=~clk;
adv_ref_track #(.MAX_AGE(120),.MISS_LIMIT(8)) dut(clk,rst,done,full,local_box,strong_hit,box);
task observe(input integer strict,input integer local_hit,input integer px);begin
 @(negedge clk);full={strict[0],1'b0,px[7:0],7'd20,8'd40,7'd25};local_box={local_hit[0],1'b1,px[7:0],7'd20,8'd40,7'd25};done=1;
 @(negedge clk);done=0;@(negedge clk);end endtask
integer n,last_x;
initial begin repeat(4)@(negedge clk);rst=1;strong_hit=1;observe(1,0,20);strong_hit=0;
 if(!box[31] || box[30])$fatal(1,"strong match must acquire immediately as strict");
 observe(1,0,22);if(box[29:22]!=22)$fatal(1,"strict movement is unnecessarily delayed");
 observe(0,1,23);if(!box[31] || !box[30] || box[29:22]!=23)$fatal(1,"weak local measurement did not update position");
 observe(0,0,0);if(box[29:22]!=24)$fatal(1,"first prediction");observe(0,0,0);if(box[29:22]!=25)$fatal(1,"second prediction");
 observe(0,0,0);if(box[29:22]!=25)$fatal(1,"prediction exceeded two frames");
 observe(1,0,27);if(!box[31] || box[30] || box[29:22]!=27)$fatal(1,"strict recovery failed");
 for(n=0;n<8;n=n+1)observe(0,1,28+n);if(box[31])$fatal(1,"weak evidence refreshed strict identity forever");
 observe(1,0,40);if(box[31])$fatal(1,"normal first match acquired");observe(1,0,40);if(!box[31])$fatal(1,"normal second match failed");
 repeat(121)@(negedge clk);if(box[31])$fatal(1,"stopped-result timeout");
 $display("PASS ADVANCED V3 REF TRACK: strong one-hit entry, two-hit normal entry, immediate position, measured weak tracking, flagged two-frame prediction, strict recovery, finite weak lifetime and age timeout");$finish;end
endmodule
