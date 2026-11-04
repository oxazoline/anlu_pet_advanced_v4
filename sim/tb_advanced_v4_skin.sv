`timescale 1ns/1ps
module tb_advanced_v4_skin;
reg clk=0,rst=0,v=0,sof=0;reg [95:0] rgb=0;always #5 clk=~clk;
adv_vision #(.V4_MODE(1)) dut(.I_clk(clk),.I_rst_n(rst),.I_rgb(rgb),.I_valid(v),.I_sof(sof),.I_face(32'd0),.I_frame_id(16'd0));
task color(input[23:0]c,input expected);begin
 @(negedge clk);rgb={4{c}};v=1;repeat(5)@(negedge clk);
 if(dut.is_skin!==expected)$fatal(1,"colour %h skin=%b expected=%b",c,dut.is_skin,expected);
end endtask
initial begin repeat(4)@(negedge clk);rst=1;sof=1;@(negedge clk);sof=0;
color(24'h2d1e15,1);color(24'h6e4832,1);color(24'hd2c8b9,0);color(24'hfaf0e6,0);color(24'hfae1d2,1);color(24'hc8c8c8,0);color(24'h101010,0);color(24'h284878,0);
$display("PASS ADVANCED V4 SKIN: dim chromatic skin accepted; warm paper, neutral paper, black and blue excluded through actual RGB pipeline");$finish;end
endmodule
