`timescale 1ns/1ps
module tb_advanced_frame_boxes;
reg clk=0,rst=0,vs=0,de=0;always #5 clk=~clk;
reg[31:0]refbox=0,info=0;reg[63:0]metrics=0;wire ov,oh,od;wire[23:0]rgb;
adv_overlay dut(clk,rst,vs,1'b0,de,24'h123456,refbox,32'd0,32'd0,info,metrics,ov,oh,od,rgb,32'd0,32'd0);
integer x;
task line0;begin @(negedge clk);vs=1;@(negedge clk);vs=0;repeat(3)@(negedge clk);
 for(x=0;x<1280;x=x+1)begin @(negedge clk);de=1;end
 @(negedge clk);de=0;repeat(4)@(negedge clk);end endtask
initial begin repeat(3)@(negedge clk);rst=1;
 refbox={2'b10,8'd20,7'd20,8'd30,7'd30};info=32'h00070000;repeat(5)@(negedge clk);
 refbox={2'b10,8'd60,7'd20,8'd30,7'd30};info=32'h00080000;repeat(5)@(negedge clk);
 metrics={1'b1,1'b0,2'd0,16'd50,16'd50,16'd7,6'd0,6'd0};line0;
 if(!dut.ref_box[31] || dut.ref_box[29:22]!=20)$fatal(1,"latest source box substituted for displayed older frame");
 metrics[27:12]=8;line0;if(!dut.ref_box[31] || dut.ref_box[29:22]!=60)$fatal(1,"selected source-frame box unavailable");
 metrics[27:12]=9;line0;if(!dut.ref_box[31] || dut.draw_match!=2)$fatal(1,"bounded coast absent");
 metrics[27:12]=13;line0;if(dut.ref_box[31])$fatal(1,"out of date result used");
 metrics[27:12]=7;metrics[59:44]=501;line0;if(dut.ref_box[31])$fatal(1,"stopped camera resurrected old box");
 $display("PASS ADVANCED FRAME BOXES: source7/source8 cache follows selected video id, missing frame hidden, old repeated frame expires");$finish;end
endmodule
