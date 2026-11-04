`timescale 1ns/1ps
module tb_extension_mode_pipeline;
reg clk=0,dclk=0,rst=0,valid=0,sof=0,vs=0,de=0;always #5 clk=~clk;always #7 dclk=~dclk;
reg[95:0] gray=0;reg[31:0] raw=0;wire[31:0] face;wire[31:0] status;wire[167:0] diagnostic;wire pw,commit,visual;wire[9:0] pa;wire[7:0] pp,id;
ext_face_visual_hold hold(clk,rst,raw,visual,face);
ext_expression_capture capture(clk,rst,gray,valid,sof,face,status,diagnostic,pw,pa,pp,commit,id,visual);
wire[199:0] received;ext_face_status_cdc #(.WIDTH(200)) cdc(clk,dclk,rst,{status,diagnostic},received);
wire ov,oh,od;wire[23:0] rgb;wire[9:0] a;
basic_osd osd(dclk,rst,vs,1'b0,de,24'h123456,4'd0,64'd0,64'd0,1'b1,32'd0,71'd0,8'd64,ov,oh,od,rgb,2'd3,face,received[199:168],received[167:0],8'd0,1'b0,8'd0,a);
reg[7:0] image[0:73727];integer xm[0:1279],ym[0:719],xx,yy,i,k,p,commits=0,match_count=0,j;
reg[95:0] text="EXPR NERVOUS";
always @(posedge clk)begin if(commit)commits=commits+1;if(visual)match_count=match_count+1;end
function[7:0] value(input integer x,y);begin
 if(xm[x]>=0 && ym[y]>=0)value=image[ym[y]*48+xm[x]];else value=32;
end endfunction
task frame;begin
 @(negedge clk);sof=1;valid=0;@(negedge clk);sof=0;
 for(yy=0;yy<720;yy=yy+1)for(xx=0;xx<320;xx=xx+1)begin
  @(negedge clk);valid=1;for(k=0;k<4;k=k+1)gray[95-k*24-:24]={3{value(xx*4+k,yy)}};
 end
 @(negedge clk);valid=0;wait(!capture.busy && !capture.start);repeat(6)@(negedge clk);
end endtask
task display_frame;begin
 repeat(30)@(negedge dclk);vs=1;@(negedge dclk);vs=0;repeat(4)@(negedge dclk);
end endtask
initial begin
 $readmemh("mode_camera.hex",image);
 for(i=0;i<1280;i=i+1)xm[i]=-1;for(i=0;i<720;i=i+1)ym[i]=-1;
 for(i=0;i<48;i=i+1)begin p=((2*i+1)*32)/12;xm[160+p]=i;xm[159+p]=i;ym[96+p]=i;ym[95+p]=i;end
 repeat(3)@(negedge clk);rst=1;raw={2'b10,8'd20,7'd12,7'd32,8'd9};frame;frame;frame;frame;
 if(!status[11] || diagnostic[155] || !diagnostic[135] || diagnostic[165:164]!=3)$fatal(1,"weak frontal open OTHER not confirmed");
 raw[7]=1;
 for(j=0;j<16;j=j+1)begin frame;if(status[11] || !status[8] || diagnostic[155])$fatal(1,"weak profile C stole base display");end
 display_frame;if(osd.confused_label)$fatal(1,"profile C survived CDC/UI");
 raw=32'h40000000;repeat(5)@(negedge clk);if(status[11] || status[1:0]!=0)$fatal(1,"owner clear failed");
 $display("PASS MODE CAMERA PIPELINE:20 full1280x720 actual four-lane streams, weak open OTHER C frontal acquisition,16 flagged profile frames reject insufficient C evidence,200-bit CDC/frame snapshot excludes stale C, owner clear");$finish;
end
initial begin #400000000;$fatal(1,"hang");end
endmodule
