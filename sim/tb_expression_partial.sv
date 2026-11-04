`timescale 1ns/1ps
module tb_expression_partial;
 reg clk=0,rst=0,b=0,w=0,f=0,clean=0,rot=0,low=0;always #5 clk=~clk;
 reg [5:0] x,y;reg [7:0] pixel;reg [31:0] face={2'b10,8'd20,7'd10,7'd50,8'd9};wire matched;
 ext_expression_motion dut(clk,rst,b,w,f,clean,rot,x,y,pixel,low,face,matched);
 reg [7:0] image[0:73727];integer xx,yy,v,seen=0,base;always @(posedge clk)if(matched)seen=seen+1;
 task patch(input integer kind,input bit learn);begin
 clean=learn;@(negedge clk);b=1;@(negedge clk);b=0;
 for(yy=0;yy<48;yy=yy+1)for(xx=0;xx<48;xx=xx+1)begin
 @(negedge clk);w=1;x=xx;y=yy;v=image[yy*48+xx];
 if((kind==1 && xx>=24)||(kind==2 && xx<24))v=255-v;
 if(kind==3)v=100;
 if(kind==4)v=(xx*97+yy*43+xx*yy*19)%256;
 pixel=v;
 end
 @(negedge clk);w=0;f=1;@(negedge clk);f=0;repeat(2)@(negedge clk);
 end endtask
 initial begin
 $readmemh("au_pixels.hex",image);repeat(3)@(negedge clk);rst=1;
 patch(1,0);patch(1,0);if(seen!=0)$fatal(1,"Half texture acquired without clean template");
 patch(0,1);patch(0,1);base=seen;
 patch(1,0);if(dut.full_match || seen!=base)$fatal(1,"Single partial texture bypassed confirmation");
 patch(1,0);if(seen!=base+1)$fatal(1,"Visible left half did not support after two fresh patches");
 patch(0,0);base=seen;
 patch(2,0);if(dut.full_match || seen!=base)$fatal(1,"Single right half bypassed confirmation");
 patch(2,0);if(seen!=base+1)$fatal(1,"Visible right half did not support");
 base=seen;patch(3,0);patch(3,0);patch(4,0);patch(4,0);if(seen!=base)$fatal(1,"Blank/foreign partial texture refreshed");
 face[29:22]=100;patch(0,0);patch(0,0);if(seen!=base)$fatal(1,"Foreign ROI reused appearance");
 $display("PASS PARTIAL APPEARANCE: real portrait, left/right occlusion, two fresh partial confirmations, no untrained acquisition, blank/foreign/owner rejection");$finish;
 end
 initial begin #10000000;$fatal(1,"partial timeout");end
endmodule
