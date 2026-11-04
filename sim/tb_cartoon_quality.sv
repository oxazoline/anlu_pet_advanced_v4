`timescale 1ns/1ps
// Direct image invariants, independent of generated reference-vector files.
module tb_cartoon_quality;
    reg clk=0,rst=0,valid=0,sof=0;
    reg [95:0] data=0;always #5 clk=~clk;
    wire [95:0] out;wire ov,os,ol;
    ext_cartoon_rgb96 #(.IMAGE_WIDTH(20),.IMAGE_HEIGHT(4)) dut(
        clk,rst,data,valid,sof,2'd2,out,ov,os,ol);
    integer level,kind,row,col,lane,k,count=0,expected_r,expected_g,expected_b;
    integer x,actual_r,actual_g,actual_b,dr,dg,db;
    integer last_gray=-1,current_gray=-1,frames=0;
    reg [23:0] pixel;
    always @(posedge clk)begin
        #1;
        if(rst && ov)begin
            for(lane=0;lane<4;lane=lane+1)begin
                x=(count%5)*4+lane;
                actual_r=out[95-lane*24 -:8];actual_g=out[87-lane*24 -:8];actual_b=out[79-lane*24 -:8];
                dr=actual_r-expected_r;dg=actual_g-expected_g;db=actual_b-expected_b;
                if(x<10)begin
                    if(dr!=0 || dg!=0 || db!=0)$fatal(1,"left bypass must be exact");
                end else begin
                    if(dr < -4 || dr > 4 || dg < -4 || dg > 4 || db < -4 || db > 4)
                        $fatal(1,"flat color was darkened/quantized outside bounded luma mapping");
                    if(kind==0)begin
                        if(dr!=dg || dg!=db)$fatal(1,"neutral gray acquired chroma");
                        if(expected_r>=8 && actual_r==0)$fatal(1,"visible dark gray collapsed to black");
                        if(last_gray>=0 && (actual_r-last_gray<0 || actual_r-last_gray>2))
                            $fatal(1,"hard jump/nonmonotonic gray curve");
                        current_gray=actual_r;
                    end else if(dr!=dg || dg!=db)$fatal(1,"unclipped color differences changed");
                end
            end
            count=count+1;
        end
    end
    task tick(input bit v,input bit s,input [95:0] d);
        begin @(negedge clk);valid=v;sof=s;data=d;end
    endtask
    initial begin
        repeat(3)@(negedge clk);rst=1;
        for(kind=0;kind<2;kind=kind+1)begin
            for(level=0;level<256;level=level+1)begin
                if(kind==0)begin expected_r=level;expected_g=level;expected_b=level;end
                else begin expected_r=16+(level*31)%224;expected_g=16+(level*59)%224;expected_b=16+(level*83)%224;end
                pixel={8'(expected_r),8'(expected_g),8'(expected_b)};count=0;current_gray=-1;
                tick(0,1,0);tick(0,0,0);
                for(row=0;row<4;row=row+1)
                    for(col=0;col<5;col=col+1)tick(1,0,{4{pixel}});
                repeat(12)tick(0,0,0);
                if(count!=20)$fatal(1,"geometry/flush");
                if(kind==0)last_gray=current_gray;
                frames=frames+1;
            end
        end
        if(frames!=512)$fatal(1,"coverage");
        $display("PASS IMAGE QUALITY: all 256 flat gray levels plus 256 unclipped colors, exact left bypass, no flat false contours, +/-4 luma bound, no dark collapse, monotonic <=2 adjacent gray steps, RGB difference preservation, 512 consecutive stale-RAM frames");$finish;
    end
    initial begin #3000000;$fatal(1,"timeout");end
endmodule
