`timescale 1ns/1ps
module tb_spatial_chain;
    reg clk=0,rst=0,valid=0,sof=0;reg [95:0] data=0;
    always #5 clk=~clk;
    wire [95:0] gray,horizontal,filtered;wire gv,gs,gl,hv,hs,hl,fv,fs,fl,pv,ps;
    wire [127:0] packed_data;
    basic_gray_rgb96 g(clk,rst,data,valid,sof,1'b0,gray,gv,gs,gl);
    basic_spatial_denoise d(clk,rst,gray,gv,gs,horizontal,hv,hs,hl);
    basic_vertical_denoise v(clk,rst,horizontal,hv,hs,filtered,fv,fs,fl);
    wire [95:0] detail,toned;wire dv,ds,dl,tv,ts,tl;
    basic_detail_sharpen d5(clk,rst,filtered,fv,fs,detail,dv,ds,dl);
    basic_tone_map t5(clk,rst,detail,dv,ds,dl,toned,tv,ts,tl);
    basic_rgb_packer p(clk,rst,ts,tv,toned,ps,pv,packed_data);
    reg [95:0] source[0:230399];reg [127:0] expected[0:172799];
    integer words=0,beats=0,lines=0,index=0,frame,row,col;
    always @(posedge clk)begin
        #1;
        if(!rst)begin words=0;beats=0;lines=0;end
        else begin
            if(tv)begin beats=beats+1;if(tl)lines=lines+1;end
            if(pv)begin
                if(words>=172800 || packed_data!==expected[words])
                    $fatal(1,"grayscale/spatial/DDR reference mismatch at word %0d",words);
                words=words+1;
            end
        end
    end
    task tick(input bit v,input bit s,input [95:0] rgb);
        begin @(negedge clk);valid=v;sof=s;data=rgb;end
    endtask
    initial begin
        $readmemh("chain_input.hex",source);$readmemh("chain_expected.hex",expected);
        for(frame=0;frame<2;frame=frame+1)begin
            rst=0;valid=0;sof=0;repeat(5)@(negedge clk);rst=1;
            if(frame==0)begin tick(0,1,0);repeat(16)tick(0,0,0);end
            index=0;
            for(row=0;row<720;row=row+1)begin
                for(col=0;col<320;col=col+1)begin
                    if((col+row)%11==0 && index!=0)tick(0,0,0);
                    tick(1,frame==1 && index==0,source[index]);index=index+1;
                end
                // Many lines are contiguous: flush must overlap next-line input.
                if(row%3==0)repeat(3)tick(0,0,0);
            end
            repeat(24)tick(0,0,0);
            if(words!=172800||beats!=230400||lines!=720)$fatal(1,"geometry/tail flush mismatch");
        end
        $display("PASS SPATIAL CHAIN: 2 full 1280x720 frames, independent RGB->gray->horizontal->vertical->detail->tone->DDR reference, gaps/contiguous lines/borders/SOF/reset history");$finish;
    end
    initial begin #12000000;$fatal(1,"timeout");end
endmodule
