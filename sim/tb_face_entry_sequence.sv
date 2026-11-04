`timescale 1ns/1ps
module tb_face_entry_sequence;
 reg clk=0,rst=0,v=0,sof=0;always #5 clk=~clk;
 reg [95:0] data=0;wire [31:0] status;
 reg [31:0] pixels[0:691199];
 ext_face_detector dut(clk,rst,data,v,sof,status);
 integer frame,y,x,k,index,cycles;reg [7:0] g;integer hits=0;
 initial begin
  $readmemh("reliability_gray4.hex",pixels);
  repeat(3)@(negedge clk);rst=1;index=0;
  for(frame=0;frame<3;frame=frame+1)begin
   @(negedge clk);sof=1;v=0;@(negedge clk);sof=0;
   $display("ENTRY FIELD frame=%0d zoom=%0d crop=%0d,%0d",frame,dut.zoom,dut.crop_x,dut.crop_y);
   for(y=0;y<720;y=y+1)for(x=0;x<320;x=x+1)begin
    @(negedge clk);v=1;
    for(k=0;k<4;k=k+1)begin g=pixels[index][31-k*8-:8];data[95-k*24-:24]={3{g}};end
    index=index+1;
   end
   @(negedge clk);v=0;cycles=0;
   while(!dut.done)begin @(negedge clk);cycles=cycles+1;if(cycles>12000010)$fatal(1,"detector hang");end
   if(dut.timeout)$fatal(1,"unexpected classifier timeout");
   if(dut.found && dut.neighbors[6:0]>=5)hits=hits+1;
   $display("ENTRY RESULT frame=%0d found=%0d votes=%0d box=%0d,%0d,%0d wait_cycles=%0d",frame,dut.found,dut.neighbors,dut.mapped_x,dut.mapped_y,dut.mapped_size,cycles);
   repeat(4)@(negedge clk);
   if(frame<2 && status[31])$fatal(1,"entry bypassed three strong detections");
  end
  $display("ENTRY_SEQUENCE_RESULT visible=%0d strong_frames=%0d status=%h",status[31],hits,status);
  if(!$test$plusargs("comparison_only"))begin
   if(hits!=3 || !status[31] || status[6:0]<5 || status[7])$fatal(1,"detail-preserving three-frame frontal acquisition failed");
   $display("PASS FACE ENTRY SEQUENCE: real pixel capture, integral RAM, cascade and tracker; three strong fresh results acquire a translated 240px public face");
  end
  $finish;
 end
 initial begin #450000000;$fatal(1,"test timeout");end
endmodule
