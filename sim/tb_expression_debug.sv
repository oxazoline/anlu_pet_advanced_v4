`timescale 1ns/1ps
module tb_expression_debug;
 reg clk=0,rst=0,vs=0,de=0;always #5 clk=~clk;
 reg [31:0] status=32'h2ac43bf1;
 reg [167:0] diagnostic={8'hd3,32'hfffabcde,32'h11112222,32'h87654321,32'h12345678,32'h89abcdef};
 wire [9:0] address;reg [7:0] patch=0;wire ov,oh,od;wire [23:0] rgb;
 basic_osd #(.ENABLE_CONFUSED_UI(1),.COMPACT_DEBUG(0)) dut(clk,rst,vs,1'b0,de,24'h123456,4'd0,64'd0,64'd0,1'b1,32'd0,71'd0,8'd64,ov,oh,od,rgb,2'd3,{1'b1,1'b0,8'd30,7'd20,7'd20,8'd9},status,diagnostic,patch,1'b1,8'h2a,address);
 always @(posedge clk)patch<=address[7:0]^{6'd0,address[9:8]};
 integer x,y,i,checked=0;reg expected_valid=0;reg [23:0] expected_rgb=0;
 reg [2:0] valid_delay=0;reg [23:0] rgb_delay[0:2];
 always @(posedge clk)begin
  if(!rst)begin valid_delay<=0;for(i=0;i<3;i=i+1)rgb_delay[i]<=0;end
  else begin
   valid_delay<={valid_delay[1:0],expected_valid};
   rgb_delay[0]<=expected_rgb;rgb_delay[1]<=rgb_delay[0];rgb_delay[2]<=rgb_delay[1];
  end
  #1;if(rst && valid_delay[2])begin
   if(!od || rgb!==rgb_delay[2])$fatal(1,"preview sync/RGB mismatch got=%h expected=%h",rgb,rgb_delay[2]);
   checked=checked+1;
  end
 end
 task frame_start;begin @(negedge clk);de=0;vs=1;@(negedge clk);vs=0;end endtask
 task char_at(input integer row_id,col_id,input [7:0] expected);begin
  force dut.x=944+col_id*16;force dut.y=80+row_id*16;force dut.de_d=1;de=1;#1;
  if(dut.expression_debug_char!==expected)$fatal(1,"debug glyph row=%0d col=%0d got=%c want=%c",row_id,col_id,dut.expression_debug_char,expected);
 end endtask
 function [7:0] value(input integer xx,yy);integer a;begin a=((yy-304)/4)*32+(xx-944)/4;value=(a&255)^(a>>8);end endfunction
 initial begin
  repeat(3)@(negedge clk);rst=1;frame_start;
  char_at(1,2,"1");char_at(1,9,"8");char_at(2,2,"8");char_at(2,9,"1");
  char_at(3,2,"1");char_at(4,2,"F");char_at(5,9,"F");
  char_at(6,3,"C");char_at(6,4,"4");char_at(6,9,"3");
  char_at(7,3,"2");char_at(7,4,"A");char_at(7,10,"2");char_at(7,11,"A");
  char_at(8,4,"1");char_at(8,10,"N");char_at(9,8,"A");char_at(9,9,"0");
  char_at(10,6,"1");char_at(10,13,"1");
  char_at(11,4,"H");char_at(11,7,"1");char_at(11,10,"1");char_at(11,13,"1");
  char_at(12,4,"1");char_at(12,11,"0");char_at(12,17,"0");char_at(13,0,"A");char_at(13,5,"1");char_at(13,8,"1");char_at(13,11,"0");char_at(13,14,"1");char_at(13,17,"1");
  status=0;diagnostic=0;char_at(1,2,"1");char_at(6,3,"C"); // midframe inputs must not tear
  de=0;release dut.x;release dut.y;release dut.de_d;
  frame_start;
  for(y=0;y<440;y=y+1)begin
   for(x=0;x<1280;x=x+1)begin
    @(negedge clk);de=1;
    expected_valid=x>=944 && x<1072 && y>=304 && y<432;
    expected_rgb={3{value(x,y)}};
   end
   @(negedge clk);de=0;expected_valid=0;repeat(3)@(negedge clk);
  end
  repeat(6)@(negedge clk);
  if(checked!=16384)$fatal(1,"preview coverage count %0d",checked);
  $display("PASS EXPRESSION DEBUG: signed32 raw scores/margin/contrast/reason/frame IDs, raw and actual label, eligibility/owner/profile/support/busy/capture glyphs, readable T/B/D/P/S action flags, frame snapshots, 16384 enlarged preview pixels aligned with video");$finish;
 end
 initial begin #8000000;$fatal(1,"timeout");end
endmodule
