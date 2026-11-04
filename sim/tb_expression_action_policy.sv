`timescale 1ns/1ps
module tb_expression_action_policy;
 reg clk=0,rst=0;always #5 clk=~clk;
 wire busy,done;wire[1:0] label;wire[167:0] diag;
 ext_expression_core dut(clk,rst,1'b0,1'b0,12'd0,8'd0,8'd128,busy,done,label,diag,1'b0);
 `include "action_policy_count.vh"
 reg[15:0] scores[0:CASES*6-1];reg[7:0] contrast[0:CASES-1];
 reg ori[0:CASES-1];reg[1:0] raw[0:CASES-1],labels[0:CASES-1];reg[31:0] expected[0:CASES-1];
 integer f,i;
 initial begin
 $readmemh("action_policy_scores.hex",scores);$readmemh("action_policy_contrast.hex",contrast);
 $readmemh("action_policy_ori.hex",ori);$readmemh("action_policy_raw.hex",raw);
 $readmemh("action_policy_labels.hex",labels);$readmemh("action_policy_debug.hex",expected);
 repeat(3)@(negedge clk);rst=1;
 for(f=0;f<CASES;f=f+1)begin
 @(negedge clk);
 for(i=0;i<6;i=i+1)dut.au_scores[i]=scores[f*6+i];
 dut.state=15;dut.O_busy=1;dut.contrast=contrast[f];dut.orientation_confident=ori[f];dut.au_orientation=0;
 dut.winner[0]=raw[f];dut.selected=0;dut.margin0=20000;dut.happy_gap0=20000;
 @(negedge clk);
 if(!done || label!==labels[f])$fatal(1,"Action policy f%0d got%0d expected%0d",f,label,labels[f]);
 if(diag[159:128]!==expected[f])$fatal(1,"Action diagnostics f%0d got%h want%h",f,diag[159:128],expected[f]);
 end
 $display("PASS ACTION POLICY: %0d boundary/gate cases including3072 reconstructed photo diagnostic intervals accepted as NERVOUS; independent brow/down/press paths, smile veto, original path preservation and coherent readable flags. Diagnostic replay only, not camera pixels.",CASES);$finish;
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
