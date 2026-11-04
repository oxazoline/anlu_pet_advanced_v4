`timescale 1ns/1ps
// Control/ownership tests with mocked complete core results, not camera accuracy.
module tb_expression_coast_profile;
 reg clk=0,rst=0,sof=0;always #5 clk=~clk;
 reg [31:0] face=0;wire [31:0] status;wire commit;reg [167:0] diag;
 integer i;
 ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.BALANCED_POLICY(0),.ENABLE_AU(0)) dut(clk,rst,96'd0,1'b0,sof,face,status,,,,,commit,);
 task fs;begin release dut.capture;@(negedge clk);sof=1;@(negedge clk);sof=0;#1;end endtask
 task halt_capture;begin force dut.capture=0;end endtask
 task result(input [1:0] value,input [31:0] margin);
 begin
  @(negedge clk);diag=0;diag[167]=1;diag[165:164]=value==0?1:value-1;diag[163:160]=value==0?3:0;diag[31:0]=margin;
  force dut.core_diagnostic=diag;force dut.done=1;force dut.result=value;force dut.result_allowed=1;
  @(negedge clk);force dut.done=0;release dut.core_diagnostic;release dut.result;release dut.result_allowed;#1;
 end endtask
 initial begin
  repeat(3)@(negedge clk);rst=1;force dut.start=0;force dut.done=0;
  // A visible H/P box with no preceding detection support must not bootstrap.
  @(posedge clk);face<={1'b1,1'b0,8'd30,7'd20,7'd32,8'h80};
  fs;if(dut.capture || status[6])$fatal(1,"unsupported initial profile bootstrapped capture");
  halt_capture;result(2,4000);if(status[1:0]!=0 || commit)$fatal(1,"unsupported result became a label");
  // Fresh support owns the patch. Neither profile entry nor pose change suppresses
  // a valid actual class; model quality/rejection still governs result acceptance.
  @(posedge clk);face[6:0]<=6;
  fs;if(!dut.capture || !status[6] || !status[5] || !status[4])$fatal(1,"supported profile cannot capture");
  halt_capture;result(2,4000);if(status[1:0]!=2 || !status[8])$fatal(1,"profile neutral hidden");
  result(1,32'h7fffffff);if(status[1:0]!=1)$fatal(1,"profile smile hidden or defaulted");
  result(3,4000);result(3,4000);if(status[1:0]!=3)$fatal(1,"profile tension hidden");
  // Nine unsupported SOFs remain eligible and permit a new capture each frame.
  // Repeated classifier outputs cannot reset the independent coast age.
  @(posedge clk);face[6:0]<=0;
  for(i=1;i<=9;i=i+1)begin
   fs;if(!dut.capture || !status[6] || dut.coast_age!=i)$fatal(1,"coast capture/age mismatch frame=%0d age=%0d",i,dut.coast_age);
   halt_capture;result(2,4000);if(dut.coast_age!=i || status[1:0]==0)$fatal(1,"classifier refreshed coast age or lost accepted profile");
  end
  force dut.busy=1;fs;repeat(2)@(negedge clk);halt_capture;
  if(status[6] || status[1:0]!=0 || status[8] || status[15:12]!=10 || dut.result_allowed)$fatal(1,"coast exceeded ten SOFs");
  // Late old core completion after support resumes, but before a new completed
  // patch, must stay invalid: result_allowed was cleared at expiry.
  @(posedge clk);face[6:0]<=6;
  @(negedge clk);force dut.done=1;force dut.result=2;#1;if(commit)$fatal(1,"old expired patch committed after support return");
  @(negedge clk);force dut.done=0;release dut.result;
  if(status[1:0]!=0 || status[8])$fatal(1,"late old result leaked after expiry");
  release dut.busy;fs;if(!dut.capture)$fatal(1,"fresh support did not restart capture");
  halt_capture;result(2,4000);if(status[1:0]!=2)$fatal(1,"fresh owned neutral did not recover");
  // A foreign unsupported ROI invalidates the old owner immediately and cannot
  // reacquire a coast episode merely by returning to the old coordinates.
  @(posedge clk);face<={1'b1,1'b0,8'd100,7'd20,7'd32,8'h80};
  #1;if(status[1:0]!=0 || status[8] || status[5] || status[15:12]!=15)$fatal(1,"ROI jump status incoherent");
  repeat(3)@(negedge clk);
  if(status[6] || dut.coast_supported || dut.pending!=0)$fatal(1,"foreign H retained support or pending result");
  @(posedge clk);face<={1'b1,1'b0,8'd30,7'd20,7'd32,8'h80};
  fs;if(status[6] || dut.capture || status[1:0]!=0)$fatal(1,"return to old coordinates resurrected unsupported label");
  // Evidence can recover, but removal immediately clears label and evidence.
  @(posedge clk);face[6:0]<=6;
  fs;halt_capture;result(2,4000);
  @(posedge clk);face[31]<=0;
  #1;if(status[1:0]!=0 || status[8] || status[15:12]!=8)$fatal(1,"face removal did not immediately clear output");
  repeat(3)@(negedge clk);@(posedge clk);face<={1'b1,1'b0,8'd30,7'd20,7'd32,8'h80};
  fs;if(status[6] || dut.capture)$fatal(1,"new unsupported face inherited old lifetime");
  // The pre-existing 13-SOF no-classifier-result expiry also remains independent
  // of positive detector support and prevents indefinitely held stale labels.
  @(posedge clk);face[6:0]<=6;
  fs;halt_capture;result(2,4000);
  for(i=0;i<12;i=i+1)begin fs;halt_capture;end
  if(status[1:0]!=2)$fatal(1,"class result stale expiry early");
  fs;halt_capture;
  if(status[1:0]!=0 || status[8] || status[15:12]!=12)$fatal(1,"stale accepted result remained forever");
  @(posedge clk);face<={1'b1,1'b0,8'd100,7'd20,7'd32,8'h80};
  repeat(3)@(negedge clk);
  if(status[6] || dut.coast_supported)$fatal(1,"inactive stale owner allowed unsupported foreign coast");
  $display("PASS EXPRESSION COAST PROFILE: supported P captures/classes without default, unsupported initial P blocked, H/P captures through nine SOFs, tenth expires despite classifier updates, late result/foreign ROI/removal cannot resurrect lifetime, independent stale-result expiry, coherent eligibility/owner/profile/RS flags");
  $finish;
 end
 initial begin #200000;$fatal(1,"coast/profile control timeout");end
endmodule
