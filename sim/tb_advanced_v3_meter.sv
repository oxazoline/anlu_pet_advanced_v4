`timescale 1ns/1ps
module tb_advanced_v3_meter;
reg clk=0,ctrl=0,rst=0,valid=0,sof=0;reg[95:0]rgb=0;reg[15:0]id=1;wire[31:0]refbox,hand,motion,info,debug,meter,syncmeter;
always #5 clk=~clk;always #7 ctrl=~ctrl;
adv_vision dut(clk,rst,rgb,valid,sof,32'd0,refbox,hand,motion,info,id,debug,meter);
ext_face_status_cdc #(.WIDTH(32)) cdc(clk,ctrl,rst,meter,syncmeter);
integer y,x;reg[7:0]v;
task frame(input integer left,input integer right);begin
 @(negedge clk);sof=1;@(negedge clk);sof=0;
 for(y=0;y<720;y=y+1)begin for(x=0;x<320;x=x+1)begin @(negedge clk);valid=1;v=x<160 ? left:right;rgb={12{v}};end
 @(negedge clk);valid=0;repeat(2)@(negedge clk);end
 wait(dut.state==0 && !dut.capture);repeat(60)@(negedge clk);end endtask
initial begin repeat(4)@(negedge clk);rst=1;
 frame(90,210);if(syncmeter[31:24]!=1 || syncmeter[23:16]!=90 || syncmeter[15:8]!=210 || !syncmeter[7] || syncmeter[4:3]!=0)$fatal(1,"zone means/frame id/CDC incorrect %h",syncmeter);
 id=2;frame(255,30);if(syncmeter[31:24]!=2 || syncmeter[23:16]!=255 || syncmeter[15:8]!=30 || syncmeter[4:3]!=3)$fatal(1,"clipping or frame reset incorrect %h",syncmeter);
 id=3;frame(120,120);if(syncmeter[23:16]!=120 || syncmeter[15:8]!=120 || syncmeter[4:3]!=0)$fatal(1,"previous bright-frame statistics leaked");
 $display("PASS ADVANCED V3 METER: three full RGB96 frames, exact two4096-cell linear-luma means, saturation fraction, consecutive-frame reset, source ID and asynchronous bundled transfer");$finish;end
initial begin #300000000;$fatal(1,"meter timeout");end
endmodule
