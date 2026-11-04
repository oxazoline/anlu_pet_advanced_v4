`timescale 1ns/1ps
module tb_expression_au_limits;
 reg clk=0,rst=0;always #5 clk=~clk;
 wire busy,done;wire[1:0] label;wire[167:0] diag;
 ext_expression_core dut(clk,rst,1'b0,1'b0,12'd0,8'd0,8'd128,busy,done,label,diag,1'b0);
 reg[7:0] h[0:4095];reg[15:0] expected[0:3071];reg tense[0:511];
 integer f,i,cycles,clipped=0;
 initial begin
 $readmemh("au_limits_hidden.hex",h);$readmemh("au_limits_scores.hex",expected);$readmemh("au_limits_tense.hex",tense);
 repeat(3)@(negedge clk);rst=1;
 for(f=0;f<512;f=f+1)begin
 @(negedge clk);
 // Only legal H8 activations are injected to isolate the actual six-head ROM/MAC.
 // Pixel-to-hidden behavior is separately checked in tb_expression_au.
 for(i=0;i<8;i=i+1)dut.hidden[i]=h[f*8+i];
 dut.state=19;dut.head_index=0;dut.au_output=0;dut.weight_word=954;dut.au_slot=0;
 dut.accumulator=dut.au_bias2(0);dut.product=0;dut.O_busy=1;
 dut.contrast=128;dut.orientation_confident=1;dut.winner[0]=1;dut.selected=0;
 cycles=0;
 @(negedge clk);
 while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>200)$fatal(1,"AU limits timeout");end
 for(i=0;i<6;i=i+1)begin
 if(dut.au_scores[i]!==expected[f*6+i])$fatal(1,"AU limits f%0d head%0d got%0d expected%0d",f,i,dut.au_scores[i],$signed(expected[f*6+i]));
 if(expected[f*6+i]==16'h8000 || expected[f*6+i]==16'h7fff)clipped=clipped+1;
 end
 if(dut.au_tense!==tense[f])$fatal(1,"AU full32 decision mismatch f%0d",f);
 end
 if(clipped<100)$fatal(1,"Boundary vectors did not exercise saturation");
 $display("PASS AU LIMITS: actual six-head ROM/MAC, all256 legal hidden corners plus256 random vectors, signed16 saturation and NERVOUS predicate match full32 CPU; clipped%0d",clipped);$finish;
 end
 initial begin #2000000;$fatal(1,"timeout");end
endmodule
