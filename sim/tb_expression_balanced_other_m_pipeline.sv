`timescale 1ns/1ps
module tb_expression_balanced_other_m_pipeline;
reg clk=0,dclk=0,rst=0,valid=0,sof=0,vs=0,de=0;always #5 clk=~clk;always #7 dclk=~dclk;
reg[95:0] gray=0;reg[31:0] raw=0;wire[31:0] face;wire[31:0] status;wire[167:0] diagnostic;wire pw,commit,visual;wire[9:0] pa;wire[7:0] pp,id;
ext_face_visual_hold hold(clk,rst,raw,visual,face);
ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.ENABLE_CBROW(0)) capture(clk,rst,gray,valid,sof,face,status,diagnostic,pw,pa,pp,commit,id,visual);
wire[199:0] received;ext_face_status_cdc #(.WIDTH(200)) cdc(clk,dclk,rst,{status,diagnostic},received);
wire ov,oh,od;wire[23:0] rgb;wire[9:0] a;
basic_osd #(.ENABLE_CONFUSED_UI(1)) osd(dclk,rst,vs,1'b0,de,24'h123456,4'd0,64'd0,64'd0,1'b1,32'd0,71'd0,8'd64,ov,oh,od,rgb,2'd3,face,received[199:168],received[167:0],8'd0,1'b0,8'd0,a);
reg[7:0] image[0:73727];integer xm[0:1279],ym[0:719],xx,yy,i,k,p,commits=0,match_count=0,j;
reg[103:0] text="EXPR CONFUSED";
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
 $readmemh("balanced_camera_pixels.hex",image);
 for(i=0;i<1280;i=i+1)xm[i]=-1;for(i=0;i<720;i=i+1)ym[i]=-1;
 for(i=0;i<48;i=i+1)begin p=((2*i+1)*32)/12;xm[160+p]=i;xm[159+p]=i;ym[96+p]=i;ym[95+p]=i;end
 repeat(3)@(negedge clk);rst=1;raw={2'b10,8'd20,7'd12,7'd32,8'd9};
 frame;frame;frame;frame;
 if(capture.core.mouth_score<128 || capture.core.mouth_score>=256)$fatal(1,"camera did not exercise weak OTHER mouth band");
 if(commits<4 || match_count==0 || !status[11] || status[1:0]!=0 || !diagnostic[135] || diagnostic[165:164]!=3 || diagnostic[163:160]!=2 || capture.label!=0)$fatal(1,"real OTHER combo failed independent C");
 raw=0;repeat(4)@(negedge clk);if(face[31:30]!=3)$fatal(1,"F1M bridge missing");
 for(j=0;j<16;j=j+1)begin
  frame;if(diagnostic[127:32]!==96'd0 || diagnostic[31:0]!==capture.core.chosen_margin)$fatal(1,"compact mode changed margin or leaked score payload");if(!status[11] || status[15:12]!=0 || !status[8] || diagnostic[165:164]!=3 || capture.label!=0 || face[31:30]!=3)$fatal(1,"OTHER/F1M C blank/stale j%0d",j);
 end
 display_frame;
 force osd.x=832;#1;if(osd.character!="M")$fatal(1,"visible F1M header missing");release osd.x;
 if(osd.expression_status[15:12]!=0 || !osd.expression_status[11])$fatal(1,"C effective status not coherent after CDC");
 for(i=0;i<13;i=i+1)begin
  force osd.x=16+i*16;force osd.y=688;force osd.de_d=1;de=1;#1;
  if(!osd.expression_area || osd.expression_char!==text[103-i*8-:8])$fatal(1,"CONFUSED glyph%0d missing/truncated",i);
 end
 force osd.x=223;#1;if(!osd.expression_area)$fatal(1,"CONFUSED last glyph hidden");force osd.x=224;#1;if(osd.expression_area)$fatal(1,"CONFUSED area too wide");
 raw=32'h40000000;repeat(5)@(negedge clk);if(status[11] || status[1:0]!=0)$fatal(1,"source high label not invalidated");
 release osd.x;release osd.y;release osd.de_d;de=0;display_frame;force osd.x=20;force osd.y=688;#1;if(osd.expression_area)$fatal(1,"stale CONFUSED after next display VS");
 $display("PASS BALANCED OTHER M PIPELINE:20 full real four-lane camera frames, exact2x2 capture, actual model OTHER/rejection2/base0 and weak mouth128..255 with independent C, real appearance bridge F1M sustained16 frames without RS2/C expiry, effective-valid200-bit CDC/frame snapshot/all13 glyphs, compact96-bit payload with retained margin and timeout clear; no forced classifier outputs");$finish;
end
initial begin #400000000;$fatal(1,"hang");end
endmodule
