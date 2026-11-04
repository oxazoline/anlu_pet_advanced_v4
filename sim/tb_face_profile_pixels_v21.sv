`timescale 1ns/1ps
module tb_face_profile_pixels_v21;
reg clk=0,rst=0,start=0;always #5 clk=~clk;
wire busy,done,found,tmo;wire[7:0] x,v;wire[6:0] y,w;wire[13:0] a;
reg[21:0] mem[0:14399],q;reg[31:0] expected[0:23];reg[511:0] file_name;
ext_face_lbp dut(clk,rst,start,busy,done,found,tmo,x,y,w,v,a,q,32'd0);
always @(posedge clk)q<=mem[a];
integer scene,rnd,c,index;
initial begin
 $readmemh("profile_phase_expected.hex",expected);
 for(scene=0;scene<6;scene=scene+1)begin
  rst=0;repeat(3)@(negedge clk);rst=1;
  $sformat(file_name,"profile_phase_pixels_%0d.hex",scene);$readmemh(file_name,mem);
  for(rnd=0;rnd<4;rnd=rnd+1)begin
   @(negedge clk);start=1;@(negedge clk);start=0;c=0;
   while(!done)begin @(negedge clk);c=c+1;if(c>12000010)$fatal(1,"profile watchdog");end
   index=scene*4+rnd;
   if(tmo || found!==expected[index][31] || (found && {x,y,w,v}!==expected[index][29:0]))$fatal(1,"profile pixel scene%0d round%0d got%h want%h",scene,rnd,{found,1'b0,x,y,w,v},expected[index]);
   $display("PROFILE PARITY scene=%0d round=%0d found=%0d phase=%0d clocks=%0d",scene,rnd,found,dut.profile_phase_active,c);
  end
 end
 $display("PASS V21 PROFILE PIXELS: both mirrored forehead-band scenes converge from missed even grid to odd-row hits, independent exact geometry/votes, four persistent negative scenes across all four phases");$finish;
end
initial begin #2000000000;$fatal(1,"hang");end
endmodule
