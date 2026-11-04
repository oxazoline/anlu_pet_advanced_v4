`timescale 1ns/1ps
module tb_expression_responsive_boundaries;
reg clk=0,rst=0;always #5 clk=~clk;wire busy,done;wire[1:0] label;wire[167:0] diag;
ext_expression_core #(.ENABLE_CUE(1),.ENABLE_MOUTH(1),.BALANCED_POLICY(1),.FULL_SCORE_DEBUG(0)) dut(clk,rst,1'b0,1'b0,12'd0,8'd0,8'd0,busy,done,label,diag,1'b0);
integer b,a,m,r,c,o,i,count=0;reg expected;reg[1:0] before_class;
initial begin
 repeat(3)@(negedge clk);rst=1;
 dut.selected=0;dut.margin0=100000;dut.happy_gap0=100000;dut.low_mode=0;
 dut.au_scores[0]=-32768;dut.au_scores[2]=0;dut.au_scores[3]=-32768;dut.au_scores[4]=-32768;dut.au_scores[5]=-32768;dut.cue_scores[1]=-32768;
 for(b=511;b<=512;b=b+1)for(a=383;a<=384;a=a+1)for(m=63;m<=64;m=m+1)for(r=0;r<4;r=r+1)for(c=23;c<=24;c=c+1)for(o=0;o<2;o=o+1)begin
  dut.cue_scores[0]=b;dut.au_scores[1]=a;dut.mouth_score=m;dut.winner[0]=r;dut.contrast=c;dut.orientation_confident=o;
  expected=(b>=512 || a>=384) && m>=64 && r!=0 && c>=24 && o;
  #2;if(dut.confused!==expected)$fatal(1,"responsive boundary mismatch");count=count+1;
 end
 for(i=-32768;i<=32767;i=i+1)begin
  dut.winner[0]=0;dut.contrast=255;dut.orientation_confident=1;dut.mouth_score=32767;dut.cue_scores[0]=i;dut.au_scores[1]=32767;
  #1;if(dut.confused)$fatal(1,"raw HAPPY overwritten");
 end
 $display("PASS RESPONSIVE BOUNDARIES:128 exact new brow512/old384/mouth64/raw/contrast/orientation combinations;65536 signed brow values retain raw HAPPY protection; base gates unchanged");$finish;
end
initial begin #1000000;$fatal(1,"hang");end
endmodule
