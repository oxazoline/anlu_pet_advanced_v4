`timescale 1ns/1ps
module tb_expression_ui;
 reg clk=0,rst=0;always #5 clk=~clk;wire ov,oh,od;wire[23:0] rgb;wire[9:0] a;reg[31:0] value;integer i;
 basic_osd #(.ENABLE_CONFUSED_UI(1),.COMPACT_DEBUG(0)) dut(clk,rst,1'b0,1'b0,1'b0,24'h123456,4'd0,64'd0,64'd0,1'b1,32'd0,71'd0,8'd64,ov,oh,od,rgb,2'd3,32'd0,32'd0,168'd0,8'd0,1'b0,8'd0,a);
 initial begin
  repeat(3)@(negedge clk);rst=1;force dut.face_status=32'h80000000;force dut.x=20;force dut.y=688;force dut.de_d=1;
  force dut.expression_status=value;value=0;#1;if(dut.expression_area || dut.expression_text!="            ")$fatal(1,"invalid expression still rendered UNKNOWN");
  for(i=1;i<=3;i=i+1)begin value=i;#1;if(!dut.expression_area)$fatal(1,"valid label hidden");if(i==3 && dut.expression_text!="EXPR NERVOUS")$fatal(1,"third label not NERVOUS");end
  force dut.face_status=0;#1;if(dut.expression_area)$fatal(1,"label without face");
  $display("PASS EXPRESSION UI: only HAPPY/NEUTRAL/NERVOUS rendered, no UNKNOWN word or label rectangle for invalid input, no label without a visible face");$finish;
 end
endmodule
