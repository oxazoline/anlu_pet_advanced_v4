`timescale 1ns/1ps
module tb_face_roi;
 reg clk=0,rst=0,start=0;always #5 clk=~clk;
 reg [31:0] hint=0;reg [21:0] memory[0:14399];reg [21:0] q;
 wire busy,done,found,timeout;wire [7:0] x,votes;wire [6:0] y,size;wire [13:0] address;
 ext_face_lbp dut(clk,rst,start,busy,done,found,timeout,x,y,size,votes,address,q,hint);
 always @(posedge clk)q<=memory[address];
 integer round,cycles,full_cycles;reg [21:0] expected;
 initial begin
  $readmemh("face_face_center_integral.hex",memory);
  repeat(3)@(negedge clk);rst=1;
  for(round=0;round<2;round=round+1)begin
   @(negedge clk);start=1;@(negedge clk);start=0;cycles=0;
   while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>12000001)$fatal(1,"scan hang");end
   if(!found || timeout || votes!=9)$fatal(1,"ROI lost trained face evidence");
   if(round==0)begin
    full_cycles=cycles;expected={x,y,size};hint={1'b1,1'b0,x,y,size,votes};
   end else begin
    if({x,y,size}!==expected || cycles*2>=full_cycles)$fatal(1,"ROI should keep same face and more than halve scan work");
    $display("FACE ROI full_cycles=%0d local_cycles=%0d",full_cycles,cycles);
   end
   repeat(3)@(negedge clk);
  end
  $display("PASS FACE ROI: actual trained cascade, global and hinted rounds yield identical nine-vote face; local scan more than twice as fast");$finish;
 end
 initial begin #100000000;$fatal(1,"timeout");end
endmodule
