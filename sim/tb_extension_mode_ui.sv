`timescale 1ns/1ps
module tb_extension_mode_ui;
localparam NO_C=0;reg clk=0,rst=0,vs=0,de=0;always #5 clk=~clk;reg[31:0] face={2'b10,8'd20,7'd12,7'd32,8'd9};reg[31:0] status=0;reg[167:0] diag=0;wire ov,oh,od;wire[23:0] rgb;wire[9:0] addr;
basic_osd dut(clk,rst,vs,1'b0,de,24'h123456,4'd0,64'd0,64'd0,1'b1,32'd0,71'd0,8'd64,ov,oh,od,rgb,2'd3,face,status,diag,8'd0,1'b0,8'd0,addr);
initial begin
 status[11]=1;status[8]=1;status[6]=1;status[5]=1;diag[155]=1;repeat(3)@(negedge clk);rst=1;vs=1;@(negedge clk);vs=0;repeat(4)@(negedge clk);
 force dut.x=20;force dut.y=688;force dut.de_d=1;de=1;#1;if(NO_C && (dut.confused_label || dut.expression_area))$fatal(1,"no-C UI can display C");if(!NO_C && !dut.confused_label)$fatal(1,"C UI disabled unexpectedly");
 force dut.x=944+16*16;force dut.y=80+8*16;#1;if(!NO_C && dut.expression_debug_char!="Q")$fatal(1,"profile Q indicator missing");
 $display("PASS MODE UI:actual default C display enable/exclusion and guarded Q diagnostic");$finish;
end
initial begin #100000;$fatal(1,"hang");end
endmodule
