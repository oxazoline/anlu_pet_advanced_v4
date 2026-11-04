`timescale 1ns/1ps
module tb_face_zoom_policy;
 reg clk=0,rst=0;always #5 clk=~clk;
 wire [31:0] status;reg [31:0] candidate;reg prior_zoom=0;
 ext_face_detector dut(clk,rst,96'd0,1'b0,1'b0,status);
 integer width,i;reg expected;
 initial begin
  repeat(3)@(negedge clk);rst=1;
  force dut.global_hint=candidate;force dut.zoom=prior_zoom;
  for(i=0;i<2;i=i+1)begin
   prior_zoom=i;
   for(width=12;width<=88;width=width+1)begin
    candidate={1'b1,1'b0,8'd40,7'd1,width[6:0],8'd6};#1;
    expected=i ? width<=40 : width<=32;
    if(dut.choose_zoom!==expected)$fatal(1,"zoom threshold width=%0d state=%0d",width,i);
   end
  end
  // Hint fields chosen for each new capture must still fit the image.
  candidate={1'b1,1'b0,8'd65,7'd30,7'd29,8'd5};prior_zoom=0;#1;
  if(!dut.choose_zoom || dut.next_crop_x!=39 || dut.next_crop_y!=22)$fatal(1,"diagnostic seed lost zoom");
  candidate=0;force dut.next_zoom=0;#1;if(dut.choose_zoom)$fatal(1,"discovery full");
  force dut.next_zoom=1;#1;if(!dut.choose_zoom)$fatal(1,"discovery zoom");
  release dut.next_zoom;release dut.global_hint;release dut.zoom;
  $display("PASS FACE ZOOM POLICY: all sizes12..88 and both history states, detail restoration at24..32, bounded hysteresis, diagnostic seed crop and discovery schedule");$finish;
 end
endmodule
