`timescale 1ns/1ps
module tb_expression_capture;
 reg clk=0,rst=0,v=0,sof=0;always #5 clk=~clk;reg[95:0] rgb=0;reg[31:0] face=0;wire[31:0] status;
 ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.BALANCED_POLICY(0),.ENABLE_AU(0)) dut(clk,rst,rgb,v,sof,face,status,,,,,,);
 integer y,x,k,i,j,px,py,wr=0,cwr=0,expected,pattern=0,l,t,ww,completed=0,grid,denom,ix,iy;reg[7:0] preview[0:1023];reg profile=0,coast=0;
 function[7:0] gray(input integer x,y);begin case(pattern)0:gray=(x*7+y*11)%256;1:gray=(x+y)%2?255:0;2:gray=255;default:gray=(x*x+3*y*y+31*x*y)%256;endcase end endfunction
 task frame_start;begin @(negedge clk);v=0;sof=1;@(negedge clk);sof=0;end endtask
 always @(posedge clk)if(rst)begin
  if(dut.selected)begin if(dut.core_address!==cwr[11:0])$fatal(1,"core address order");cwr=cwr+1;end
  if(dut.O_patch_write)begin if(dut.O_patch_address!==wr[9:0])$fatal(1,"preview address order");preview[wr]=dut.O_patch_pixel;wr=wr+1;end
 end
 task camera(input integer rows);begin
  for(y=0;y<rows;y=y+1)for(x=0;x<320;x=x+1)begin
   if((y+x)%17==3)begin @(negedge clk);v=0;end
   @(negedge clk);v=1;for(k=0;k<4;k=k+1)rgb[95-k*24-:24]={3{gray(x*4+k,y)}};
  end
  @(negedge clk);v=0;repeat(3)@(negedge clk);
 end endtask
 function integer mean4(input integer xx,yy);begin mean4=(integer'(gray(xx-1,yy-1))+integer'(gray(xx,yy-1))+integer'(gray(xx-1,yy))+integer'(gray(xx,yy))+2)/4;end endfunction
 task check_patch(input integer left,top,width,kind);begin
  pattern=kind;l=left;t=top;ww=width;wr=0;cwr=0;grid=width<24?32:48;denom=width<24?8:12;
  face={1'b1,1'b0,8'(left/8),7'(top/8),7'(width),(profile?8'd137:8'd9)};frame_start;if(coast)begin @(negedge clk);face[6:0]=0;end camera(720);
  if(wr!=1024 || cwr!=grid*grid || dut.capture)$fatal(1,"patch incomplete w%0d preview%0d core%0d",width,wr,cwr);
  for(j=0;j<grid;j=j+1)for(i=0;i<grid;i=i+1)begin
   px=left+((2*i+1)*width)/denom;py=top+((2*j+1)*width)/denom;expected=mean4(px,py);
   if(dut.core.patch[j*grid+i]!==expected[7:0])$fatal(1,"sample mismatch w%0d (%0d,%0d) got%0d want%0d",width,i,j,dut.core.patch[j*grid+i],expected);
  end
  for(j=0;j<32;j=j+1)for(i=0;i<32;i=i+1)begin
   ix=grid==32?i:(3*i+1)/2;iy=grid==32?j:(3*j+1)/2;
   expected=mean4(left+((2*ix+1)*width)/denom,top+((2*iy+1)*width)/denom);
   if(preview[j*32+i]!==expected[7:0])$fatal(1,"native-to-preview resample mismatch");
  end
  completed=completed+1;
 end endtask
 initial begin
  repeat(3)@(negedge clk);rst=1;force dut.start=0;
  check_patch(320,160,25,0);check_patch(0,0,16,1);check_patch(736,176,68,2);check_patch(0,0,90,3);check_patch(64,48,17,3);
  check_patch(320,160,24,1);check_patch(320,160,23,0);
  profile=1;check_patch(320,160,32,0);coast=1;check_patch(256,0,88,0);profile=0;coast=0;
  wr=0;cwr=0;face={1'b1,1'b0,8'd40,7'd20,7'd25,8'd9};frame_start;camera(170);check_patch(320,160,25,1);
  face={1'b1,1'b0,8'd0,7'd0,7'd15,8'd9};frame_start;if(dut.capture || status[15:12]!=11)$fatal(1,"small ROI rejection");
  face={1'b1,1'b0,8'd0,7'd0,7'd91,8'd9};frame_start;if(dut.capture || status[15:12]!=13)$fatal(1,"native48 last-point bounds");
  $display("PASS EXPRESSION CAPTURE: ten native48/native32 geometries including real supported-P and large H/P pixel streams, every2x2 pixel against independent coordinate division, exact48-to32 preview, minimum stride/all phases/gaps/white/edges/partial restart and mode-aware bounds");$finish;
 end
 initial begin #40000000;$fatal(1,"capture timeout");end
endmodule
