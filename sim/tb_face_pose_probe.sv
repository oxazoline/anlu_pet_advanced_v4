`timescale 1ns/1ps
module tb_face_pose_probe;
reg clk=0,rst=0,start=0;always #5 clk=~clk;
reg[31:0] hint={1'b1,1'b0,8'd6,7'd6,7'd24,8'd7};wire busy,done,found,tmo;wire[7:0] x,v;wire[6:0] y,w;wire[13:0] a;
reg[7:0] frontal=3,side=7;wire[7:0] evidence=dut.model_pass==0?frontal:side;
wire local_evidence=!dut.weak_probe_active || side>=2;
ext_face_lbp #(.WIDTH(40),.HEIGHT(36),.MAX_CYCLES(1000000)) dut(clk,rst,start,busy,done,found,tmo,x,y,w,v,a,22'd0,hint);
integer cycles,probed;
task scan;begin
 @(negedge clk);start=1;@(negedge clk);start=0;cycles=0;probed=0;
 while(!done)begin if(dut.weak_probe_active)probed=1;@(negedge clk);cycles=cycles+1;if(cycles>1000000)$fatal(1,"hang");end
 @(negedge clk);if(tmo)$fatal(1,"probe exhausted watchdog");
end endtask
initial begin
 repeat(3)@(negedge clk);rst=1;
 force dut.observed_count=evidence;force dut.use_local=local_evidence;
 force dut.local_x=8'd18;force dut.local_y=8'd18;force dut.local_w=8'd24;
 scan;if(!found || v!=135 || !probed || dut.remembered_pass!=1)$fatal(1,"weak frontal starved fresh strong profile");
 // Force frontal-first recovery, then no profile: saved weak frontal must survive.
 hint[7:0]=0;side=0;scan;
 if(!found || v!=131 || !probed || x!=6 || y!=6 || w!=24 || !dut.use_weak_fallback)$fatal(1,"bounded probe lost saved geometry/conservative pose");
 // Two-vote frontal fallback must survive even with no local profile group.
 frontal=2;scan;if(!found || v!=130 || !probed || !dut.use_weak_fallback || dut.use_local)$fatal(1,"empty probe dropped saved two-vote maintenance");
 // Strong frontal should complete directly and clear old profile marker.
 frontal=7;scan;if(!found || v!=7 || probed || dut.remembered_pass!=0)$fatal(1,"frontal return regression");
 // Global weak profiles are observations only; separate tracker requires five.
 hint=0;frontal=0;side=3;force dut.use_local=0;
 scan;if(!found || v!=131)$fatal(1,"weak global profile observation not published");
 release dut.observed_count;release dut.use_local;release dut.local_x;release dut.local_y;release dut.local_w;
 $display("PASS POSE PROBE: weak frontal cannot starve a stronger profile, one bounded probe preserves saved geometry, no strong frontal delay, global weak profile observation");$finish;
end
initial begin #40000000;$fatal(1,"timeout");end
endmodule
