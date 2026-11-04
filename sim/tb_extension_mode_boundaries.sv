`timescale 1ns/1ps
module tb_extension_mode_boundaries;
reg clk=0,rst=0;always #5 clk=~clk;wire busy,done;wire[1:0] label;wire[167:0] diag;
ext_expression_core #(.ENABLE_CUE(1),.ENABLE_MOUTH(1),.BALANCED_POLICY(1),.FULL_SCORE_DEBUG(0),.V22_POLICY(1),.ENABLE_CBROW(1),.CONFUSED_GUARD(1)) dut(clk,rst,1'b0,1'b0,12'd0,8'd0,8'd0,busy,done,label,diag,1'b0);
integer b,j,m,r,c,o,bi,ji,mi,count=0;reg ex,eq;integer bs[0:3],js[0:3],ms[0:3];
initial begin
 bs[0]=-129;bs[1]=-128;bs[2]=-1;bs[3]=0;js[0]=383;js[1]=384;js[2]=767;js[3]=768;ms[0]=127;ms[1]=128;ms[2]=255;ms[3]=256;
 repeat(3)@(negedge clk);rst=1;dut.selected=0;
 for(bi=0;bi<4;bi=bi+1)for(ji=0;ji<4;ji=ji+1)for(mi=0;mi<4;mi=mi+1)for(r=0;r<4;r=r+1)for(c=23;c<=24;c=c+1)for(o=0;o<2;o=o+1)begin
  b=bs[bi];j=js[ji];m=ms[mi];dut.cbrow_scores[0]=b;dut.cbrow_scores[1]=j;dut.mouth_score=m;dut.winner[0]=r;dut.contrast=c;dut.orientation_confident=o;
  ex=b>=-128 && j>=384 && m>=128 && r!=0 && c>=24 && o;eq=b>=0 && j>=768 && m>=256;
  #2;if(dut.confused!==ex || dut.au_debug[27]!==eq || dut.mouth_open!==(m>=128))$fatal(1,"mode boundary mismatch b%0d j%0d m%0d",b,j,m);count=count+1;
 end
 if(count!=1024)$fatal(1,"coverage count");
 $display("PASS MODE BOUNDARIES:1024 signed normal-brow-128/mouth128/joint384 and strong-profile0/256/768 raw/contrast/orientation boundary combinations");$finish;
end
initial begin #100000;$fatal(1,"hang");end
endmodule
