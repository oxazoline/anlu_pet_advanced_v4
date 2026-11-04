`timescale 1ns/1ps
module tb_face_large_policy;
 reg clk=0,rst=0,sof=0;always #5 clk=~clk;wire[31:0] status;
 ext_face_detector dut(clk,rst,96'd0,1'b0,sof,status);
 task fs;begin @(negedge clk);sof=1;@(negedge clk);sof=0;#1;end endtask
 task empty;begin force dut.done=1;@(negedge clk);force dut.done=0;#1;end endtask
 initial begin
  repeat(3)@(negedge clk);rst=1;force dut.busy=0;force dut.start=0;force dut.phase=0;force dut.O_status=0;force dut.pending_hint=0;force dut.found=0;force dut.timeout=0;
  empty;if(dut.prefer_large)$fatal(1,"one miss changed discovery");empty;if(!dut.prefer_large)$fatal(1,"two empty scans did not try near mode");
  fs;if(!dut.large_scan || dut.zoom || dut.scan_hint[31:30]!=2'b01)$fatal(1,"discovery near field flag/hint");
  force dut.box_x=20;force dut.box_y=5;force dut.box_size=114;#1;
  if(dut.mapped_size!=88 || dut.mapped_x!=33 || dut.mapped_y!=0)$fatal(1,"large clipping/center");
  force dut.box_y=56;force dut.box_size=72;#1;if(dut.mapped_y!=18 || dut.mapped_size!=72)$fatal(1,"bottom clipping");
  release dut.box_x;release dut.box_y;release dut.box_size;
  force dut.O_status={1'b1,1'b0,8'd50,7'd20,7'd24,8'd6};force dut.refresh=7;fs;
  if(!dut.wide_scan || dut.large_scan || dut.scan_hint!=0)$fatal(1,"first wide refresh not baseline full view");
  force dut.refresh=1;fs;force dut.refresh=7;fs;
  if(!dut.wide_scan || !dut.large_scan || dut.zoom || dut.scan_hint[31:30]!=2'b01)$fatal(1,"second wide refresh did not search cropped large face globally");
  force dut.O_status=0;force dut.pending_hint={1'b1,1'b0,8'd30,7'd0,7'd88,8'd6};force dut.last_large=1;force dut.refresh=1;fs;
  if(!dut.large_scan || dut.scan_hint[31:30]!=2'b11 || dut.scan_hint[21:15]!=19)$fatal(1,"tracked near hint conversion");
  $display("PASS FACE LARGE POLICY: bounded empty-scan discovery, native full field, virtual hint conversion, clipped ROI centers/borders, alternating baseline/near wide refresh and retained strong near confirmation");$finish;
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
