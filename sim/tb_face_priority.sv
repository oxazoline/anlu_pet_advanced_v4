`timescale 1ns/1ps

module tb_face_priority;
 reg clk=0,rst=0,start=0;always #5 clk=~clk;reg [31:0] hint=0;
 wire busy,done,found,timeout;wire [7:0] x,votes;wire [6:0] y,size;wire [13:0] addr;
 ext_face_lbp #(.WIDTH(40),.HEIGHT(36),.MAX_CYCLES(1000000)) dut(clk,rst,start,busy,done,found,timeout,x,y,size,votes,addr,22'd0,hint);
 integer round,rank_seen,expected,c,mask,pref;
 task begin_scan;begin @(negedge clk);start=1;@(negedge clk);start=0;end endtask
 initial begin
  repeat(3)@(negedge clk);rst=1;force dut.observed_count=8'd0;
  for(round=0;round<8;round=round+1)begin
   pref=(round%4)+1;begin_scan;rank_seen=-1;c=0;mask=0;
   while(!done)begin
    if(dut.pass_rank!=rank_seen)begin
     rank_seen=dut.pass_rank;
     if(rank_seen==0)expected=0;else if(rank_seen==1)expected=pref;
     else if(rank_seen<=pref)expected=rank_seen-1;else expected=rank_seen;
     if(dut.model_pass!=expected || (mask&(1<<expected)))$fatal(1,"global frontal-first/order round=%0d rank=%0d got=%0d expected=%0d",round,rank_seen,dut.model_pass,expected);
     mask=mask|(1<<expected);
    end
    @(negedge clk);c=c+1;if(c>1000000)$fatal(1,"priority timeout");
   end
   if(timeout || found || mask!=31)$fatal(1,"not all five passes completed");
   repeat(2)@(negedge clk);
  end
  // Scheduling injection; actual-cascade scores are checked in separate tests.
  begin_scan;wait(dut.state==13 && dut.model_pass==2);@(negedge clk);
  force dut.observed_count=8'd7;force dut.result_x=8'd20;force dut.result_y=8'd18;force dut.result_w=8'd24;
  wait(done);@(negedge clk);
  if(!found || !votes[7] || dut.remembered_pass!=2)$fatal(1,"profile direction not remembered");
  hint={1'b1,1'b0,x,y,size,votes};
  begin_scan;if(dut.model_pass!=2)$fatal(1,"fresh profile lost priority");
  wait(done);@(negedge clk);
  begin_scan;if(dut.model_pass!=0)$fatal(1,"two-round frontal probe absent");
  force dut.use_local=1'b1;force dut.observed_count=8'd2;
  wait(done);@(negedge clk);
  if(!found || votes!=130 || dut.remembered_pass!=2 || (!dut.weak_probe_active || !dut.use_weak_fallback))$fatal(1,"weak frontal must maintain geometry without declaring confident frontal pose");
  release dut.use_local;force dut.observed_count=8'd7;
  hint[7:0]=0;begin_scan;
  if(dut.model_pass!=0)$fatal(1,"unsupported target not immediately frontal-first");
  wait(done);@(negedge clk);
  if(votes[7] || dut.remembered_pass!=0)$fatal(1,"frontal return stayed profile-locked");
  hint=0;begin_scan;if(dut.model_pass!=0)$fatal(1,"reentry delayed by profile pass");
  wait(done);@(negedge clk);
  release dut.observed_count;release dut.result_x;release dut.result_y;release dut.result_w;
  rst=0;repeat(2)@(negedge clk);if(dut.search_priority!=1 || dut.remembered_pass!=0)$fatal(1,"priority reset");
  $display("PASS FACE PRIORITY V9: all global starts frontal-first, four unique rotating profile fallbacks, profile priority, two-round frontal probe, weak local maintenance with conservative pose, immediate frontal recovery");$finish;
 end
 initial begin #40000000;$fatal(1,"timeout");end
endmodule
