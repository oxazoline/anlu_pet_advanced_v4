`timescale 1ns/1ps
module tb_face_maintenance;
 reg clk=0,rst=0,start=0;always #5 clk=~clk;
 wire busy,done,found,timeout;wire [7:0] x,votes;wire [6:0] y,size;wire [13:0] addr;
 wire [31:0] status;reg [31:0] hint=0;
 reg [7:0] strength=7;reg profile_only=1;
 wire [7:0] supported=(profile_only ? dut.model_pass==3 : dut.model_pass==0)?strength:0;
 ext_face_lbp #(.WIDTH(40),.HEIGHT(36),.MAX_CYCLES(1000000)) dut(clk,rst,start,busy,done,found,timeout,x,y,size,votes,addr,22'd0,hint);
 ext_face_track #(.HOLD_CYCLES(1000000),.ACQUIRE_CYCLES(1000000)) track(clk,rst,done,found,timeout,x,y,size,votes,status);
 task scan;integer cycles;begin
  @(negedge clk);start=1;@(negedge clk);start=0;cycles=0;
  while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>1000000)$fatal(1,"scan hang");end
  repeat(2)@(negedge clk);
 end endtask
 initial begin
  repeat(3)@(negedge clk);rst=1;
  force dut.observed_count=supported;force dut.result_x=8'd20;force dut.result_y=8'd18;force dut.result_w=8'd24;
  // Policy injection only; image-based cascade tests are separate.
  force dut.use_local=0;
  scan;if(status[31])$fatal(1,"one-hit entry");hint={1'b1,1'b0,x,y,size,votes};
  force dut.use_local=1;
  scan;if(status[31])$fatal(1,"two-hit entry");scan;
  if(!status[31] || !status[7] || dut.remembered_pass!=3)$fatal(1,"profile acquisition");
  // Exact failing V8 condition: old profile, no current support, local frontal2.
  hint={status[31:8],8'd0};profile_only=0;strength=2;
  scan;
  if(!found || !status[31] || status[6:0]!=2 || !status[7] || dut.remembered_pass!=3 || (!dut.weak_probe_active || !dut.use_weak_fallback))$fatal(1,"lost usable frontal maintenance evidence or prematurely changed pose");
  // Strong frontal is allowed to clear the conservative pose marker.
  strength=7;scan;
  if(!status[31] || status[7] || dut.remembered_pass!=0)$fatal(1,"strong frontal did not qualify pose");
  // No stale profile may survive reset; weak evidence cannot acquire a new box.
  rst=0;repeat(3)@(negedge clk);rst=1;hint=0;strength=2;force dut.use_local=0;
  scan;scan;scan;if(status[31])$fatal(1,"weak global evidence fabricated entry");
  release dut.use_local;release dut.observed_count;release dut.result_x;release dut.result_y;release dut.result_w;
  $display("PASS FACE MAINTENANCE: V8 counterexample fixed, actual tracker accepts local frontal2, pose remains conservative until frontal7, three-hit strict entry and no weak global acquisition");$finish;
 end
 initial begin #20000000;$fatal(1,"test timeout");end
endmodule
