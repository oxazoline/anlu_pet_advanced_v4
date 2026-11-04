`timescale 1ns/1ps
module tb_advanced_font;
reg clk=0;always #5 clk=~clk;reg[7:0]ch=255;reg[3:0]row=15;wire[15:0]old_bits,new_bits;
osd_char_lib old(ch,row,old_bits);adv_font_rom dut(clk,ch,row,new_bits);integer c,r;
initial begin for(c=0;c<256;c=c+1)for(r=0;r<16;r=r+1)begin
 @(negedge clk);ch=c;row=r;@(posedge clk);#1;if(new_bits!==old_bits)$fatal(1,"glyph mismatch%0d/%0d actual%h expected%h",c,r,new_bits,old_bits);
end
$display("PASS ADVANCED FONT: all256 character codes x16 rows identical to V26, one-cycle ROM output");$finish;end
endmodule
