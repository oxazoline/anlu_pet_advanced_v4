`timescale 1ns/1ps
module tb_advanced_latency;
reg refclk=0,cclk=0,dclk=0,pclk=0,rst=0,cap=0,proc=0,slot=0,wr=0,sel=0,vs=0,de=0;
reg[1:0] ws=0,rs=0,mode=0;wire[63:0] metrics;
always #5 refclk=~refclk;always #7 cclk=~cclk;always #3 dclk=~dclk;always #11 pclk=~pclk;
adv_frame_latency #(.TICKS_PER_MS(10),.WORDS_PER_FRAME(4))dut(refclk,cclk,dclk,pclk,rst,cap,proc,mode,slot,ws,wr,sel,rs,vs,de,metrics,);
task capture(input integer target,input integer md);begin
 @(negedge cclk);cap=1;@(negedge cclk);cap=0;repeat(5)@(negedge cclk);mode=md;
 proc=1;@(negedge cclk);proc=0;repeat(10)@(negedge dclk);ws=target;slot=1;@(negedge dclk);slot=0;
end endtask
task words(input integer n);integer i;begin for(i=0;i<n;i=i+1)begin @(negedge dclk);wr=1;end @(negedge dclk);wr=0;end endtask
task display(input integer target);begin
 @(negedge dclk);rs=target;sel=1;@(negedge dclk);sel=0;repeat(10)@(negedge pclk);
 vs=1;@(negedge pclk);vs=0;repeat(5)@(negedge pclk);de=1;@(negedge pclk);de=0;repeat(2)@(negedge pclk);
end endtask
integer lastmax;
initial begin
 repeat(4)@(negedge refclk);rst=1;repeat(10)@(negedge cclk);
 capture(0,2);words(4);capture(1,1);words(2);
 display(0);if(!metrics[63] || metrics[27:12]!=1 || metrics[61:60]!=2)$fatal(1,"latest-frame substituted for selected slot: %h",metrics);
 if(metrics[59:44]==0)$fatal(1,"latency not measured");
 lastmax=dut.max_delay;display(0);if(!metrics[62] || dut.max_delay!=lastmax)$fatal(1,"repeat counted as new-frame latency");
 display(1);if(metrics[63])$fatal(1,"incomplete frame published");
 words(2);display(1);if(!metrics[63] || metrics[27:12]!=2 || metrics[61:60]!=1)$fatal(1,"completed slot tag not retained");
 if(dut.drops!=0)$fatal(1,"normal repeat counted as drop");
 rst=0;repeat(3)@(negedge pclk);if(metrics!=0)$fatal(1,"reset tag not cleared");
 $display("PASS ADVANCED LATENCY: four async clocks, capture timestamp/id/mode bound to chosen DDR slot, incomplete publication blocked, repeats separated, reset");$finish;
end
initial begin #100000;$fatal(1,"latency timeout");end
endmodule
