`timescale 1ns/1ps
module tb_advanced_v4_pet;
reg clk=0,rst=0,vs=0,de=0;reg[31:0]refbox=0,face=0,expr=0;wire ov,oh,od;wire[23:0]o;
always #5 clk=~clk;
adv_pet_overlay dut(clk,rst,vs,1'b0,de,24'h365978,refbox,face,expr,ov,oh,od,o);
reg[23:0]gold[0:16383];reg[23:0]q0,q1,q2,e;reg d0,d1,d2;integer n,x,y,drivex=0,drivey=0,sx,sy,addr,pose,px,py,mirror,seen=0,f=0;
always @(posedge clk)begin
 if(!rst)begin q0=0;q1=0;q2=0;d0=0;d1=0;d2=0;end
 else begin
 e=24'h365978;
 if(de && drivex>=px && drivex<px+192 && drivey>=py && drivey<py+288)begin
 sx=(drivex-px)/4;sy=(drivey-py)/4;if(mirror)sx=47-sx;
 addr=pose*4096+sy*48+sx;e=gold[addr];seen=seen+1;
 end
 q2=q1;q1=q0;q0=de?e:0;d2=d1;d1=d0;d0=de;
 #1;if(od && f!=0)$fwrite(f,"%c%c%c",o[23:16],o[15:8],o[7:0]);
 if(od!==d2 || o!==q2)$fatal(1,"pet pixel/latency mismatch n%0d x%0d y%0d rgb%h expected%h",n,x,y,o,q2);
 end
end
initial begin
 $readmemh("pet_expected.hex",gold);repeat(4)@(negedge clk);rst=1;
 for(n=0;n<7;n=n+1)begin
  face=32'h80000000;expr=0;refbox=0;pose=0;px=1072;py=416;mirror=0;
  case(n)
   1:begin expr=1;pose=1;end
   2:begin expr=3;pose=2;end
   3:begin expr=1;face=0;end
   4:begin refbox={1'b1,1'b0,8'd20,7'd20,8'd30,7'd20};pose=3;px=408;py=96;mirror=1;expr=1;end
   5:begin refbox={1'b1,1'b0,8'd100,7'd20,8'd20,7'd20};pose=3;px=600;py=96;expr=3;end
   6:expr=2;
  endcase
  if(n==0)f=$fopen("pet_neutral.ppm","wb");
  else if(n==4)f=$fopen("pet_rice_left.ppm","wb");
  else if(n==5)f=$fopen("pet_rice_right.ppm","wb");
  else f=0;
  if(f!=0)$fwrite(f,"P6\n1280 720\n255\n");
  @(negedge clk);vs=1;de=0;@(negedge clk);vs=0;
  for(y=0;y<720;y=y+1)begin
   for(x=0;x<1280;x=x+1)begin @(negedge clk);de=1;drivex=x;drivey=y;end
   @(negedge clk);de=0;repeat(3)@(negedge clk);
  end
  repeat(5)@(negedge clk);if(f!=0)$fclose(f);f=0;
 end
 if(seen!=7*192*288)$fatal(1,"sprite coverage wrong %0d",seen);
 $display("PASS ADVANCED V4 PET: all pixels of seven720p frames, HAPPY/R/neutral mapping, missing-face neutral, Rice priority, mirrored left/right placement and aligned RGB/DE");$finish;
end
initial begin #100000000;$fatal(1,"pet timeout");end
endmodule
