`timescale 1ns/1ps
module tb_expression_cbrow_pixels;
reg clk=0,rst=0,start=0,write=0,low=0;always #5 clk=~clk;reg[11:0] address;reg[7:0] pixel,contrast;wire busy,done,gbusy,gdone;wire[1:0] label,glabel;wire[167:0] diag,gdiag;
ext_expression_core #(.ENABLE_CUE(1),.ENABLE_MOUTH(1),.BALANCED_POLICY(1),.FULL_SCORE_DEBUG(0),.V22_POLICY(1),.ENABLE_CBROW(1)) dut(clk,rst,start,write,address,pixel,contrast,busy,done,label,diag,low);
v24_expression_core_gold #(.ENABLE_CUE(1),.ENABLE_MOUTH(1),.BALANCED_POLICY(1),.FULL_SCORE_DEBUG(0),.V22_POLICY(1)) gold(clk,rst,start,write,address,pixel,contrast,gbusy,gdone,glabel,gdiag,low);
reg[7:0] pixels[0:73727],hh[0:255];reg modes[0:31],candidate[0:31];reg[1:0] labels[0:31];reg[15:0] ss[0:63];integer f,i,lo,hi,cycles,seen_gold,seen_new,cc=0;reg[31:0] expected_margin;
always @(posedge clk)begin if(gdone)seen_gold=1;if(done)seen_new=1;end
initial begin
 $readmemh("cbrow_pixels.hex",pixels);$readmemh("cbrow_modes.hex",modes);$readmemh("cbrow_labels.hex",labels);$readmemh("cbrow_cbrow_hidden.hex",hh);$readmemh("cbrow_cbrow_scores.hex",ss);$readmemh("cbrow_confused.hex",candidate);
 repeat(3)@(negedge clk);rst=1;
 for(f=0;f<32;f=f+1)begin
  low=modes[f];lo=255;hi=0;for(i=0;i<(low?1024:2304);i=i+1)begin @(negedge clk);write=1;address=i;pixel=pixels[f*2304+i];if(pixel<lo)lo=pixel;if(pixel>hi)hi=pixel;end
  @(negedge clk);write=0;contrast=hi-lo;start=1;seen_gold=0;seen_new=0;@(negedge clk);start=0;cycles=0;
  while(!seen_gold || !seen_new)begin @(negedge clk);cycles=cycles+1;if(cycles>900000)$fatal(1,"frame budget");end
  if(label!==glabel || label!==labels[f] || dut.final_rejection!==gold.final_rejection)$fatal(1,"V24 H/R decision changed f%0d",f);
  for(i=0;i<8;i=i+1)begin if(dut.scores[i]!==gold.scores[i])$fatal(1,"main score changed");if(dut.hidden[i]!==hh[f*8+i])$fatal(1,"CBROW hidden f%0d neuron%0d got%0d want%0d",f,i,dut.hidden[i],hh[f*8+i]);end
  for(i=0;i<6;i=i+1)if(dut.au_scores[i]!==gold.au_scores[i])$fatal(1,"AU score changed");
  for(i=0;i<2;i=i+1)begin if(dut.cue_scores[i]!==gold.cue_scores[i] || dut.orientation_scores[i]!==gold.orientation_scores[i])$fatal(1,"cue/orientation changed");if(dut.cbrow_scores[i]!==ss[f*2+i])$fatal(1,"CBROW score f%0d output%0d got%0d want%0d",f,i,dut.cbrow_scores[i],$signed(ss[f*2+i]));end
  if(dut.mouth_score!==gold.mouth_score || diag[135]!==candidate[f] || dut.confused!==candidate[f])$fatal(1,"C/mouth mismatch f%0d",f);
  expected_margin=gold.chosen_margin>65535?65535:gold.chosen_margin;
  if(diag[31:0]!==expected_margin || (diag[159:153]!==0 || diag[152]!==($signed(ss[f*2+1])>=384)) || diag[127:32]!==0 || diag[167:160]!==gdiag[167:160])$fatal(1,"compact metadata mismatch");
  if(candidate[f])cc=cc+1;
 end
 if(cc<4)$fatal(1,"C witnesses absent");
 $display("PASS CBROW PIXELS:32 real native48/native32/rotated images through actual dedicated shared-MAC model; exact NPZ hidden and two scores, unchanged literal V24 main/AU/cue/mouth/orientation/classification, compact margin saturation and independent C");$finish;
end
initial begin #350000000;$fatal(1,"hang");end
endmodule
