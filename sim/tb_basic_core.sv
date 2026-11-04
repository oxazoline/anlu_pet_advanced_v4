`timescale 1ns/1ps
module tb_basic_core;
    reg clk=0; always #5 clk=~clk;
    reg rst=0, valid=0, sof=0, last=0;
    reg [95:0] data=0;
    wire [95:0] gray;
    wire gv,gs,gl,pv,ps;
    wire [127:0] packed_data;
    basic_gray_rgb96 g(clk,rst,data,valid,sof,last,gray,gv,gs,gl);
    basic_rgb_packer p(clk,rst,gs,gv,gray,ps,pv,packed_data);
    reg [7:0] expected[0:3000000];
    integer wr=0,rd=0,words=0,pixels=0;
    integer k,j,value,rr,gg,bb;
    reg [23:0] px;
    reg old_valid=0,old_sof=0,old_last=0;
    reg [95:0] old_gray=0,reference_gray;
    function [7:0] luminance;
        input [23:0] rgb;
        integer r,g,b;
        begin r=rgb[23:16]; g=rgb[15:8]; b=rgb[7:0];
            luminance=(77*r+150*g+29*b)/256;
        end
    endfunction
    always @(posedge clk) begin
        if (!rst) begin
            wr=0; rd=0; words=0; pixels=0;
            old_valid=0; old_sof=0; old_last=0; old_gray=0;
        end else begin
            reference_gray=0;
            for(k=0;k<4;k=k+1) begin
                px=data[95-k*24 -: 24]; value=luminance(px);
                reference_gray[95-k*24 -:24]={3{value[7:0]}};
                if(valid) begin
                    for(j=0;j<3;j=j+1) begin expected[wr]=value[7:0]; wr=wr+1; end
                    pixels=pixels+1;
                end
            end
            #1;
            if(gv!==old_valid || gs!==old_sof || gl!==old_last)
                $fatal(1,"gray marker latency mismatch");
            if(gv && gray!==old_gray) $fatal(1,"gray arithmetic/lane mismatch");
            if(pv) begin
                if(wr-rd<16) $fatal(1,"unexpected packed output");
                for(j=0;j<16;j=j+1) begin
                    if(packed_data[127-j*8 -:8]!==expected[rd])
                        $fatal(1,"packed byte mismatch at %0d",rd);
                    rd=rd+1;
                end
                words=words+1;
            end
            old_valid=valid; old_sof=sof; old_last=last; old_gray=reference_gray;
        end
    end
    task tick(input bit v,input bit s,input bit l,input [95:0] d);
        begin @(negedge clk); valid=v; sof=s; last=l; data=d; end
    endtask
    integer row,col,t;
    reg [95:0] next_data;
    initial begin
        repeat(4) @(negedge clk); rst=1;
        tick(0,1,0,0); repeat(16) tick(0,0,0,0);
        for(row=0;row<720;row=row+1) begin
            for(col=0;col<320;col=col+1) begin
                for(t=0;t<4;t=t+1) begin
                    rr=(col*4+t+row)%256; gg=(row*7+t)%256; bb=(col*13+t*43)%256;
                    if(row==0) begin rr=255; gg=255; bb=255; end
                    next_data[95-t*24 -:24]={rr[7:0],gg[7:0],bb[7:0]};
                end
                // Deliberate holes inside packed groups, not just line blanking.
                if((col+row)%7==0) tick(0,0,0,0);
                tick(1,0,col==319,next_data);
            end
            repeat(8) tick(0,0,0,0);
        end
        repeat(8) tick(0,0,0,0);
        if(wr!=2764800 || rd!=wr || words!=172800 || pixels!=921600)
            $fatal(1,"frame size mismatch bytes=%0d/%0d words=%0d pixels=%0d",rd,wr,words,pixels);
        $display("PASS CORE: 921600 pixels, 172800 DDR words, grayscale/markers/gaps match");
        // Reset with an incomplete packed group; no old partial data may leak.
        tick(1,0,0,96'h123456789abcdef012345678);
        @(negedge clk);rst=0;valid=0;
        repeat(3) @(negedge clk);rst=1;
        tick(1,1,0,{4{24'hffffff}});
        tick(0,0,0,0);
        tick(1,0,0,{4{24'hff0000}});
        tick(1,0,0,{4{24'h00ff00}});
        tick(1,0,1,{4{24'h0000ff}});
        repeat(8) tick(0,0,0,0);
        if(rd!=48 || wr!=48 || words!=3) $fatal(1,"reset/SOF recovery failed");
        $display("PASS RESET: incomplete group discarded; coincident SOF/data preserved");
        $finish;
    end
    initial begin #10000000; $fatal(1,"timeout"); end
endmodule
