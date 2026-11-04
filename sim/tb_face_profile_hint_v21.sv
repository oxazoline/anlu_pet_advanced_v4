`timescale 1ns/1ps
module tb_face_profile_hint_v21;
reg clk=0,rst=0;always #5 clk=~clk;reg[7:0] pv=131;reg ff=1,tt=0;
wire[31:0] status;
ext_face_detector #(.ENABLE_LARGE(0),.ENABLE_ZOOM(0)) dut(clk,rst,96'd0,1'b0,1'b0,status);
task event_result;begin @(negedge clk);force dut.done=1;@(negedge clk);force dut.done=0;repeat(3)@(negedge clk);end endtask
task reset;begin rst=0;repeat(3)@(negedge clk);rst=1;repeat(2)@(negedge clk);end endtask
initial begin
 force dut.done=0;force dut.found=ff;force dut.timeout=tt;force dut.neighbors=pv;
 force dut.mapped_x=8'd30;force dut.mapped_y=7'd20;force dut.mapped_size=7'd40;
 reset;event_result;if(!dut.pending_hint[31] || status[31])$fatal(1,"search hint visible too early");
 ff=0;pv=0;event_result;if(!dut.pending_hint[31] || !dut.pending_hint_gap || status[31])$fatal(1,"first profile gap discarded ROI");
 event_result;if(dut.pending_hint[31] || status[31])$fatal(1,"second profile gap retained ROI");
 reset;ff=1;pv=131;event_result;ff=0;pv=0;event_result;ff=1;pv=131;event_result;
 ff=0;pv=0;event_result;if(dut.pending_hint[31])$fatal(1,"second separated miss retained ROI");
 reset;ff=1;pv=131;event_result;ff=0;tt=1;event_result;
 if(dut.pending_hint[31] || !status[30])$fatal(1,"timeout retained hint");tt=0;
 reset;ff=1;pv=8;event_result;ff=0;pv=0;event_result;if(dut.pending_hint[31])$fatal(1,"frontal hint got profile grace");
 $display("PASS PROFILE HINT V21: invisible weak profile search memory tolerates one miss only; second separated miss, timeout and frontal miss clear immediately");$finish;
end
initial begin #100000;$fatal(1,"hang");end
endmodule
