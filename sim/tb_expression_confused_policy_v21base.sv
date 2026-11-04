`timescale 1ns/1ps
module tb_expression_confused_policy_v21base;
reg clk=0,rst=0;always #5 clk=~clk;wire busy,done;wire[1:0] label;wire[167:0] diag;
ext_expression_core #(.ENABLE_CUE(1),.ENABLE_MOUTH(1)) dut(clk,rst,1'b0,1'b0,12'd0,8'd0,8'd0,busy,done,label,diag,1'b0);
reg[15:0] brow[0:1535],old[0:1535],mouth[0:1535];reg[7:0] raw[0:1535],contrast[0:1535],orientation[0:1535],labels[0:1535],candidate[0:1535];integer i;
initial begin
 $readmemh("v21c_policy_brow.hex",brow);$readmemh("v21c_policy_old.hex",old);$readmemh("v21c_policy_mouth.hex",mouth);$readmemh("v21c_policy_raw.hex",raw);$readmemh("v21c_policy_contrast.hex",contrast);$readmemh("v21c_policy_orientation.hex",orientation);$readmemh("v21c_policy_label.hex",labels);$readmemh("v21c_policy_candidate.hex",candidate);
 repeat(3)@(negedge clk);rst=1;
 for(i=0;i<1536;i=i+1)begin
  @(negedge clk);dut.cue_scores[0]=brow[i];dut.cue_scores[1]=-32768;dut.au_scores[0]=-32768;dut.au_scores[1]=old[i];dut.au_scores[2]=0;dut.au_scores[3]=-32768;dut.au_scores[4]=-32768;dut.au_scores[5]=-32768;dut.mouth_score=mouth[i];dut.winner[0]=raw[i];dut.selected=0;dut.contrast=contrast[i];dut.orientation_confident=orientation[i];dut.margin0=100000;dut.happy_gap0=100000;
  #2;if(dut.confused!==candidate[i][0])$fatal(1,"C signed boundary %0d",i);
  dut.state=15;dut.O_busy=1;
  @(negedge clk);if(label!==labels[i][1:0] || diag[135]!==candidate[i][0])$fatal(1,"C overwrote V21 base decision at%0d got%0d want%0d",i,label,labels[i]);
 end
 $display("PASS V21 CONFUSED POLICY:1536 independent signed/brow/mouth/raw/contrast/orientation boundaries; base H/N/R/rejection exact, C requires already accepted V21 R, raw HAPPY/OTHER and low-quality protected");$finish;
end
initial begin #1000000;$fatal(1,"hang");end
endmodule
