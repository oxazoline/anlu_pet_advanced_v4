`timescale 1ns/1ps
module tb_tone_detail;
    reg clk=0,rst=0,valid=0,sof=0,last=0;
    reg [95:0] data=0;
    always #5 clk=~clk;
    wire [95:0] out_data,unused_data;
    wire ov,os,ol,uv,us,ul;
    basic_tone_map t(clk,rst,data,valid,sof,last,out_data,ov,os,ol);
    basic_detail_sharpen d(clk,rst,data,valid,sof,unused_data,uv,us,ul);
    reg [7:0] expected[0:255];
    integer x,l,c,r,low,mag,correction,value,actual,checked=0;
    initial begin
        $readmemh("tone_expected.hex",expected);
        repeat(3) @(negedge clk);rst=1;
        for(x=0;x<256;x=x+1)begin
            @(negedge clk);data={12{8'(x)}};valid=x%7!=0;sof=x==0;last=x%4==3;
            @(posedge clk);#1;
            if(ov!==valid || os!==sof || ol!==last || out_data!=={12{expected[x]}})
                $fatal(1,"tone LUT/control mismatch at %0d",x);
            if(x>0 && expected[x]<expected[x-1])$fatal(1,"tone is not monotonic");
            if(expected[x]<x)$fatal(1,"tone unexpectedly darkens input");
        end
        if(expected[0]!=0 || expected[255]!=255)$fatal(1,"black/white endpoint");
        // Every left/right pair for representative centers including saturation.
        for(c=0;c<256;c=c+1)if(c<8 || c%16==0 || c>247)
            for(l=0;l<256;l=l+1)for(r=0;r<256;r=r+1)begin
                low=(l+2*c+r+2)/4;mag=c>low?c-low:low-c;
                correction=mag>6?(mag-6)/2:0;
                if(correction>6)correction=6;
                value=c+(c>=low?correction:-correction);
                if(value<0)value=0;if(value>255)value=255;
                actual=d.smooth(8'(l),8'(c),8'(r));
                if(actual!=value)$fatal(1,"detail mismatch %0d/%0d/%0d",l,c,r);
                if(mag<=6 && actual!=c)$fatal(1,"noise gate changed small residual");
                if(actual-c>6 || c-actual>6)$fatal(1,"correction cap exceeded");
                checked=checked+1;
            end
        $display("PASS TONE/DETAIL: all 256 tone levels and controls, monotonic endpoints; %0d detail triplets, gate/cap/saturation",checked);
        $finish;
    end
    initial begin #100000;$fatal(1,"timeout");end
endmodule
