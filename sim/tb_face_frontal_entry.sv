`timescale 1ns/1ps

module tb_face_frontal_entry;
 reg clk=0,rst=0,start=0;always #5 clk=~clk;
 reg [31:0] hint=0;reg [21:0] memory[0:14399];reg [21:0] q;
 wire busy,done,found,timeout;wire [7:0] x,votes;wire [6:0] y,size;wire [13:0] address;
 ext_face_lbp dut(clk,rst,start,busy,done,found,timeout,x,y,size,votes,address,q,hint);
 always @(posedge clk)q<=memory[address];
 integer round,cycles,reference_cycles;
 initial begin
  $readmemh("face_face_center_integral.hex",memory);
  repeat(3)@(negedge clk);rst=1;
  for(round=0;round<6;round=round+1)begin
   if(round==4)hint={1'b1,1'b0,x,y,size,8'd0};else hint=0;
   @(negedge clk);start=1;@(negedge clk);start=0;cycles=0;
   if(dut.model_pass!=0)$fatal(1,"real frontal entry did not start frontal");
   while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>12000001)$fatal(1,"scan hang");end
   if(!found || timeout || votes!=9 || dut.model_pass!=0)$fatal(1,"real frontal evidence degraded round=%0d votes=%0d",round,votes);
   if(round==0)reference_cycles=cycles;
   else if(cycles>reference_cycles)$fatal(1,"frontal entry slower with fallback history");
   $display("FRONTAL ENTRY round=%0d cycles=%0d votes=%0d",round,cycles,votes);
   repeat(3)@(negedge clk);
  end
  $display("PASS FACE FRONTAL ENTRY: six actual-cascade scans, constant full-view entry work, nine-vote frontal result and fast zero-support ROI recovery");$finish;
 end
 initial begin #300000000;$fatal(1,"timeout");end
endmodule
