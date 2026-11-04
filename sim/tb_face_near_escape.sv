`timescale 1ns/1ps
module tb_face_near_escape;
reg clk=0,rst=0,sof=0;always #5 clk=~clk;wire[31:0] status;
ext_face_detector dut(clk,rst,96'd0,1'b0,sof,status);
task fs;begin @(negedge clk);sof=1;@(negedge clk);sof=0;end endtask
task result(input[7:0] v,input bit f);begin
 force dut.neighbors=v;force dut.found=f;force dut.done=1;@(negedge clk);force dut.done=0;@(negedge clk);
end endtask
initial begin
 repeat(3)@(negedge clk);rst=1;force dut.busy=0;force dut.start=0;force dut.phase=0;force dut.timeout=0;
 force dut.O_status={1'b1,1'b0,8'd30,7'd1,7'd88,8'd7};
 force dut.refresh=1;force dut.last_large=1;fs;release dut.last_large;
 if(!dut.large_scan)$fatal(1,"near baseline lost");
 result(2,1);if(dut.last_large)$fatal(1,"weak near result locked frontal-only mode");
 fs;if(dut.large_scan || dut.zoom || dut.scan_hint[30])$fatal(1,"no ordinary/profile field after weak near result");
 force dut.O_status=0;force dut.box_x=30;force dut.box_y=10;force dut.box_size=40;
 result(131,1);
 if(!dut.pending_hint[31] || !dut.pending_hint[7] || dut.pending_hint[6:0]!=3)$fatal(1,"weak profile cannot seed repeated localized confirmation");
 result(3,1);if(dut.pending_hint[31])$fatal(1,"weak frontal acquired search hint");
 $display("PASS NEAR ESCAPE: strong near retained, weak near releases frontal-only scan, profile3 may seed five-hit confirmation, frontal3 cannot seed hint");$finish;
end
initial begin #100000;$fatal(1,"timeout");end
endmodule
