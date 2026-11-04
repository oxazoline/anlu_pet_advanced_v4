`timescale 1ns/1ps
module tb_expression_confused_limits_v21base;
reg clk=0,rst=0;always #5 clk=~clk;wire busy,done;wire[1:0] label;wire[167:0] diag;
ext_expression_core #(.ENABLE_CUE(1),.ENABLE_MOUTH(1)) dut(clk,rst,1'b0,1'b0,12'd0,8'd0,8'd0,busy,done,label,diag,1'b0);
reg[8:0] f[0:129023];reg[31:0] partial[0:63];reg[15:0] score[0:63];reg modes[0:63];integer k,i,c,clip=0;
initial begin
 $readmemh("mouth_limits_features.hex",f);$readmemh("mouth_limits_partial.hex",partial);$readmemh("mouth_limits_scores.hex",score);$readmemh("mouth_limits_modes.hex",modes);
 repeat(3)@(negedge clk);rst=1;
 for(k=0;k<64;k=k+1)begin
  @(negedge clk);for(i=0;i<2016;i=i+1)dut.histogram[i]=f[k*2016+i];
  dut.au_orientation=0;dut.low_mode=modes[k];dut.cue_phase=1;dut.au_feature_address=531;dut.feature_index=0;dut.weight_word=958;dut.au_slot=0;
  dut.mouth_partial[0]=partial[k];dut.accumulator=$signed(partial[k])+dut.mouth_bias(modes[k]);dut.state=29;dut.O_busy=1;
  @(negedge clk);c=0;while(!done)begin @(negedge clk);c=c+1;if(c>1600)$fatal(1,"local mouth deadline");end
  if(dut.mouth_score!==score[k])$fatal(1,"mouth legal MAC bounds%0d got%0d want%0d",k,$signed(dut.mouth_score),$signed(score[k]));
  if(score[k]==16'h7fff || score[k]==16'h8000)clip=clip+1;
 end
 if(clip<2)$fatal(1,"saturation not exercised");
 $display("PASS V21 BASE MOUTH LIMITS:64 legal histogram/main-hidden extrema and interiors, exact selected504 features/packed signed4 weights/mode biases and signed16 saturation");$finish;
end
initial begin #2000000;$fatal(1,"hang");end
endmodule
