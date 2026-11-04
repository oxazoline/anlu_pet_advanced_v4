`timescale 1ns/1ps
module tb_extension_mode_core;
localparam NO_C=0;
reg clk=0,rst=0,start=0,write=0,low=0;always #5 clk=~clk;reg[11:0] address;reg[7:0] pixel,contrast;wire busy,done,gbusy,gdone;wire[1:0] label,glabel;wire[167:0] diag,gdiag;
ext_expression_core #(.ENABLE_CUE(1),.ENABLE_MOUTH(!NO_C),.BALANCED_POLICY(1),.FULL_SCORE_DEBUG(0),.V22_POLICY(1),.ENABLE_CBROW(!NO_C),.CONFUSED_GUARD(!NO_C)) dut(clk,rst,start,write,address,pixel,contrast,busy,done,label,diag,low);
v25_expression_core_gold #(.ENABLE_CUE(1),.ENABLE_MOUTH(1),.BALANCED_POLICY(1),.FULL_SCORE_DEBUG(0),.V22_POLICY(1),.ENABLE_CBROW(1)) gold(clk,rst,start,write,address,pixel,contrast,gbusy,gdone,glabel,gdiag,low);
reg[7:0] pixels[0:73727];reg modes[0:31],candidate[0:31],strong_expected[0:31];reg[1:0] labels[0:31];integer f,i,lo,hi,cycles,seen_gold,seen_new,dc,gc,saved=0;
always @(posedge clk)begin if(gdone)begin seen_gold=1;gc=cycles;end if(done)begin seen_new=1;dc=cycles;end end
initial begin
 $readmemh("mode_pixels.hex",pixels);$readmemh("mode_modes.hex",modes);$readmemh("mode_labels.hex",labels);$readmemh("mode_candidate.hex",candidate);$readmemh("mode_strong.hex",strong_expected);repeat(3)@(negedge clk);rst=1;
 for(f=0;f<32;f=f+1)begin
  low=modes[f];lo=255;hi=0;for(i=0;i<(low?1024:2304);i=i+1)begin @(negedge clk);write=1;address=i;pixel=pixels[f*2304+i];if(pixel<lo)lo=pixel;if(pixel>hi)hi=pixel;end
  @(negedge clk);write=0;contrast=hi-lo;start=1;seen_gold=0;seen_new=0;cycles=0;@(negedge clk);start=0;
  while(!seen_gold || !seen_new)begin @(negedge clk);cycles=cycles+1;if(cycles>900000)$fatal(1,"frame budget");end
  if(label!==glabel || label!==labels[f] || dut.final_rejection!==gold.final_rejection)$fatal(1,"V25 H/R decision changed f%0d",f);
  for(i=0;i<8;i=i+1)if(dut.scores[i]!==gold.scores[i])$fatal(1,"main score changed");for(i=0;i<6;i=i+1)if(dut.au_scores[i]!==gold.au_scores[i])$fatal(1,"AU score changed");for(i=0;i<2;i=i+1)if(dut.cue_scores[i]!==gold.cue_scores[i] || dut.orientation_scores[i]!==gold.orientation_scores[i])$fatal(1,"cue/orientation changed");
  if(NO_C)begin
   if(gc-dc<25000 || dut.ENABLE_MOUTH!=0 || dut.ENABLE_CBROW!=0)$fatal(1,"no-C path not removed/accelerated");saved=gc-dc;
   if((diag[31:0]>=2188)!==(gdiag[31:0]>=2188) || (diag[31:0]>=2432)!==(gdiag[31:0]>=2432))$fatal(1,"fast-H margin behavior changed");
  end else if(diag[135]!==candidate[f] || diag[155]!==strong_expected[f] || dut.mouth_score!==gold.mouth_score)$fatal(1,"guarded C/Q mismatch f%0d",f);
 end
 $display("PASS MODE CORE:32 native48/native32/rotated actual pixel inputs versus literal V25; all H/R scores/labels/rejections unchanged; mode=%0d, removed auxiliary-path saving=%0d cycles; guarded C/Q CPU oracle exact",NO_C,saved);$finish;
end
initial begin #350000000;$fatal(1,"hang");end
endmodule
