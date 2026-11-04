`timescale 1ns/1ps
module tb_expression_compact_debug;
reg clk=0,rst=0,vs=0,de=0;always #5 clk=~clk;
reg[31:0] face={2'b11,8'd20,7'd12,7'd32,8'd0};reg[31:0] status=0;reg[167:0] diag=0;
wire ov,oh,od;wire[23:0] rgb;wire[9:0] pa;
basic_osd #(.ENABLE_CONFUSED_UI(1)) dut(clk,rst,vs,1'b0,de,24'h123456,4'd0,64'd0,64'd0,1'b1,32'd0,71'd0,8'd64,ov,oh,od,rgb,2'd3,face,status,diag,8'd64,1'b1,8'h2a,pa);
integer r,c;reg[31:0] text="LITE";
task fs;begin @(negedge clk);de=0;vs=1;@(negedge clk);vs=0;end endtask
task at_char(input integer row_id,col_id,input[7:0] expected);begin
 force dut.x=944+col_id*16;force dut.y=80+row_id*16;force dut.de_d=1;de=1;#1;
 if(dut.expression_debug_char!==expected)$fatal(1,"compact row%0d col%0d got%c want%c",row_id,col_id,dut.expression_debug_char,expected);
end endtask
initial begin
 status[31:24]=8'h2a;status[23:16]=8'hc4;status[11]=1;status[10:9]=2;status[8]=1;status[6]=1;status[5]=1;
 diag[167]=1;diag[165:164]=2;diag[152]=1;diag[135]=1;diag[132]=1;diag[130]=1;diag[129]=1;
 diag[127:96]=32'haaaabbbb;diag[95:64]=32'h76543210;diag[63:32]=32'hdeadbeef;diag[31:0]=32'h12345678;
 repeat(3)@(negedge clk);rst=1;fs;
 for(r=1;r<=3;r=r+1)begin
  case(r)1:at_char(r,0,"H");2:at_char(r,0,"N");3:at_char(r,0,"R");endcase
  at_char(r,1,":");for(c=2;c<6;c=c+1)at_char(r,c,text[31-(c-2)*8-:8]);for(c=6;c<10;c=c+1)at_char(r,c," ");
 end
 at_char(4,2,"0");at_char(4,3,"1");at_char(5,2,"1");at_char(5,9,"8");at_char(6,9,"0");
 at_char(8,10,"R");at_char(8,14,"J");at_char(8,15,"1");at_char(11,4,"C");at_char(13,5,"1");at_char(13,14,"1");
 diag=0;status=0;at_char(8,15,"1");at_char(11,4,"C");
 release dut.x;release dut.y;release dut.de_d;de=0;fs;at_char(8,15,"0");at_char(11,4,"-");
 $display("PASS COMPACT DEBUG:explicit H/N/R LITE rows ignore incoming numeric scores, full32-bit margin/action/strength/status flags retained, C label and frame-atomic metadata unchanged; full-score legacy formatting tested separately");$finish;
end
initial begin #100000;$fatal(1,"hang");end
endmodule
