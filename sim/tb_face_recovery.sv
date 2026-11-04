`timescale 1ns/1ps

module tb_face_recovery;
 reg clk=0,rst=0,sof=0;always #5 clk=~clk;wire [31:0] status;
 ext_face_detector #(.RECOVERY_CYCLES(200)) dut(clk,rst,96'd0,1'b0,sof,status);
 reg hit=0;reg [7:0] support=9,bx=45;reg [6:0] by=20,bw=30;
 task fs;begin @(negedge clk);sof=1;@(negedge clk);sof=0;end endtask
 task result(input bit f);begin
  @(negedge clk);hit=f;force dut.done=1;@(negedge clk);force dut.done=0;
  repeat(2)@(negedge clk);
 end endtask
 task acquire;begin
  result(1);result(1);if(status[31])$fatal(1,"entry threshold weakened");
  result(1);if(!status[31])$fatal(1,"strong acquisition failed");
 end endtask
 initial begin
  repeat(3)@(negedge clk);rst=1;
  force dut.busy=0;force dut.start=0;force dut.done=0;force dut.found=hit;force dut.timeout=0;
  force dut.mapped_x=bx;force dut.mapped_y=by;force dut.mapped_size=bw;force dut.neighbors=support;
  acquire;
  result(0);
  force dut.refresh=0;#1;
  if(!status[31] || !dut.scan_hint[31])$fatal(1,"periodic refresh discarded coasting ROI");
  release dut.refresh;
  result(0);result(0);result(0);
  if(status[31] || !dut.using_recovery || dut.global_hint[7:0]!=0)$fatal(1,"lost ROI not retained as hidden zero-support memory");
  if(!dut.choose_zoom)$fatal(1,"recovery lost small-face detail");
  fs;if(!dut.recovery_scan || !dut.scan_hint[31])$fatal(1,"first recovery missing");result(0);
  fs;if(!dut.recovery_scan)$fatal(1,"second recovery missing");result(0);
  if(dut.using_recovery || dut.global_hint[31] || status[31])$fatal(1,"failed recovery trapped search or fabricated a box");
  fs;if(dut.recovery_scan)$fatal(1,"third stale ROI retry");
  // Actual tracker confirmations are still required after loss.
  acquire;
  result(0);result(0);result(0);result(0);
  repeat(201)@(negedge clk);
  if(dut.using_recovery || dut.global_hint[31] || status[31])$fatal(1,"absolute recovery expiry failed");
  bx=72;by=28;bw=24;support=8;result(1);
  if(dut.global_hint[29:22]!=72 || status[31])$fatal(1,"pending candidate priority or three-hit entry violated");
  rst=0;repeat(3)@(negedge clk);
  if(dut.recovery_hint || dut.using_recovery || status[31])$fatal(1,"reset");
  $display("PASS FACE RECOVERY: real tracker integration, three fresh strong hits still required, hidden recent ROI, no periodic hint drop during coast, two-attempt bound, absolute expiry without done, restored zoom and no stale green boxes");$finish;
 end
 initial begin #200000;$fatal(1,"timeout");end
endmodule
