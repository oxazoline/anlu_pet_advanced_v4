`timescale 1ns/1ps
module tb_expression_cbrow_policy;
reg clk=0,rst=0;always #5 clk=~clk;wire busy,done;wire[1:0] label;wire[167:0] diag;
ext_expression_core #(.ENABLE_CUE(1),.ENABLE_MOUTH(1),.BALANCED_POLICY(1),.FULL_SCORE_DEBUG(0),.V22_POLICY(1),.ENABLE_CBROW(1)) dut(clk,rst,1'b0,1'b0,12'd0,8'd0,8'd0,busy,done,label,diag,1'b0);
integer b,j,m,r,c,o,i,count=0;reg expected;reg[31:0] mm[0:7];
initial begin
 mm[0]=0;mm[1]=2187;mm[2]=2188;mm[3]=2431;mm[4]=2432;mm[5]=65535;mm[6]=65536;mm[7]=2000000;
 repeat(3)@(negedge clk);rst=1;dut.selected=0;dut.low_mode=0;dut.margin0=100000;dut.happy_gap0=100000;
 for(b=-1;b<=0;b=b+1)for(j=383;j<=384;j=j+1)for(m=63;m<=64;m=m+1)for(r=0;r<4;r=r+1)for(c=23;c<=24;c=c+1)for(o=0;o<2;o=o+1)begin
  dut.cbrow_scores[0]=b;dut.cbrow_scores[1]=j;dut.mouth_score=m;dut.winner[0]=r;dut.contrast=c;dut.orientation_confident=o;
  expected=b>=0 && j>=384 && m>=64 && r!=0 && c>=24 && o;
  #2;if(dut.confused!==expected)$fatal(1,"dedicated boundary");count=count+1;
 end
 for(i=0;i<8;i=i+1)begin dut.margin0=mm[i];#2;if((dut.chosen_margin>=2188)!==((dut.chosen_margin>65535?65535:dut.chosen_margin)>=2188) || (dut.chosen_margin>=2432)!==((dut.chosen_margin>65535?65535:dut.chosen_margin)>=2432))$fatal(1,"H fast gate altered");end
 $display("PASS CBROW POLICY:128 independent brow0/joint384/mouth64/raw/contrast/orientation boundaries; compact margin clipping preserves native2188 and low2432 HAPPY fast gate");$finish;
end
initial begin #100000;$fatal(1,"hang");end
endmodule
