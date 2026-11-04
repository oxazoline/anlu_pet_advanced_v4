`timescale 1ns/1ps
module tb_face_profile_roi;
 reg clk=0,rst=0,start=0;always #5 clk=~clk;reg [31:0] hint=0;
 reg [21:0] memory[0:14399];reg [21:0] q;
 wire busy,done,found,timeout;wire [7:0] x,votes;wire [6:0] y,size;wire [13:0] addr;
 ext_face_lbp dut(clk,rst,start,busy,done,found,timeout,x,y,size,votes,addr,q,hint);
 always @(posedge clk)q<=memory[addr];
 integer round,cycles,full_cycles,direction;
 initial begin
  $readmemh("face_profile_right_upside_integral.hex",memory);
  repeat(3)@(negedge clk);rst=1;
  for(round=0;round<6;round=round+1)begin
   @(negedge clk);start=1;@(negedge clk);start=0;cycles=0;
   if(round>0 && dut.model_pass!=((round==2 || round==4)?0:direction))$fatal(1,"real profile direction not first");
   while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>12000001)$fatal(1,"profile scan hung");end
   if(!found || timeout || !votes[7] || votes[6:0]<2)$fatal(1,"real profile evidence lost round=%0d found=%0d timeout=%0d votes=%0d pass=%0d",round,found,timeout,votes,dut.model_pass);
   if(round==0)begin
    if(votes[6:0]<5)$fatal(1,"profile cannot seed acquisition");
    full_cycles=cycles;direction=dut.remembered_pass;hint={1'b1,1'b0,x,y,size,votes};
   end else begin
    if(cycles>=full_cycles)$fatal(1,"remembered direction did not reduce work");
    $display("PROFILE ROI round=%0d first_cycles=%0d hinted_cycles=%0d remembered_pass=%0d probe=%0d",round,full_cycles,cycles,direction,dut.frontal_probe_first);
   end
   repeat(3)@(negedge clk);
  end
  $display("PASS FACE PROFILE ROI: real inverted profile, strong first acquisition evidence, remembered direction, periodic frontal-probe fallback and faster hinted re-detection");$finish;
 end
 initial begin #250000000;$fatal(1,"timeout");end
endmodule
