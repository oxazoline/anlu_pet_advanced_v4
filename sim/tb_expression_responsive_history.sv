`timescale 1ns/1ps
module tb_expression_responsive_history;
reg clk=0,rst=0,sof=0;always #5 clk=~clk;reg[31:0] face=0;wire[31:0] status;reg[167:0] diag;reg[1:0] value;integer seq,i,model,ncount;reg[1:0] rh;reg[2:0] nh;reg isr;
ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.V22_POLICY(0),.ENABLE_CBROW(0)) dut(clk,rst,96'd0,1'b0,sof,face,status,,,,,,);
task obs(input[1:0] v);begin
 @(negedge clk);value=v;diag=0;diag[167]=1;diag[129]=1;diag[165:164]=v-1;
 force dut.core_diagnostic=diag;force dut.done=1;force dut.result=value;force dut.result_allowed=1;
 @(negedge clk);force dut.done=0;#1;
end endtask
initial begin
 force dut.capture=0;force dut.done=0;
 for(seq=0;seq<4096;seq=seq+1)begin
  rst=0;face=0;repeat(2)@(negedge clk);rst=1;face={2'b10,8'd30,7'd20,7'd32,8'd9};sof=1;@(negedge clk);sof=0;obs(2);
  model=2;rh=0;nh=0;
  for(i=0;i<12;i=i+1)begin
   isr=(seq>>i)&1;
   if(model==2)begin
    if(isr && (|rh))model=3;
    rh={rh[0],isr};nh=0;
   end else begin
    ncount=nh[0]+nh[1]+nh[2];
    if(!isr && ncount>=2)model=2;
    nh={nh[1:0],!isr};rh=0;
   end
   obs(isr?3:2);
   if(status[1:0]!==model[1:0])$fatal(1,"history seq%0d step%0d got%0d want%0d",seq,i,status[1:0],model);
  end
 end
 $display("PASS RESPONSIVE HISTORY:4096 independent12-result N/R histories versus sliding-window oracle; entry2of3, neutral release3of4, no single-spike acquisition");$finish;
end
initial begin #10000000;$fatal(1,"hang");end
endmodule
