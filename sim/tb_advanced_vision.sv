`timescale 1ns/1ps
`include "advanced_config.vh"
module tb_advanced_vision;
reg clk=0,rst=0,valid=0,sof=0;always #5 clk=~clk;
reg [95:0] rgb=0;wire [31:0] refbox,yeah,motion,info;
adv_vision dut(clk,rst,rgb,valid,sof,32'd0,refbox,yeah,motion,info,16'd7,,);
reg [23:0] grid[0:`ADV_CASES*14400-1];reg [1:0] expected[0:`ADV_CASES-1];
integer yy,xx,k,n,rep;reg [23:0] pixel;
task frame(input integer index);begin
 @(negedge clk);sof=1;valid=0;@(negedge clk);sof=0;
 for(yy=0;yy<720;yy=yy+1)begin
  for(xx=0;xx<320;xx=xx+1)begin
   @(negedge clk);valid=1;pixel=grid[index*14400+(yy>>3)*160+(xx>>1)];rgb={4{pixel}};
  end
  @(negedge clk);valid=0;repeat(2)@(negedge clk);
 end
 @(negedge clk);valid=0;wait(dut.state==0 && !dut.capture);repeat(8)@(negedge clk);
end endtask
initial begin
 $readmemh("advanced_frames.hex",grid);$readmemh("advanced_expected.hex",expected);
 repeat(4)@(negedge clk);rst=1;
 for(n=0;n<`ADV_CASES;n=n+1)begin
  rst=0;repeat(4)@(negedge clk);rst=1;
  for(rep=0;rep<3;rep=rep+1)frame(n);
  if(refbox[31]!==expected[n][1] || yeah[31]!==expected[n][0])begin
   $writememh("advanced_mask_debug.hex",dut.frame_mask);
   $display("REF bbox %0d %0d %0d %0d threshold%0d rw%0d rh%0d",dut.ix0,dut.iy0,dut.ix1,dut.iy1,8'd0,dut.rw,dut.rh);
   $display("CASE%0d expected%0b gotREF%0b YEAH%0b TP%0d BAD%0d FG%0d SCORE%0d bbox%h",n,expected[n],refbox[31],yeah[31],dut.ref_tp,dut.ref_bad,dut.ref_fg,$signed(dut.head_total),dut.raw_hand);
   $fatal(1,"production camera-grid recognition differs from integer reference");
  end
  $display("CASE%0d REF%0b YEAH%0b",n,refbox[31],yeah[31]);
 end
 $display("PASS ADVANCED VISION: actual1280x720 four-lane streams, user reference and size/brightness variants, shapes and public gesture positives/negatives, frozen integer MLP equivalence, temporal acquisition/withdrawal");$finish;
end
initial begin #2000000000;$fatal(1,"advanced timeout");end
endmodule
