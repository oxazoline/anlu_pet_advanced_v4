`timescale 1ns/1ps
module tb_expression_visual_pipeline;
 reg clk=0,rst=0,valid=0,sof=0;always #5 clk=~clk;
 reg [95:0] data=0;reg [31:0] raw=0;wire[31:0] face,status;wire[167:0] diagnostic;
 wire visual,pw,commit;wire[9:0] address;wire[7:0] pixel,id;
 ext_face_visual_hold hold(clk,rst,raw,visual,face);
 // Production default: V18 action head is enabled, sharing the base multiplier.
 ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.ENABLE_CBROW(0)) capture(clk,rst,data,valid,sof,face,status,diagnostic,pw,address,pixel,commit,id,visual);
 reg [7:0] image[0:73727];integer xx,yy,k,match_count=0,commits=0,before_match,before_commit;
 reg glare=0,rotation=0;
 always @(posedge clk)begin if(visual)match_count=match_count+1;if(commit)commits=commits+1;end
 function[7:0] gray(input integer x,y);integer fx,fy;begin
 if(x<160 || x>=416 || y<96 || y>=352)gray=32;
 else begin
 fx=(x-160)*48/256;fy=(y-96)*48/256;
 gray=glare && (rotation?fy>=24:fy<24)?255:image[fy*48+fx];
 end
 end endfunction
 task frame;begin
 @(negedge clk);sof=1;valid=0;@(negedge clk);sof=0;
 for(yy=0;yy<720;yy=yy+1)for(xx=0;xx<320;xx=xx+1)begin
 @(negedge clk);valid=1;for(k=0;k<4;k=k+1)data[95-k*24-:24]={3{gray(xx*4+k,yy)}};
 end
 @(negedge clk);valid=0;wait(!capture.busy && !capture.start);repeat(6)@(negedge clk);
 end endtask
 initial begin
 $readmemh("au_pixels.hex",image);repeat(3)@(negedge clk);rst=1;raw={2'b10,8'd20,7'd12,7'd32,8'd9};repeat(3)@(negedge clk);
 frame;frame;frame;
 if(match_count==0 || commits<3)$fatal(1,"Real capture pipeline did not produce independent appearance proof/commits");
 if(status[1:0]!=3 || diagnostic[165:164]!=2)$fatal(1,"Real camera pixels failed to display enabled NERVOUS");
 before_match=match_count;before_commit=commits;rotation=diagnostic[128];raw=0;glare=1;repeat(3)@(negedge clk);
 if(!face[31] || !face[30])$fatal(1,"Appearance bridge missing");
 frame;
 if(match_count<=before_match || commits!=before_commit+1 || !status[6] || !status[5])$fatal(1,"M capture/classify path blocked or mouth pixels misaligned");
 repeat(11)begin @(negedge clk);sof=1;@(negedge clk);sof=0;end
 if(!status[6])$fatal(1,"Fresh independent appearance incorrectly used expired prediction budget");
 raw={2'b01,30'd0};repeat(4)@(negedge clk);
 if(face[31] || status[6] || status[1:0]!=0)$fatal(1,"Timeout left appearance/label active");
 $display("PASS VISUAL PIPELINE: four full real-pixel camera frames, production base plus enabled action model, actual2x2 capture/NERVOUS display/descriptor, eye-glare M refresh, inference/preview commits, independent M eligibility beyond prediction budget and timeout clearing");$finish;
 end
 initial begin #100000000;$fatal(1,"timeout");end
endmodule
