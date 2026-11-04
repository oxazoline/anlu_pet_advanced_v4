`timescale 1ns/1ps
module tb_expression_roi_owner;
 reg clk=0,rst=0,sof=0;always #5 clk=~clk;reg [31:0] face=0;wire [31:0] status;wire commit;
 ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.BALANCED_POLICY(0),.ENABLE_AU(0)) dut(clk,rst,96'd0,1'b0,sof,face,status,,,,,commit,);
 task fs;begin @(negedge clk);sof=1;@(negedge clk);sof=0;#1;end endtask
 task result;begin
  @(negedge clk);force dut.done=1;force dut.result=1;force dut.result_allowed=1;
  @(negedge clk);release dut.done;release dut.result;release dut.result_allowed;#1;
 end endtask
 initial begin
  repeat(3)@(negedge clk);rst=1;face={1'b1,1'b0,8'd50,7'd20,7'd24,8'd6};fs;
  force dut.capture=0;result;result;if(status[1:0]!=1)$fatal(1,"baseline expression");release dut.capture;
  // Move to a larger enclosing face while an old patch is being inferred.
  force dut.busy=1;face={1'b1,1'b0,8'd35,7'd5,7'd56,8'd6};fs;
  if(dut.patch_face[14:8]!=24 || dut.roi_consistent || dut.diagnostic_valid || dut.pending!=0)$fatal(1,"old ROI ownership overwritten at busy SOF");
  force dut.done=1;force dut.result=1;force dut.result_allowed=1;#1;if(commit)$fatal(1,"old glasses patch published after relocalization");
  @(negedge clk);#1;if(status[1:0]!=0 || dut.diagnostic_valid)$fatal(1,"old expression accepted");
  release dut.done;release dut.result;release dut.result_allowed;release dut.busy;force dut.busy=0;
  fs;if(!dut.capture || !dut.roi_consistent || dut.patch_face[14:8]!=56)$fatal(1,"new correctly owned capture delayed");
  force dut.capture=0;result;result;if(status[1:0]!=1)$fatal(1,"new ROI failed to reconfirm");
  // Ordinary small movement inside the association bound preserves ownership.
  face={1'b1,1'b0,8'd37,7'd6,7'd55,8'd6};#1;if(!dut.roi_consistent)$fatal(1,"small box jitter discarded");
  face={1'b1,1'b0,8'd100,7'd5,7'd56,8'd6};@(negedge clk);#1;
  if(dut.diagnostic_valid || status[1:0]!=0)$fatal(1,"foreign ROI retained expression");
  $display("PASS EXPRESSION ROI OWNER: busy SOF preserves captured geometry, enlarged/foreign box invalidates old label and blocks preview commit, next idle SOF starts fresh and ordinary jitter remains valid");$finish;
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
