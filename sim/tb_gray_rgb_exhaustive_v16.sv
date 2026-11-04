`timescale 1ns/1ps
// Independent integer-multiply oracle, exhaustive 24-bit RGB domain split over
// four lanes. Also verifies unchanged two-register markers, gaps and midstream reset.
module tb_gray_rgb_exhaustive_v16;
 reg clk=0,rst=0,valid=0,sof=0,last=0;always #5 clk=~clk;
 reg [95:0] data=0;wire[95:0] gray;wire gv,gs,gl;
 basic_gray_rgb96 dut(clk,rst,data,valid,sof,last,gray,gv,gs,gl);
 reg [95:0] expected_d=0,expected_out=0;
 reg valid_d=0,sof_d=0,last_d=0,want_valid,want_sof,want_last;
 integer beat,k,color,expected_value,pixels_checked=0,blank_sofs=0,reset_checks=0;
 always @(posedge clk)begin
  if(!rst)begin
   expected_d=0;valid_d=0;sof_d=0;last_d=0;
   #1;if(gray!==0 || gv!==0 || gs!==0 || gl!==0)$fatal(1,"gray reset contract");
   reset_checks=reset_checks+1;
  end else begin
   expected_out=expected_d;want_valid=valid_d;want_sof=sof_d;want_last=last_d;
   for(integer q=0;q<4;q=q+1)begin
    expected_value=(77*integer'(data[95-q*24-:8])+150*integer'(data[87-q*24-:8])+29*integer'(data[79-q*24-:8]))/256;
    expected_d[95-q*24-:24]={3{expected_value[7:0]}};
   end
   valid_d=valid;sof_d=sof;last_d=last;
   #1;
   if(gv!==want_valid || gs!==want_sof || gl!==want_last)$fatal(1,"two-clock marker contract changed");
   if(gray!==expected_out)$fatal(1,"exact grayscale mismatch beat=%0d got=%h expected=%h",beat,gray,expected_out);
   if(want_valid)pixels_checked=pixels_checked+4;
   if(want_sof && !want_valid)blank_sofs=blank_sofs+1;
  end
 end
 initial begin
  repeat(3)@(negedge clk);rst=1;
  for(beat=0;beat<4194304;beat=beat+1)begin
   if(beat==2097152)begin
    @(negedge clk);valid=0;sof=0;last=0;data=0;
    repeat(2)@(negedge clk);
    rst=0;valid=1;sof=1;last=1;data=96'hffffffffffffffffffffffff;
    repeat(2)@(negedge clk);rst=1;valid=0;sof=0;last=0;data=0;
   end
   if(beat%257==0)begin
    @(negedge clk);valid=0;sof=beat%1028==0;last=1;data=96'hff000000ff000000ff7f8081;
   end
   @(negedge clk);valid=1;sof=beat%640==0;last=beat%320==319;
   for(k=0;k<4;k=k+1)begin color=beat*4+k;data[95-k*24-:24]=color[23:0];end
  end
  @(negedge clk);valid=0;sof=1;last=0;data=0;
  @(negedge clk);sof=0;repeat(5)@(negedge clk);
  if(pixels_checked!=16777216)$fatal(1,"exhaustive RGB coverage count=%0d",pixels_checked);
  if(blank_sofs==0 || reset_checks<4)$fatal(1,"missing blank-SOF/reset coverage");
  $display("PASS GRAY EXHAUSTIVE V16: all16777216 RGB combinations across four lanes match independent 77R+150G+29B integer oracle; exact unchanged two-clock data/valid/SOF/last, gaps and blank-SOF, midstream reset, no truncation/saturation/rounding changes; blank_sofs=%0d reset_checks=%0d",blank_sofs,reset_checks);
  $finish;
 end
 initial begin #60000000;$fatal(1,"exhaustive gray timeout");end
endmodule
