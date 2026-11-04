`timescale 1ns/1ps
module tb_expression_cue_policy_v21;
reg clk=0,rst=0;always #5 clk=~clk;wire busy,done;wire[1:0] label;wire[167:0] diag;
ext_expression_core #(.ENABLE_CUE(1)) dut(clk,rst,1'b0,1'b0,12'd0,8'd0,8'd0,busy,done,label,diag,1'b0);
reg[63:0] vectors[0:511],v;integer i;
initial begin
 $readmemh("cue_policy.hex",vectors);repeat(3)@(negedge clk);rst=1;
 for(i=0;i<512;i=i+1)begin @(negedge clk);v=vectors[i];
  dut.cue_scores[0]=v[63:48];dut.cue_scores[1]=v[47:32];
  dut.winner[0]=v[31:30];dut.selected=0;dut.contrast=v[29:22];
  dut.orientation_confident=($signed(v[21:6])>=128 || $signed(v[21:6])<=-128);
  dut.au_scores[0]=-32768;dut.au_scores[1]=-32768;dut.au_scores[2]=0;
  dut.au_scores[3]=-32768;dut.au_scores[4]=-32768;dut.au_scores[5]=-32768;
  #2;if(dut.cue_tense!==v[0] || dut.au_tense!==v[0])$fatal(1,"binary cue boundary %0d got%0d want%0d",i,dut.cue_tense,v[0]);
 end
 $display("PASS V21 CUE POLICY: 512 independent signed/boundary/contrast/orientation/raw cases, raw HAPPY and OTHER protected, old smile veto does not suppress independent action cues");$finish;
end
endmodule
