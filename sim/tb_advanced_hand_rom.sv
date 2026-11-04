`timescale 1ns/1ps
module tb_advanced_hand_rom;
reg clk=0;always #5 clk=~clk;reg[9:0]word_addr=1023;reg[3:0]hidden=15;
wire[17:0]word_data;wire signed[15:0]bias;wire signed[7:0]head;
adv_hand_weights dut(clk,word_addr,hidden,word_data,bias,head);
reg[2:0]expected[0:6143];reg[15:0]ebias[0:11];reg[7:0]ehead[0:11];integer n;
initial begin $readmemh("advanced_hand_coeff.hex",expected);$readmemh("advanced_hand_bias.hex",ebias);$readmemh("advanced_hand_head.hex",ehead);
 for(n=0;n<6144;n=n+1)begin @(negedge clk);word_addr=n/6;hidden=n/512;@(posedge clk);#1;
 if(word_data[17-(n%6)*3-:3]!==expected[n] || bias!==ebias[n/512] || head!==ehead[n/512])$fatal(1,"packed model mismatch%0d",n);
 end
 $display("PASS ADVANCED HAND ROM: all6144 signed3 coefficients,12 signed16 biases and signed8 heads equal frozen Python model");$finish;end
endmodule
