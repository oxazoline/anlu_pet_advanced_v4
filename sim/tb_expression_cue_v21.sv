`timescale 1ns/1ps
module tb_expression_cue_v21;
reg clk=0,rst=0,start=0,write=0,low=0;always #5 clk=~clk;
reg[11:0] address;reg[7:0] pixel,contrast;wire busy,done;wire[1:0] label;wire[167:0] diag;
ext_expression_core #(.ENABLE_CUE(1)) dut(clk,rst,start,write,address,pixel,contrast,busy,done,label,diag,low);
reg[7:0] pixels[0:73727],hidden[0:255];reg[15:0] cue[0:63],au[0:191];
reg[31:0] ss[0:255];reg[1:0] labels[0:31],old_labels[0:31];reg modes[0:31],rot[0:31],ori[0:31],trigger[0:31];
integer f,i,lo,hi,cycles,improved=0,happy_count=0;
initial begin
 $readmemh("cue_pixels.hex",pixels);$readmemh("cue_cue_hidden.hex",hidden);$readmemh("cue_cue.hex",cue);$readmemh("cue_au.hex",au);$readmemh("cue_ss.hex",ss);
 $readmemh("cue_labels.hex",labels);$readmemh("cue_old_labels.hex",old_labels);$readmemh("cue_modes.hex",modes);$readmemh("cue_orientation.hex",rot);$readmemh("cue_action_orientation.hex",ori);$readmemh("cue_cue_trigger.hex",trigger);
 repeat(3)@(negedge clk);rst=1;
 for(f=0;f<32;f=f+1)begin
  low=modes[f];lo=255;hi=0;
  for(i=0;i<(low?1024:2304);i=i+1)begin @(negedge clk);write=1;address=i;pixel=pixels[f*2304+i];if(pixel<lo)lo=pixel;if(pixel>hi)hi=pixel;end
  @(negedge clk);write=0;contrast=hi-lo;start=1;@(negedge clk);start=0;cycles=0;
  while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>900000)$fatal(1,"cue inference deadline");end
  for(i=0;i<8;i=i+1)begin
   if(dut.hidden[i]!==hidden[f*8+i])$fatal(1,"cue hidden f%0d i%0d got%0d want%0d",f,i,dut.hidden[i],hidden[f*8+i]);
   if(dut.scores[i]!==ss[f*8+i])$fatal(1,"base score changed");
  end
  for(i=0;i<6;i=i+1)if(dut.au_scores[i]!==au[f*6+i])$fatal(1,"old AU changed");
  for(i=0;i<2;i=i+1)if(dut.cue_scores[i]!==cue[f*2+i])$fatal(1,"cue logit f%0d i%0d got%0d want%0d",f,i,$signed(dut.cue_scores[i]),$signed(cue[f*2+i]));
  if(label!==labels[f] || dut.cue_tense!==trigger[f] || dut.selected!==rot[f] || dut.au_orientation!==ori[f])$fatal(1,"cue decision f%0d got%0d want%0d",f,label,labels[f]);
  if(old_labels[f]==1)begin happy_count=happy_count+1;if(label!=1)$fatal(1,"old HAPPY overwritten");end
  if(old_labels[f]!=3 && label==3)improved=improved+1;
  $display("CUE PIXELS f=%0d mode=%0d old=%0d new=%0d B=%0d D=%0d clocks=%0d",f,low?32:48,old_labels[f],label,$signed(dut.cue_scores[0]),$signed(dut.cue_scores[1]),cycles);
 end
 if(improved<8 || happy_count<4)$fatal(1,"no meaningful cue/HAPPY witnesses");
 $display("PASS V21 CUE PIXELS: 32 real native48/native32/rotated inputs, exact hidden/logits/main/oldAU, new nervous witnesses, original HAPPY unchanged and bounded shared-MAC latency");$finish;
end
initial begin #300000000;$fatal(1,"hang");end
endmodule
