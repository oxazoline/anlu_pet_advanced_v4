`timescale 1ns/1ps
module tb_expression_v21_equivalence;
reg clk=0,rst=0,start=0,write=0,low=0;always #5 clk=~clk;
reg[11:0] address;reg[7:0] pixel,contrast;wire busy,done,gbusy,gdone;wire[1:0] label,glabel;wire[167:0] diag,gdiag;
ext_expression_core #(.ENABLE_CUE(1),.ENABLE_MOUTH(1)) dut(clk,rst,start,write,address,pixel,contrast,busy,done,label,diag,low);
v21_expression_core_gold #(.ENABLE_CUE(1)) gold(clk,rst,start,write,address,pixel,contrast,gbusy,gdone,glabel,gdiag,low);
reg[7:0] pixels[0:73727];reg modes[0:31],candidate[0:31];reg[1:0] labels[0:31];reg[15:0] mouth[0:31];reg[31:0] partial[0:63];
integer f,i,lo,hi,cycles,seen_gold=0,seen_new=0,combos=0,delays=0;
always @(posedge clk)begin if(gdone)seen_gold=1;if(done)seen_new=1;end
initial begin
 $readmemh("v21c_pixels.hex",pixels);$readmemh("v21c_modes.hex",modes);$readmemh("v21c_labels.hex",labels);$readmemh("v21c_confused.hex",candidate);$readmemh("v21c_mouth.hex",mouth);$readmemh("v21c_mouth_partial.hex",partial);
 repeat(3)@(negedge clk);rst=1;
 for(f=0;f<32;f=f+1)begin
  low=modes[f];lo=255;hi=0;
  for(i=0;i<(low?1024:2304);i=i+1)begin @(negedge clk);write=1;address=i;pixel=pixels[f*2304+i];if(pixel<lo)lo=pixel;if(pixel>hi)hi=pixel;end
  @(negedge clk);write=0;contrast=hi-lo;start=1;seen_gold=0;seen_new=0;@(negedge clk);start=0;cycles=0;
  while(!seen_gold || !seen_new)begin @(negedge clk);cycles=cycles+1;if(cycles>900000)$fatal(1,"shared MAC frame deadline");if(seen_gold && !seen_new)delays=delays+1;end
  if(label!==glabel || label!==labels[f] || dut.final_winner!==gold.final_winner || dut.final_rejection!==gold.final_rejection)$fatal(1,"V21 base decision changed f%0d new%0d old%0d expected%0d",f,label,glabel,labels[f]);
  if(diag[167:160]!==gdiag[167:160] || diag[127:0]!==gdiag[127:0])$fatal(1,"V21 base scores/margins/metadata changed");
  for(i=0;i<8;i=i+1)if(dut.scores[i]!==gold.scores[i])$fatal(1,"main numerical score changed");
  for(i=0;i<6;i=i+1)if(dut.au_scores[i]!==gold.au_scores[i])$fatal(1,"AU numerical score changed");
  for(i=0;i<2;i=i+1)begin
   if(dut.cue_scores[i]!==gold.cue_scores[i] || dut.orientation_scores[i]!==gold.orientation_scores[i])$fatal(1,"cue/orientation numerical score changed");
   if(dut.mouth_partial[i]!==partial[f*2+i])$fatal(1,"mouth partial changed");
  end
  if(dut.mouth_score!==mouth[f] || dut.confused!==candidate[f] || diag[135]!==candidate[f])$fatal(1,"independent C witness f%0d got%0d want%0d",f,dut.confused,candidate[f]);
  if(candidate[f])begin combos=combos+1;if(label!=3)$fatal(1,"C created new base R");end
 end
 if(combos<4 || delays==0)$fatal(1,"missing actual overlay/latency witnesses");
 $display("PASS V21 EQUIVALENCE:32 real native48/native32/180-degree inputs through original V21 RTL and production-enabled mouth core, exact base labels/rejections/main/AU/cue/orientation/margins, independent C witness, bounded added serial work");$finish;
end
initial begin #300000000;$fatal(1,"hang");end
endmodule
