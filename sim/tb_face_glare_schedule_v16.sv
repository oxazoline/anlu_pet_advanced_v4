`timescale 1ns/1ps
module tb_face_glare_schedule_v16;
reg clk=0,rst=0;always #5 clk=~clk;
wire[31:0] status;reg[7:0] bx=40,support=7;reg[6:0] by=10,bw=60;
ext_face_detector #(.ENABLE_ZOOM(0),.ENABLE_HIGHLIGHT(1)) dut(clk,rst,96'd0,1'b0,1'b0,status);
task result(input[7:0] px,input[6:0] py,input[6:0] pw,input[7:0] pv);begin
 @(negedge clk);bx=px;by=py;bw=pw;support=pv;force dut.done=1;
 @(negedge clk);force dut.done=0;repeat(4)@(negedge clk);
end endtask
integer i;
initial begin
 force dut.busy=0;force dut.start=0;force dut.large_scan=0;force dut.zoom=0;
 force dut.found=1;force dut.timeout=0;force dut.box_x=bx;force dut.box_y=by;force dut.box_size=bw;force dut.neighbors=support;force dut.done=0;
 repeat(3)@(negedge clk);rst=1;force dut.filter_capture=0;
 // Fresh supported entry must retain the raw-first schedule and hit count.
 result(40,10,60,7);result(40,10,60,7);
 if(status[31] || dut.prefer_filter)$fatal(1,"entry schedule changed");
 result(40,10,60,7);if(!status[31] || dut.prefer_filter)$fatal(1,"raw entry changed");
 // Classifier support alone used to suppress retry, even though the tracker
 // rejected this contained upper-face ROI. Check the actual registered result.
 result(55,12,30,7);
 if(!status[31] || status[6:0]!=0 || !dut.prefer_filter)$fatal(1,"strong geometry rejection did not schedule knee");
 force dut.filter_capture=1;result(55,12,30,7);
 if(dut.prefer_filter)$fatal(1,"failed knee geometry did not schedule raw");
 force dut.filter_capture=0;result(40,10,60,7);
 if(dut.prefer_filter || status[6:0]!=7)$fatal(1,"supported face unnecessarily toggled preprocessing");
 // A foreign full-field candidate is not evidence about this ROI's glare.
 result(110,10,30,7);
 if(dut.prefer_filter || !status[31] || status[6:0]!=0)$fatal(1,"foreign candidate changed photometric schedule");
 result(40,10,60,7);
 // Weak profile evidence may need the same knee/raw retry, without changing
 // search field, refreshing cadence or the support handed to the tracker.
 result(40,10,60,8'h83);
 if(!dut.prefer_filter || !status[31] || status[7:0]!=8'h83)$fatal(1,"weak profile did not retry or support fabricated");
 force dut.filter_capture=1;result(40,10,60,8'h83);
 if(dut.prefer_filter)$fatal(1,"weak profile retry did not alternate back");
 force dut.filter_capture=0;result(40,10,60,8'h87);
 if(dut.prefer_filter || !status[31])$fatal(1,"strong supported profile toggled");
 for(i=0;i<4;i=i+1)result(110,10,30,7);
 if(status[31] || dut.prefer_filter)$fatal(1,"foreign results refreshed hold or changed retry");
 $display("PASS V16 GLARE SCHEDULE: raw first entry, registered strong contained-reject knee/raw retry, weak-profile retry, supported-face stability, foreign isolation and bounded expiry");$finish;
end
initial begin #100000;$fatal(1,"timeout");end
endmodule
