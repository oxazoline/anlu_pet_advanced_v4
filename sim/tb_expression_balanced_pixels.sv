`timescale 1ns/1ps
module tb_expression_balanced_pixels;
reg clk=0,rst=0,start=0,write=0,low=0;always #5 clk=~clk;
reg[11:0] address;reg[7:0] pixel,contrast;wire busy,done,gbusy,gdone;wire[1:0] label,glabel;wire[167:0] diag,gdiag;
ext_expression_core #(.ENABLE_CUE(1),.ENABLE_MOUTH(1),.BALANCED_POLICY(1),.FULL_SCORE_DEBUG(0)) dut(clk,rst,start,write,address,pixel,contrast,busy,done,label,diag,low);
v21_expression_core_gold #(.ENABLE_CUE(1)) gold(clk,rst,start,write,address,pixel,contrast,gbusy,gdone,glabel,gdiag,low);
reg[15:0] pb[0:3199],po[0:3199],pm[0:3199],pd[0:3199],pt[0:3199],ps[0:3199];reg[7:0] pr[0:3199],pc[0:3199],por[0:3199],pl[0:3199],py[0:3199],pg[0:3199];
reg[7:0] debug_byte[0:31];reg gs[0:31];integer other_c=0;
reg[7:0] pixels[0:73727];reg modes[0:31],candidate[0:31];reg[1:0] labels[0:31];reg[15:0] mouth[0:31];reg[31:0] partial[0:63];
integer f,i,lo,hi,cycles,seen_gold=0,seen_new=0,combos=0,delays=0;
always @(posedge clk)begin if(gdone)seen_gold=1;if(done)seen_new=1;end
initial begin
 $readmemh("balanced_pixels.hex",pixels);$readmemh("balanced_modes.hex",modes);$readmemh("balanced_labels.hex",labels);$readmemh("balanced_confused.hex",candidate);$readmemh("balanced_mouth.hex",mouth);$readmemh("balanced_mouth_partial.hex",partial);
 $readmemh("balanced_strong_r.hex",gs);$readmemh("balanced_debug_byte.hex",debug_byte);
 $readmemh("balanced_policy_brow.hex",pb);$readmemh("balanced_policy_old.hex",po);$readmemh("balanced_policy_mouth.hex",pm);$readmemh("balanced_policy_down.hex",pd);$readmemh("balanced_policy_total.hex",pt);$readmemh("balanced_policy_smile.hex",ps);$readmemh("balanced_policy_raw.hex",pr);$readmemh("balanced_policy_contrast.hex",pc);$readmemh("balanced_policy_orientation.hex",por);$readmemh("balanced_policy_label.hex",pl);$readmemh("balanced_policy_candidate.hex",py);$readmemh("balanced_policy_strong.hex",pg);
 repeat(3)@(negedge clk);rst=1;
 for(f=0;f<32;f=f+1)begin
  low=modes[f];lo=255;hi=0;
  for(i=0;i<(low?1024:2304);i=i+1)begin @(negedge clk);write=1;address=i;pixel=pixels[f*2304+i];if(pixel<lo)lo=pixel;if(pixel>hi)hi=pixel;end
  @(negedge clk);write=0;contrast=hi-lo;start=1;seen_gold=0;seen_new=0;@(negedge clk);start=0;cycles=0;
  while(!seen_gold || !seen_new)begin @(negedge clk);cycles=cycles+1;if(cycles>900000)$fatal(1,"shared MAC frame deadline");if(seen_gold && !seen_new)delays=delays+1;end
  if(label!==glabel || label!==labels[f] || dut.final_winner!==gold.final_winner || dut.final_rejection!==gold.final_rejection)$fatal(1,"V21 base decision changed f%0d new%0d old%0d expected%0d",f,label,glabel,labels[f]);
  if(diag[167:160]!==gdiag[167:160] || diag[127:32]!==96'd0 || diag[31:0]!==gdiag[31:0])$fatal(1,"V21 base scores/margins/metadata changed");
  for(i=0;i<8;i=i+1)if(dut.scores[i]!==gold.scores[i])$fatal(1,"main numerical score changed");
  for(i=0;i<6;i=i+1)if(dut.au_scores[i]!==gold.au_scores[i])$fatal(1,"AU numerical score changed");
  for(i=0;i<2;i=i+1)begin
   if(dut.cue_scores[i]!==gold.cue_scores[i] || dut.orientation_scores[i]!==gold.orientation_scores[i])$fatal(1,"cue/orientation numerical score changed");
   if(dut.mouth_partial[i]!==partial[f*2+i])$fatal(1,"mouth partial changed");
  end
  if(dut.mouth_score!==mouth[f] || dut.confused!==candidate[f] || diag[135]!==candidate[f])$fatal(1,"independent C witness f%0d got%0d want%0d",f,dut.confused,candidate[f]);
  if(diag[152]!==gs[f] || diag[159:152]!==debug_byte[f])$fatal(1,"strong-R metadata changed");
  if(candidate[f])begin combos=combos+1;if(label==0 && diag[165:164]==3)other_c=other_c+1;end
 end
 if(combos<4 || other_c<4 || delays==0)$fatal(1,"missing actual overlay/latency witnesses");
 for(f=0;f<3200;f=f+1)begin
  @(negedge clk);dut.cue_scores[0]=pb[f];dut.cue_scores[1]=pd[f];dut.au_scores[0]=pt[f];dut.au_scores[1]=po[f];dut.au_scores[2]=ps[f];dut.au_scores[3]=-32768;dut.au_scores[4]=-32768;dut.au_scores[5]=-32768;dut.mouth_score=pm[f];dut.winner[0]=pr[f];dut.selected=0;dut.contrast=pc[f];dut.orientation_confident=por[f];dut.margin0=100000;dut.happy_gap0=100000;dut.low_mode=0;
  #2;if(dut.confused!==py[f][0] || dut.strong_r!==pg[f][0])$fatal(1,"balanced independent boundary%0d",f);
  dut.state=15;dut.O_busy=1;@(negedge clk);if(label!==pl[f][1:0] || diag[135]!==py[f][0] || diag[152]!==pg[f][0])$fatal(1,"base label or C/G metadata boundary%0d",f);
 end
 // The old photograph reports byte05 (mouth160..191) and byte31
 // (brow1568..1599), raw OTHER, contrast98, orientation-confident.
 // Replay the full quantized intervals, not a guessed single score.
 for(f=160;f<=191;f=f+1)for(i=1568;i<=1599;i=i+1)begin
  @(negedge clk);dut.cue_scores[0]=i;dut.cue_scores[1]=-32768;dut.au_scores[0]=-32768;dut.au_scores[1]=-32768;dut.au_scores[2]=0;dut.au_scores[3]=-32768;dut.au_scores[4]=-32768;dut.au_scores[5]=-32768;dut.mouth_score=f;dut.winner[0]=3;dut.selected=0;dut.contrast=8'h98;dut.orientation_confident=1;
  #2;if(!dut.confused || !dut.mouth_open)$fatal(1,"photo mouth/brow interval rejected");
 end
 $display("PASS BALANCED PIXELS:32 actual native48/native32/rotated images through original V21 and balanced shared-MAC core with exact unchanged base scores/classes, independent C on rejected OTHER and neutral, exact packed mouth/strong-R diagnostics, compact96-bit zero diagnostics with full internal scores and exact32-bit margin;3200 signed/contrast/orientation/mouth/brow/strong thresholds plus1024 photo-derived score-interval replays (diagnostic values, not camera pixels), HAPPY/low-quality protected");$finish;
end
initial begin #300000000;$fatal(1,"hang");end
endmodule
