`timescale 1ns/1ps
module tb_expression_visual;
 reg clk=0,rst=0,begin_patch=0,write=0,finish_patch=0,clean=0,rotate=0,low=0;
 always #5 clk=~clk;
 reg [5:0] x,y;reg [7:0] pixel;reg [31:0] raw=0;wire[31:0] face;wire matched;
 ext_expression_motion motion(clk,rst,begin_patch,write,finish_patch,clean,rotate,x,y,pixel,low,face,matched);
 ext_face_visual_hold #(.LIMIT_CYCLES(30000),.FRESH_CYCLES(6000)) hold(clk,rst,raw,matched,face);
 reg [7:0] image[0:73727];integer xx,yy,last,match_count=0,i;
 always @(posedge clk)if(matched)match_count=match_count+1;
 task patch(input integer kind,input integer mode,input bit learning);integer yy,xx,v;begin
 low=mode==32;clean=learning;last=mode-1;
 @(negedge clk);begin_patch=1;@(negedge clk);begin_patch=0;
 for(yy=0;yy<mode;yy=yy+1)for(xx=0;xx<mode;xx=xx+1)begin
 @(negedge clk);write=1;x=xx;y=yy;
 v=image[(rotate?(47-yy):yy)*48+(rotate?(47-xx):xx)];
 if(kind==1 && (rotate?yy>=mode/2:yy<mode/2))v=255;
 if(kind==2)v=100;
 if(kind==3)v=(xx*97+yy*43+xx*yy*19)%256;
 pixel=v;
 end
 @(negedge clk);write=0;finish_patch=1;@(negedge clk);finish_patch=0;repeat(2)@(negedge clk);
 end endtask
 task reset_all;begin @(negedge clk);rst=0;repeat(3)@(negedge clk);rst=1;raw={2'b10,8'd20,7'd10,7'd50,8'd9};repeat(2)@(negedge clk);end endtask
 initial begin
 $readmemh("au_pixels.hex",image);
 reset_all;patch(0,48,1);if(match_count!=0)$fatal(1,"Untrained template supported face");
 patch(0,48,1);if(match_count!=1)$fatal(1,"Real stable mouth texture not matched tex%0d",motion.texture);
 raw=0;patch(1,48,0);if(match_count!=2 || !face[31] || !face[30])$fatal(1,"Eye glare did not preserve independent mouth support");
 raw={2'b10,8'd32,7'd12,7'd18,8'd9};
 repeat(3)@(negedge clk);
 if(!face[30] || face[14:8]!=50)$fatal(1,"Reacquired upper lens box replaced independent mouth track");
 raw=0;
 patch(2,48,0);if(match_count!=2)$fatal(1,"Blank background refreshed visual life");
 patch(3,48,0);if(match_count!=2)$fatal(1,"Foreign texture refreshed visual life");
 repeat(6002)@(negedge clk);if(face[31])$fatal(1,"Stale appearance remained visible");
 reset_all;rotate=1;match_count=0;patch(0,48,1);patch(0,48,1);raw=0;patch(1,48,0);
 if(match_count!=2 || !face[30])$fatal(1,"Inverted camera glare support failed");
 // Unlimited exact image match_count still cannot exceed last real detector lifetime.
 for(i=0;i<15;i=i+1)patch(0,48,0);
 if(face[31])$fatal(1,"Appearance bypassed absolute real-detection lifetime");
 reset_all;rotate=0;patch(0,32,1);patch(0,32,1);raw=0;patch(1,32,0);
 if(!face[31] || !face[30])$fatal(1,"Native32 visual support failed");
 raw={2'b01,30'd0};repeat(2)@(negedge clk);if(face[31])$fatal(1,"Detector timeout not cleared");
 $display("PASS VISUAL SUPPORT: real face pixels, normal/inverted/native32 eye glare and upper-lens reacquisition veto, no first-entry acquisition, blank/foreign rejection, fresh/absolute deadline, timeout clearing");$finish;
 end
 initial begin #10000000;$fatal(1,"timeout");end
endmodule
