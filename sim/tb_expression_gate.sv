`timescale 1ns/1ps
module tb_expression_gate;
 reg clk=0,rst=0;always #5 clk=~clk;wire busy,done;wire[1:0] label;wire[167:0] diag;
 ext_expression_core #(.ENABLE_AU(0)) dut(clk,rst,1'b0,1'b0,12'd0,8'd0,8'd100,busy,done,label,diag,1'b0);
 reg[31:0] limits[0:1];integer mode,orient,cases=0;
 task trial(input integer low,input integer rot,input integer gap,input integer margin,input integer winner,input integer contrast,input integer expected,input integer reason);
 begin
  @(negedge clk);
  dut.low_mode=low;dut.selected=rot;dut.contrast=contrast;
  dut.winner[rot]=winner;dut.margin0=margin;dut.margin1=margin;
  dut.happy_gap0=gap;dut.happy_gap1=gap;
  dut.state=dut.FINISH;
  @(negedge clk);#1;
  if(!done || label!==expected || diag[163:160]!==reason)$fatal(1,"mode=%0d rot=%0d gap=%0d label=%0d reason=%0d want=%0d/%0d",low,rot,gap,label,diag[163:160],expected,reason);
  cases=cases+1;
 end endtask
 integer threshold,gap_limit;
 initial begin
  $readmemh("expression_competitor_gaps.hex",limits);
  repeat(3)@(negedge clk);rst=1;
  if(dut.HAPPY_TENSE_GAP!==limits[0] || dut.LOW_HAPPY_TENSE_GAP!==limits[1])$fatal(1,"competitor calibration constants");
  for(mode=0;mode<2;mode=mode+1)for(orient=0;orient<2;orient=orient+1)begin
   gap_limit=$signed(limits[mode]);threshold=mode?dut.low_class_margin(0):dut.class_margin(0);
   trial(mode,orient,gap_limit-1,threshold+1,0,100,0,4);
   trial(mode,orient,gap_limit,threshold+1,0,100,1,0);
   trial(mode,orient,-100,threshold+1,0,100,0,4);
   trial(mode,orient,gap_limit+1,threshold-1,0,100,0,3);
   trial(mode,orient,gap_limit+1,threshold+1,0,23,0,1);
   threshold=mode?dut.low_class_margin(2):dut.class_margin(2);
   trial(mode,orient,-100,threshold,2,100,3,0);
   trial(mode,orient,gap_limit+1,32'h7fffffff,3,100,0,2);
  end
  if(cases!=28)$fatal(1,"coverage");
  $display("PASS EXPRESSION GATE: both resolutions/orientations, signed HAPPY-vs-tense competitor rejection, exact gate/global-margin boundaries, no rejection of valid NERVOUS, contrast and OTHER isolation");$finish;
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
