`timescale 1ns/1ps
module tb_face_scale_anchor_v16;
reg clk=0,rst=0,done=0,found=1,tmo=0;always #5 clk=~clk;
reg[7:0] x=40,votes=7;reg[6:0] y=10,w=60;wire[31:0] status;
ext_face_track #(.HOLD_CYCLES(300),.ACQUIRE_CYCLES(1000)) dut(clk,rst,done,found,tmo,x,y,w,votes,status);
task result(input[7:0] bx,input[6:0] by,input[6:0] size,input[7:0] support);begin
 @(negedge clk);x=bx;y=by;w=size;votes=support;done=1;
 @(negedge clk);done=0;
end endtask
task reset;begin rst=0;found=1;tmo=0;repeat(3)@(negedge clk);rst=1;end endtask
task acquire;begin result(40,10,60,7);result(40,10,60,7);result(40,10,60,7);if(!status[31])$fatal(1,"acquisition changed");end endtask
integer i;integer prior_age;
initial begin
 reset;acquire;
 // A stable, strong upper-face cluster must not be promoted on its third hit.
 for(i=0;i<3;i=i+1)begin
  result(55,12,30,7);
  if(!status[31] || status[14:8]!=60 || status[6:0]!=0)$fatal(1,"strong upper lens cluster shrank/refreshed face");
 end
 result(55,12,30,7);if(status[31])$fatal(1,"upper lens evidence extended lifetime");
 // Incremental upper-face shrinking is individually below the old sudden
 // shrink threshold; a stable scale/position anchor stops cumulative collapse.
 reset;acquire;
 result(42,10,56,7);result(44,10,52,7);result(46,10,48,7);result(48,10,44,7);
 if(!status[31] || dut.anchor_w!=60 || status[14:8]!=47)$fatal(1,"stable anchor drifted with incremental upper shrink");
 for(i=0;i<3;i=i+1)begin
  result(50,10,40,7);if(!status[31] || status[14:8]!=47 || status[6:0]!=0)$fatal(1,"gradual upper collapse bypassed anchor");
 end
 result(50,10,40,7);if(status[31])$fatal(1,"gradual collapse retained stale face");
 // The very same sizes at a fixed face center are ordinary retreat. They
 // remain continuously visible and may rebase the anchor after a large retreat.
 reset;acquire;
 result(42,12,56,7);result(44,14,52,7);result(46,16,48,7);result(48,18,44,7);
 result(50,20,40,7);result(52,22,36,7);result(54,24,32,7);result(56,26,28,7);result(58,28,24,7);
 if(!status[31] || status[6:0]!=7 || status[14:8]!=27 || dut.anchor_w!=24)$fatal(1,"legitimate same-center retreat interrupted");
 // Known geometry ambiguity: a real frontal retreat that simultaneously
 // moves towards the top of the old face can look identical to lens collapse.
 // Do not relax the guard for this fixture. It must clear boundedly and permit
 // ordinary acquisition at the new size, never hold or lock the old geometry.
 reset;
 result(40,12,60,7);result(40,12,60,7);result(40,12,60,7);
 result(43,12,54,7);result(46,12,48,7);
 if(!status[31] || status[14:8]!=52)$fatal(1,"ambiguous retreat setup");
 prior_age=dut.age;
 for(i=0;i<3;i=i+1)begin
  result(49,12,42,7);
  if(!status[31] || status[14:8]!=52 || status[6:0]!=0 || dut.age<=prior_age)$fatal(1,"ambiguous retreat refreshed or collapsed old track");
  prior_age=dut.age;
 end
 result(49,12,42,7);if(status[31])$fatal(1,"ambiguous retreat not cleared within four unsupported rounds");
 result(49,12,42,7);if(status[31])$fatal(1,"ambiguous retreat reacquired from one observation");
 result(49,12,42,7);if(status[31])$fatal(1,"ambiguous retreat reacquired from two observations");
 result(49,12,42,7);
 if(!status[31] || status[14:8]!=42 || dut.anchor_w!=42 || status[6:0]!=7)$fatal(1,"ambiguous retreat permanently locked old anchor");
 // Confirmed profile support may shift upward and shrink; geometry alone must
 // not force a profile to keep the frontal anchor dimensions.
 reset;acquire;
 result(44,10,52,8'h87);result(48,10,44,8'h87);result(52,10,36,8'h87);
 if(!status[31] || !status[7] || status[14:8]!=43)$fatal(1,"frontal-to-profile scale reduction suppressed");
 result(55,10,30,8'h87);result(55,10,30,8'h87);result(55,10,30,8'h87);
 if(!status[31] || !status[7] || status[14:8]!=30)$fatal(1,"confirmed profile sudden shrink failed original confirmation");
 // A large real centered retreat keeps the original three-hit policy.
 reset;acquire;
 result(55,25,30,7);result(55,25,30,7);if(status[14:8]!=60)$fatal(1,"abrupt retreat skipped confirmation");
 result(55,25,30,7);if(!status[31] || status[14:8]!=30)$fatal(1,"centered abrupt retreat not confirmed");
 // Rejected geometry cannot defeat the absolute deadline without more results.
 reset;acquire;result(55,12,30,7);repeat(301)@(negedge clk);
 if(status[31])$fatal(1,"geometry rejection defeated absolute expiry");
 // Existing entry behavior is still available after bounded loss.
 acquire;if(!status[31] || status[14:8]!=60)$fatal(1,"reacquisition after expiry");
 tmo=1;result(40,10,60,7);if(status[31] || !status[30])$fatal(1,"timeout clearing changed");
 $display("PASS V16 SCALE ANCHOR: strong upper-only and gradual collapse rejected; bounded rounds/absolute expiry; centered retreat/profile shrink preserved; upward-retreat ambiguity clears and reacquires without stale hold");$finish;
end
initial begin #100000;$fatal(1,"timeout");end
endmodule
