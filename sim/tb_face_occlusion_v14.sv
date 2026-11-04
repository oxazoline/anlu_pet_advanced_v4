`timescale 1ns/1ps
module tb_face_occlusion_v14;
reg clk=0,rst=0,start=0;always #5 clk=~clk;
wire busy,done,found,tmo;wire[7:0] x,v;wire[6:0] y,w;wire[13:0] a;
reg[21:0] q,mem[0:14399];reg[31:0] expected[0:11];reg[511:0] file_name;
ext_face_lbp dut(clk,rst,start,busy,done,found,tmo,x,y,w,v,a,q,32'd0);
always @(posedge clk)q<=mem[a];
integer i,c;
initial begin
 $readmemh("profile_v14_expected.hex",expected);
 for(i=0;i<12;i=i+1)begin
  rst=0;repeat(3)@(negedge clk);rst=1;
  $sformat(file_name,"profile_v14_%0d.hex",i);$readmemh(file_name,mem);
  @(negedge clk);start=1;@(negedge clk);start=0;c=0;
  while(!done)begin @(negedge clk);c=c+1;if(c>12000010)$fatal(1,"profile watchdog");end
  if(tmo || found!=expected[i][31] || (found && {x,y,w,v}!=expected[i][29:0]))$fatal(1,"occlusion reference mismatch case=%0d got=%h exp=%h",i,{found,1'b0,x,y,w,v},expected[i]);
  $display("OCCLUSION case=%0d found=%0d votes=%0d cycles=%0d",i,found,v,c);
 end
 $display("PASS PROFILE OCCLUSION: actual cascades on four profile orientations with fixed forehead bands and four synthetic negatives; independent reference matches");$finish;
end
initial begin #1500000000;$fatal(1,"hang");end
endmodule
