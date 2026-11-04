`timescale 1ns/1ps
module tb_face_profile_phase_v21;
reg clk=0,rst=0,start=0;always #5 clk=~clk;reg[31:0] hint=0;
wire busy,done,found,tmo;wire[7:0] x,v;wire[6:0] y,w;wire[13:0] addr;
ext_face_lbp #(.WIDTH(40),.HEIGHT(36),.MAX_CYCLES(1000000)) dut(clk,rst,start,busy,done,found,tmo,x,y,w,v,addr,22'd0,hint);
integer round,c,seen,pref,expected;
task launch;begin @(negedge clk);start=1;@(negedge clk);start=0;end endtask
initial begin
 repeat(3)@(negedge clk);rst=1;force dut.observed_count=0;
 for(round=0;round<8;round=round+1)begin
  launch;if(dut.profile_phase_active!=(round%4))$fatal(1,"phase not latched");
  seen=0;c=0;
  while(!done)begin
   if(dut.state==1 && dut.scale_index==0 && !(seen&(1<<dut.model_pass)))begin
    seen=seen|(1<<dut.model_pass);
    if(dut.model_pass==0)begin if(dut.wx!=0 || dut.wy!=0)$fatal(1,"frontal grid shifted");end
    else if(dut.wx!=(round%2) || dut.wy!=((round%4)/2))$fatal(1,"profile parity missing round=%0d got=%0d,%0d",round,dut.wx,dut.wy);
   end
   @(negedge clk);c=c+1;if(c>1000000)$fatal(1,"watchdog");
  end
  if(found || tmo || seen!=31 || dut.profile_phase!=((round+1)%4))$fatal(1,"failure phase advancement");
 end
 // Positive observation freezes parity; no extra dense pass is added.
 launch;wait(dut.state==13 && dut.model_pass==1);@(negedge clk);force dut.observed_count=5;
 wait(done);@(negedge clk);if(!found || dut.profile_phase!=0)$fatal(1,"success advanced phase");
 hint={1'b1,1'b0,x,y,w,v};force dut.observed_count=0;launch;wait(done);@(negedge clk);
 if(dut.profile_phase!=0)$fatal(1,"hinted failure advanced global phase");
 hint=0;launch;force dut.cycles=1000000;@(negedge clk);release dut.cycles;
 if(!done || !tmo || dut.profile_phase!=1)$fatal(1,"timeout did not advance exactly once");
 repeat(3)@(negedge clk);if(dut.profile_phase!=1)$fatal(1,"idle phase advanced");
 rst=0;repeat(2)@(negedge clk);if(dut.profile_phase!=0)$fatal(1,"reset phase");
 $display("PASS PROFILE PHASE V21: four parity grids after global misses, frontal origin unchanged, exactly five passes, successful/hinted phase retention and timeout reset");$finish;
end
initial begin #100000000;$fatal(1,"hang");end
endmodule
