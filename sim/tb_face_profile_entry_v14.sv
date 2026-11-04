`timescale 1ns/1ps
module tb_face_profile_entry_v14;
reg clk=0,rst=0,start=0;always #5 clk=~clk;reg[31:0] hint=0;
wire busy,done,found,tmo;wire[7:0] x,v;wire[6:0] y,w;wire[13:0] a;wire[31:0] status;
reg[21:0] q,mem[0:14399];
ext_face_lbp dut(clk,rst,start,busy,done,found,tmo,x,y,w,v,a,q,hint);
ext_face_track #(.HOLD_CYCLES(31056000),.ACQUIRE_CYCLES(103520000)) tracker(clk,rst,done,found,tmo,x,y,w,v,status);
always @(posedge clk)q<=mem[a];
integer i,c;
initial begin
 $readmemh("profile_v14_1.hex",mem);
 repeat(3)@(negedge clk);rst=1;
 for(i=0;i<5;i=i+1)begin
  @(negedge clk);start=1;@(negedge clk);start=0;c=0;
  while(!done)begin @(negedge clk);c=c+1;if(c>12000001)$fatal(1,"timeout");end
  repeat(2)@(negedge clk);
  if(tmo || !found || !v[7] || v[6:0]<3)$fatal(1,"masked actual-profile evidence lost round=%0d votes=%0d",i,v);
  if(i<4 && status[31])$fatal(1,"weak actual-profile early acquisition");
  hint={1'b1,1'b0,x,y,w,v};
  $display("MASKED ENTRY round=%0d votes=%0d visible=%0d cycles=%0d",i,v,status[31],c);
 end
 if(!status[31])$fatal(1,"five actual weak-profile observations did not acquire");
 $display("PASS ACTUAL PROFILE ENTRY: five actual cascade/tracker scans of a fixed forehead-occluded portrait, localized repeat confirmation and no early acquisition");$finish;
end
initial begin #600000000;$fatal(1,"hang");end
endmodule
