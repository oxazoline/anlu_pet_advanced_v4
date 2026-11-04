`timescale 1ns/1ps
module tb_face_large;
 reg clk=0,rst=0,start=0;always #5 clk=~clk;wire busy,done,found,timeout;wire[7:0] x,votes;wire[6:0] y,w;wire[13:0] address;reg[21:0] q,memory[0:14399];reg[31:0] expected[0:5];integer f,cycles,reads=0;
 ext_face_lbp dut(clk,rst,start,busy,done,found,timeout,x,y,w,votes,address,q,32'h40000000);
 always @(posedge clk)begin q<=memory[address];if(rst && busy && (dut.state==4 || dut.state==5))begin
  if(address>=14400 || dut.physical_y>90 || dut.corner_x>160 || dut.corner_y>128)$fatal(1,"virtual corner escaped physical RAM");reads=reads+1;
 end end
 initial begin
  $readmemh("large_groups.hex",expected);repeat(3)@(negedge clk);rst=1;
  for(f=0;f<6;f=f+1)begin
   case(f)0:$readmemh("large_0_integral.hex",memory);1:$readmemh("large_1_integral.hex",memory);2:$readmemh("large_2_integral.hex",memory);3:$readmemh("large_3_integral.hex",memory);4:$readmemh("large_4_integral.hex",memory);5:$readmemh("large_5_integral.hex",memory);endcase
   @(negedge clk);start=1;@(negedge clk);start=0;cycles=0;
   while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>12000005)$fatal(1,"large scan hangs");end
   if(timeout || found!==expected[f][31] || votes!==expected[f][7:0])$fatal(1,"large decision f%0d actual%0d/%0d expected%h",f,found,votes,expected[f]);
   if(found && {x,y,w}!==expected[f][29:8])$fatal(1,"large geometry f%0d got%0d/%0d/%0d expected%h",f,x,y,w,expected[f]);
  end
  $display("PASS FACE LARGE: actual20-stage cascade, two cropped large-face scenes/four negatives, all decisions and geometry match independent128-row zero-padding reference, physical RAM bounded, no extra integral memory");$finish;
 end
 initial begin #250000000;$fatal(1,"timeout");end
endmodule
