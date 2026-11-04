`timescale 1ns/1ps
`include "advanced_v2_config.vh"
module tb_advanced_v2_pixels;
reg clk=0,rst=0,valid=0,sof=0;reg[95:0]rgb=0;wire[31:0]refbox,yeah,motion,info,debug;
always #5 clk=~clk;
adv_vision dut(clk,rst,rgb,valid,sof,32'd0,refbox,yeah,motion,info,16'd7,debug,);
reg[95:0]pixels[0:`ADV_RAW_CASES*230400-1];reg[1:0]masks[0:`ADV_RAW_CASES*14400-1];
reg[1:0]expected[0:`ADV_RAW_CASES-1];reg[31:0]scores[0:`ADV_RAW_CASES-1];integer n,r,y,x,k;
task frame;begin
 @(negedge clk);sof=1;@(negedge clk);sof=0;
 for(y=0;y<720;y=y+1)begin
 for(x=0;x<320;x=x+1)begin @(negedge clk);valid=1;rgb=pixels[n*230400+y*320+x];end
 @(negedge clk);valid=0;repeat(2)@(negedge clk);end
 wait(dut.state==0 && !dut.capture);repeat(8)@(negedge clk);
end endtask
initial begin
 $readmemh("advanced_v2_raw.hex",pixels);$readmemh("advanced_v2_mask.hex",masks);$readmemh("advanced_v2_raw_expected.hex",expected);$readmemh("advanced_v2_score.hex",scores);
 for(n=0;n<`ADV_RAW_CASES;n=n+1)begin
 rst=0;repeat(4)@(negedge clk);rst=1;repeat(n+2)@(negedge clk);
 for(r=0;r<3;r=r+1)begin frame;
 for(k=0;k<14400;k=k+1)if(dut.frame_mask[k]!==masks[n*14400+k])$fatal(1,"actual four distinct pixel lanes mismatch at case%0d cell%0d RTL%0h REF%0h",n,k,dut.frame_mask[k],masks[n*14400+k]);
 end
 if({refbox[31],yeah[31]}!==expected[n])$fatal(1,"raw pixel case%0d expected%0b got%0b",n,expected[n],{refbox[31],yeah[31]});
 if(dut.head_total!==scores[n])$fatal(1,"raw pixel integer hand score mismatch");
 end
 $display("PASS ADVANCED V2 PIXELS: distinct RGB96 lanes, complete source pixels, 57600 exact skin/ink cell comparisons per repetition, printed original/dim/dark distractor and isolated hand speckle, exact integer score");$finish;end
initial begin #600000000;$fatal(1,"raw pixels timeout");end
endmodule
