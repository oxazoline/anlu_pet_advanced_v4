`timescale 1ns/1ps
module tb_face_wide_refresh;
 reg clk=0,rst=0,sof=0;always #5 clk=~clk;wire [31:0] status;
 ext_face_detector dut(clk,rst,96'd0,1'b0,sof,status);
 task fs;begin @(negedge clk);sof=1;@(negedge clk);sof=0;#1;end endtask
 initial begin
  repeat(3)@(negedge clk);rst=1;
  force dut.busy=0;force dut.start=0;force dut.phase=0;
  force dut.O_status={1'b1,1'b0,8'd60,7'd25,7'd24,8'd6};force dut.refresh=7;
  #1;if(!dut.choose_zoom || !dut.request_wide)$fatal(1,"small-box seed");
  fs;if(dut.zoom || !dut.wide_scan || dut.scan_hint!=0)$fatal(1,"refresh remained trapped in zoom/hint");
  force dut.refresh=0;#1;if(dut.scan_hint!=0)$fatal(1,"refresh hint changed mid-capture");
  fs;if(!dut.zoom || dut.wide_scan)$fatal(1,"normal small-face detail not restored");
  // Pending acquisition is never interrupted by the periodic refresh.
  force dut.O_status=0;force dut.pending_hint={1'b1,1'b0,8'd60,7'd25,7'd24,8'd6};force dut.refresh=7;
  fs;if(!dut.zoom || dut.wide_scan || dut.scan_hint==0)$fatal(1,"fresh confirmation sequence interrupted");
  force dut.O_status={1'b1,1'b0,8'd50,7'd20,7'd24,8'd6};
  force dut.zoom=0;force dut.wide_scan=1;force dut.done=1;force dut.found=1;force dut.timeout=0;
  force dut.box_x=35;force dut.box_y=5;force dut.box_size=56;force dut.neighbors=6;
  @(negedge clk);force dut.done=0;#1;
  if(dut.relocate_left!=2 || dut.global_hint[14:8]!=56)$fatal(1,"enclosing wide result did not seed bounded retry");
  release dut.wide_scan;release dut.zoom;force dut.refresh=1;fs;
  if(dut.zoom || dut.scan_hint[14:8]!=56)$fatal(1,"enclosing confirmation trapped in old local ROI");
  force dut.done=1;@(negedge clk);force dut.done=0;#1;if(dut.relocate_left!=1)$fatal(1,"retry budget one");
  force dut.done=1;@(negedge clk);force dut.done=0;#1;if(dut.relocate_left!=0)$fatal(1,"retry budget exhausted");
  $display("PASS FACE WIDE REFRESH: tracked small ROI periodically forces full field plus zero hint, capture-latched hint survives refresh wrap, next capture restores zoom and pending acquisition remains uninterrupted");$finish;
 end
 initial begin #10000;$fatal(1,"timeout");end
endmodule
