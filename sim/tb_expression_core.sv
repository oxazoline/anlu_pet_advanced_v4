`timescale 1ns/1ps
module tb_expression_core;
 reg clk=0,rst=0,start=0,write=0;always #5 clk=~clk;
 reg low=0;reg [11:0] address;reg [7:0] pixel,contrast;wire busy,done;wire [1:0] label;
 ext_expression_core #(.ENABLE_AU(0)) dut(clk,rst,start,write,address,pixel,contrast,busy,done,label,,low);
 reg [7:0] images[0:34559];reg [31:0] scores[0:119];reg [1:0] labels[0:14];
 reg [31:0] thresholds[0:3],low_thresholds[0:3];reg[7:0] heads[0:127],low_heads[0:127];
 reg [8:0] histograms[0:60479];
 reg modes[0:14];reg remainders[0:60479];integer f,i,c,n,cycles;integer lo,hi;
 initial begin
  $readmemh("expression_low_thresholds.hex",low_thresholds);$readmemh("expression_head_weights.hex",heads);$readmemh("expression_low_head_weights.hex",low_heads);$readmemh("expression_modes.hex",modes);$readmemh("expression_remainders.hex",remainders);$readmemh("expression_pixels.hex",images);$readmemh("expression_scores.hex",scores);
  $readmemh("expression_labels.hex",labels);$readmemh("expression_histograms.hex",histograms);$readmemh("expression_thresholds.hex",thresholds);
  repeat(3)@(negedge clk);rst=1;
  for(i=0;i<4;i=i+1)if(dut.class_margin(i)!==thresholds[i])$fatal(1,"class threshold mismatch");
  for(i=0;i<4;i=i+1)if(dut.low_class_margin(i)!==low_thresholds[i])$fatal(1,"small-mode class threshold mismatch");
  for(i=0;i<128;i=i+1)if(dut.head_weight(i)!==heads[i] || dut.low_head_weight(i)!==low_heads[i])$fatal(1,"head coefficient mismatch");
  for(f=0;f<15;f=f+1)begin
   lo=255;hi=0;low=modes[f];
   for(i=0;i<(low?1024:2304);i=i+1)begin
    @(negedge clk);write=1;address=i;pixel=images[f*2304+i];
    if(pixel<lo)lo=pixel;if(pixel>hi)hi=pixel;
   end
   @(negedge clk);write=0;contrast=hi-lo;start=1;
   @(negedge clk);start=0;cycles=0;
   while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>800000)$fatal(1,"expression hangs state=%d",dut.state);end
   for(i=0;i<8;i=i+1)if(dut.scores[i]!==scores[f*8+i])$fatal(1,"score mismatch patch=%0d score=%0d got=%0d want=%0d",f,i,dut.scores[i],$signed(scores[f*8+i]));
   for(c=0;c<2;c=c+1)for(i=0;i<2016;i=i+1)
    if(dut.histogram[c*2048+i]!==histograms[f*4032+c*2016+i])$fatal(1,"hist mismatch patch=%0d orient=%0d feature=%0d got=%0d want=%0d",f,c,i,dut.histogram[c*2048+i],histograms[f*4032+c*2016+i]);
   for(c=0;c<2;c=c+1)for(i=0;i<2016;i=i+1)if(dut.remainder[c*2048+i]!==remainders[f*4032+c*2016+i])$fatal(1,"half-count remainder mismatch");
   for(i=0;i<4;i=i+1)if(dut.O_diagnostic[32+i*32+:32]!==scores[f*8+(dut.selected?4:0)+i])$fatal(1,"diagnostic raw score mismatch");
   if(!dut.O_diagnostic[167] || dut.O_diagnostic[166]!==dut.selected)$fatal(1,"diagnostic orientation/valid mismatch");
   if(label!==labels[f])$fatal(1,"label mismatch");
   $display("EXPRESSION patch=%0d label=%0d cycles=%0d",f,label,cycles);
  end
  $display("PASS EXPRESSION CORE: 15 native48/native32 patches; all 4032 normalized histogram/remainder counts and 8 integer scores each match independent CPU reference, HAPPY/NEUTRAL/NERVOUS and internal rejection, real FER Training patches, rotated pairs, flat/ramp/noise, exact reject threshold");$finish;
 end
 initial begin #100000000;$fatal(1,"timeout");end
endmodule
