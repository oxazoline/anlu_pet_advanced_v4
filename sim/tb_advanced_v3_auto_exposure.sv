`timescale 1ns/1ps
module tb_advanced_v3_auto_exposure;
reg clk=0,rst=1,configured=1;reg[3:0]btn=15;reg[31:0]meter=0;wire req;wire[15:0]exp,gain;wire[31:0]status;
always #5 clk=~clk;
adv_auto_exposure #(.CLK_HZ(1000),.DEBOUNCE_CYCLES(2),.REPEAT_CYCLES(100)) dut(clk,rst,btn,configured,1'b1,req,exp,gain,meter,status);
integer busy=0,writes=0,active=1996,pending=1996,seq=0,n,value,scene=500,before_exp,before_writes;
always @(posedge clk)begin
 if(rst)begin configured<=1;busy<=0;writes<=0;active<=1996;pending<=1996;end
 else begin
  if(!configured && exp!=pending)$fatal(1,"exposure changed during grouped transaction");
  if(req)begin if(busy!=0)$fatal(1,"overlapping I2C requests");pending<=exp;configured<=0;busy<=8;writes<=writes+1;end
  else if(busy!=0)begin busy<=busy-1;if(busy==1)begin configured<=1;active<=pending;end end
  if(exp<4 || exp>3991 || gain!=144)$fatal(1,"sensor safety/gain limit");
 end
end
task sample(input integer left,input integer right,input integer hand,input integer right_hand,input integer clipping);begin
 @(negedge clk);seq=seq+1;meter={seq[7:0],left[7:0],right[7:0],1'b1,hand[0],right_hand[0],clipping[0],clipping[0],3'd0};repeat(50)@(negedge clk);end endtask
task plant;begin value=(active*scene)>>12;if(value>255)value=255;sample(value,value,0,0,value>=250);end endtask
task keys(input[3:0]b);begin btn=b;repeat(10)@(negedge clk);btn=15;repeat(12)@(negedge clk);end endtask
initial begin
 repeat(4)@(negedge clk);rst=0;
 for(n=0;n<80;n=n+1)plant;
 value=(active*scene)>>12;if(value<128 || value>176)$fatal(1,"bright scene failed to converge %0d E%0d",value,active);
 before_writes=writes;for(n=0;n<20;n=n+1)plant;if(writes!=before_writes)$fatal(1,"steady scene oscillates");
 scene=180;for(n=0;n<100;n=n+1)plant;value=(active*scene)>>12;if(value<128 || value>176)$fatal(1,"dark scene failed to converge %0d",value);
 before_exp=exp;for(n=0;n<12;n=n+1)sample(110,220,1,0,0);if(status[19:12]!=110 || exp<=before_exp)$fatal(1,"hand-zone meter not preferred");
 keys(4'b1100);if(status[31])$fatal(1,"manual toggle failed");repeat(30)@(negedge clk);before_exp=exp;
 for(n=0;n<12;n=n+1)sample(255,255,0,0,1);if(exp!=before_exp)$fatal(1,"AUTO overrode MANUAL");
 keys(4'b1110);repeat(30)@(negedge clk);if(exp>=before_exp)$fatal(1,"manual dim key ignored");
 keys(4'b1100);if(!status[31])$fatal(1,"AUTO resume failed");
 for(n=0;n<450;n=n+1)sample(255,255,0,0,1);if(exp!=4)$fatal(1,"minimum exposure not clamped %0d",exp);
 for(n=0;n<500;n=n+1)sample(0,0,0,0,0);if(exp!=3991)$fatal(1,"maximum exposure not clamped %0d",exp);
 repeat(30)@(negedge clk);before_exp=exp;repeat(2100)@(negedge clk);if(exp!=before_exp || status[30])$fatal(1,"stale meter kept driving exposure");
 $display("PASS ADVANCED V3 AUTO EXPOSURE: delayed sensor plant bright/dark convergence, stable deadband, zone preference, fresh-only votes, settle frames, grouped-write stability, manual override/resume, safe bounds, stale-meter stop and sequence wrap");$finish;
end
initial begin #10000000;$fatal(1,"AE timeout");end
endmodule
