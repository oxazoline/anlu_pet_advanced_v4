`timescale 1ns/1ps
module tb_expression_v22_sensitive_pixels;
reg clk=0,rst=0,start=0,write=0,low=0;always #5 clk=~clk;reg[11:0] address;reg[7:0] pixel,contrast;wire busy,done,gbusy,gdone;wire[1:0] label;wire[2:0] glabel;wire[167:0] diag,gdiag;
ext_expression_core #(.ENABLE_CUE(1),.ENABLE_MOUTH(1),.BALANCED_POLICY(1),.FULL_SCORE_DEBUG(0),.V22_POLICY(1)) dut(clk,rst,start,write,address,pixel,contrast,busy,done,label,diag,low);
v22_expression_core_gold #(.ENABLE_CUE(1),.ENABLE_MOUTH(0)) gold(clk,rst,start,write,address,pixel,contrast,gbusy,gdone,glabel,gdiag,low);
reg[7:0] pixels[0:73727];reg modes[0:31];reg[1:0] labels[0:31],previous[0:31];integer f,i,lo,hi,cycles,seen_gold,seen_new;
always @(posedge clk)begin if(gdone)seen_gold=1;if(done)seen_new=1;end
initial begin
 $readmemh("v22_sensitive_pixels.hex",pixels);$readmemh("v22_sensitive_modes.hex",modes);$readmemh("v22_sensitive_labels.hex",labels);$readmemh("v22_sensitive_v22_labels.hex",previous);
 repeat(3)@(negedge clk);rst=1;
 for(f=0;f<32;f=f+1)begin
  low=modes[f];lo=255;hi=0;
  for(i=0;i<(low?1024:2304);i=i+1)begin @(negedge clk);write=1;address=i;pixel=pixels[f*2304+i];if(pixel<lo)lo=pixel;if(pixel>hi)hi=pixel;end
  @(negedge clk);write=0;contrast=hi-lo;start=1;seen_gold=0;seen_new=0;@(negedge clk);start=0;cycles=0;
  while(!seen_gold || !seen_new)begin @(negedge clk);cycles=cycles+1;if(cycles>900000)$fatal(1,"frame deadline");end
  if(label!==labels[f] || glabel!=={1'b0,previous[f]})$fatal(1,"V22 reference f%0d label%0d expected%0d old%0d oldexpected%0d",f,label,labels[f],glabel,previous[f]);
  if((glabel==1 && label!=1) || (glabel==3 && label!=3))$fatal(1,"V22 H/R recall regressed");
  for(i=0;i<8;i=i+1)if(dut.scores[i]!==gold.scores[i])$fatal(1,"main numerical score changed");
  for(i=0;i<6;i=i+1)if(dut.au_scores[i]!==gold.au_scores[i])$fatal(1,"AU numerical score changed");
  for(i=0;i<2;i=i+1)if(dut.cue_scores[i]!==gold.cue_scores[i] || dut.orientation_scores[i]!==gold.orientation_scores[i])$fatal(1,"cue/orientation numerical score changed");
 end
 // Exact new H boundaries, including low-res quality/conflict gates.
 dut.selected=0;dut.winner[0]=0;dut.contrast=24;dut.low_mode=0;dut.margin0=20;dut.happy_gap0=26;#2;if(dut.rejection!=0)$fatal(1,"native H small delta");
 dut.margin0=19;#2;if(dut.rejection!=3)$fatal(1,"native H margin boundary");dut.margin0=20;dut.happy_gap0=25;#2;if(dut.rejection!=4)$fatal(1,"native H gap boundary");
 dut.low_mode=1;dut.margin0=546;dut.happy_gap0=1344;#2;if(dut.rejection!=0)$fatal(1,"low H small delta");dut.margin0=545;#2;if(dut.rejection!=3)$fatal(1,"low H margin boundary");dut.margin0=546;dut.happy_gap0=1343;#2;if(dut.rejection!=4)$fatal(1,"low H gap boundary");
 dut.contrast=23;#2;if(dut.rejection!=1)$fatal(1,"quality gate changed");
 dut.winner[0]=1;dut.contrast=24;dut.orientation_confident=1;dut.cue_scores[0]=479;dut.cue_scores[1]=-145;#2;if(dut.cue_tense)$fatal(1,"R below both gates");dut.cue_scores[0]=480;#2;if(!dut.cue_tense)$fatal(1,"new brow480");dut.cue_scores[0]=479;dut.cue_scores[1]=-144;#2;if(!dut.cue_tense)$fatal(1,"new down-144");
 $display("PASS V22 SENSITIVE PIXELS:32 real native48/native32/rotated fixtures versus literal V22 RTL; exact main/AU/cue/orientation scores, preserved accepted H/R with small additional gates; exact H margin/gap and R brow480/down-144 boundaries, low quality protected");$finish;
end
initial begin #300000000;$fatal(1,"hang");end
endmodule
