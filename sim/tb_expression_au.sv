`timescale 1ns/1ps
module tb_expression_au;
 reg clk=0,rst=0,start=0,write=0,low=0;always #5 clk=~clk;
 reg [11:0] address;reg [7:0] pixel,contrast;wire busy,done;wire [1:0] label;wire[167:0] diag;
 ext_expression_core dut(clk,rst,start,write,address,pixel,contrast,busy,done,label,diag,low);
 reg [7:0] pixels[0:73727],hidden[0:255];reg [15:0] au[0:191];reg [1:0] labels[0:31];reg modes[0:31],rotation[0:31],action_rotation[0:31];reg [31:0] os[0:63];reg [31:0] ss[0:255];
 integer f,i,lo,hi,cycles,tense_count=0;
 initial begin
 $readmemh("au_pixels.hex",pixels);$readmemh("au_hidden.hex",hidden);$readmemh("au_au.hex",au);$readmemh("au_labels.hex",labels);$readmemh("au_modes.hex",modes);$readmemh("au_orientation.hex",rotation);$readmemh("au_ss.hex",ss);$readmemh("au_action_orientation.hex",action_rotation);$readmemh("au_orientation_scores.hex",os);
 repeat(3)@(negedge clk);rst=1;
 for(f=0;f<32;f=f+1)begin
 low=modes[f];lo=255;hi=0;
 for(i=0;i<(low?1024:2304);i=i+1)begin
 @(negedge clk);write=1;address=i;pixel=pixels[f*2304+i];if(pixel<lo)lo=pixel;if(pixel>hi)hi=pixel;
 end
 @(negedge clk);write=0;contrast=hi-lo;start=1;@(negedge clk);start=0;cycles=0;
 while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>850000)$fatal(1,"AU inference timeout");end
 for(i=0;i<8;i=i+1)begin
 if(dut.hidden[i]!==hidden[f*8+i])$fatal(1,"AU hidden mismatch f%0d h%0d got%0d want%0d",f,i,dut.hidden[i],hidden[f*8+i]);
 if(dut.scores[i]!==ss[f*8+i])$fatal(1,"Main score changed f%0d i%0d",f,i);
 end
 for(i=0;i<6;i=i+1)if(dut.au_scores[i]!==au[f*6+i])$fatal(1,"AU logit mismatch f%0d au%0d got%0d want%0d",f,i,dut.au_scores[i],$signed(au[f*6+i]));
 for(i=0;i<2;i=i+1)if($signed(dut.orientation_scores[i])!==$signed(os[f*2+i]))$fatal(1,"Orientation score mismatch f%0d i%0d",f,i);
 if(dut.au_orientation!==action_rotation[f])$fatal(1,"Action orientation mismatch");
 if(label!==labels[f] || dut.selected!==rotation[f])$fatal(1,"AU decision mismatch f%0d got%0d want%0d",f,label,labels[f]);
 if(dut.au_tense)begin tense_count=tense_count+1;if(diag[165:164]!=2 || diag[163:160]!=0 || label!=3)$fatal(1,"Auxiliary RAW/RS not coherent");end
 end
 if(tense_count<4)$fatal(1,"No real learned HAPPY/NEUTRAL to NERVOUS witnesses");
 $display("PASS AU STUDENT: 32 real-pixel native48/native32 enabled tension/physical-orientation head and rotated cases, exact 8 hidden/6 logits/8 main scores, learned HAPPY/NEUTRAL correction to NERVOUS and coherent RAW/RS");$finish;
 end
 initial begin #250000000;$fatal(1,"timeout");end
endmodule
