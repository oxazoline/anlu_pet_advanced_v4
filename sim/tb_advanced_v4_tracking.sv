`timescale 1ns/1ps
module tb_advanced_v4_tracking;
reg clk=0,rst=0,valid=0,sof=0;reg[95:0]rgb=0;reg[15:0]id=0;wire[31:0]refbox,hand,motion,info,debug,meter;
always #5 clk=~clk;
adv_vision #(.V4_MODE(1)) dut(clk,rst,rgb,valid,sof,32'd0,refbox,hand,motion,info,id,debug,meter);
reg[23:0]grid[0:26*14400-1];integer n,y,x,centre,base_centre=0,expected_centre;reg[23:0]pixel;
task frame;begin
 @(negedge clk);sof=1;@(negedge clk);sof=0;
 for(y=0;y<720;y=y+1)begin for(x=0;x<320;x=x+1)begin @(negedge clk);valid=1;pixel=grid[n*14400+(y>>3)*160+(x>>1)];rgb={4{pixel}};end
 @(negedge clk);valid=0;repeat(2)@(negedge clk);end
 wait(dut.state==0 && !dut.capture);repeat(8)@(negedge clk);
end endtask
initial begin $readmemh("advanced_v4_tracking.hex",grid);repeat(4)@(negedge clk);rst=1;
 for(n=0;n<26;n=n+1)begin id=n+1;frame;
  if(hand[31])$fatal(1,"paper-only scene produced a hand identity");
  if(info[31:16]!=id)$fatal(1,"reference result source frame identity incorrect");
  if(n==1)begin
   if(!refbox[31])$fatal(1,"clear Rice failed to acquire in two captures");
   centre=(refbox[29:22]*8)+(refbox[14:7]*4);base_centre=centre;
   if(centre<420 || centre>530 || refbox[14:7]<35)$fatal(1,"initial box does not cover whole printed pattern");
  end
  if(n>=2 && n<14)begin
   centre=(refbox[29:22]*8)+(refbox[14:7]*4);expected_centre=base_centre+24*(n-1);
   if(!refbox[31] || centre+32<expected_centre || centre>expected_centre+32)begin
    $display("frame%0d ref%h raw%h weak%h bestQ%0d TP%0d expected centre%0d got%0d",n,refbox,dut.raw_ref,dut.raw_ref_weak,$signed(dut.best_quality),dut.best_tp,expected_centre,centre);$fatal(1,"moving reference interrupted or lagged excessively");end
  end
  if(n>=22 && refbox[31])$fatal(1,"reference or prediction persisted after removal / cross negative");
 end
 $display("PASS ADVANCED V4 TRACKING PIXELS:26 complete720p camera frames, <=2-frame clear acquisition, 24px/capture measured horizontal follow through brightness/blur/partial obstruction, bounded32px error, coherent source IDs, removal timeout and unrelated-cross rejection");$finish;end
initial begin #700000000;$fatal(1,"moving reference timeout");end
endmodule
