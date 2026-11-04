`timescale 1ns/1ps
module tb_expression_cue_limits_v21;
reg clk=0,rst=0;always #5 clk=~clk;wire busy,done;wire[1:0] label;wire[167:0] diag;
ext_expression_core #(.ENABLE_CUE(1)) dut(clk,rst,1'b0,1'b0,12'd0,8'd0,8'd128,busy,done,label,diag,1'b0);
reg[7:0] h[0:4095];reg[15:0] s[0:1023];integer f,i,c;
initial begin
 $readmemh("cue_limits_hidden.hex",h);$readmemh("cue_limits_scores.hex",s);
 repeat(3)@(negedge clk);rst=1;
 for(f=0;f<512;f=f+1)begin
  @(negedge clk);for(i=0;i<8;i=i+1)dut.hidden[i]=h[f*8+i];
  dut.cue_phase=1;dut.au_output=0;dut.head_index=0;dut.weight_word=954;dut.au_slot=0;
  dut.accumulator=dut.cue_bias2(0);dut.state=19;dut.O_busy=1;c=0;
  @(negedge clk);while(!done)begin @(negedge clk);c=c+1;if(c>60)$fatal(1,"head deadline");end
  for(i=0;i<2;i=i+1)if(dut.cue_scores[i]!==s[f*2+i])$fatal(1,"cue corners f=%0d i=%0d got%0d want%0d",f,i,$signed(dut.cue_scores[i]),$signed(s[f*2+i]));
 end
 $display("PASS V21 CUE LIMITS: all256 hidden corners and256 interiors through actual shared signed4/signed8 ROM phase, exact two logits and saturating score storage");$finish;
end
initial begin #1000000;$fatal(1,"hang");end
endmodule
