`timescale 1ns/1ps
module tb_awb_frames;
    reg clk=0,rst=0,v=0,sof=0,last=0,ready=1;always #5 clk=~clk;
    reg [95:0] data=0;wire [95:0] q;wire valid,fs,ls,ir;
    awb #(.IMG_WIDTH(16),.IMG_HEIGHT(4)) dut(clk,rst,last,sof,data,v,ir,ls,fs,q,valid,ready);
    reg [96:0] expected[0:1023];integer wr=0,rd=0,cycles=0,first_input=-1;
    reg [19:0] ref_r=20'h10000,ref_b=20'h10000;
    reg [95:0] color;integer lane,product;reg [7:0] er,eg,eb;
    always @(posedge clk)begin
        if(rst)begin
            cycles=cycles+1;
            if(v)begin
                if(first_input<0)first_input=cycles;
                for(lane=0;lane<4;lane=lane+1)begin
                    product=data[lane*24+16+:8]*ref_r;er=(product>>16)>255?255:(product>>16);
                    product=data[lane*24+:8]*ref_b;eb=(product>>16)>255?255:(product>>16);
                    eg=data[lane*24+8+:8];color[lane*24+:24]={er,eg,eb};
                end
                expected[wr]={last,color};wr=wr+1;
            end
            #1;
            if(fs!==sof || ir!==ready)$fatal(1,"early SOF or ready changed");
            if(valid)begin
                if(rd>=wr || {ls,q}!==expected[rd])$fatal(1,"AWB stream mismatch sample=%0d actual=%h expected=%h",rd,{ls,q},expected[rd]);
                if(rd==0 && cycles-first_input<64)$fatal(1,"pixel lead insufficient for video FIFO reset");
                rd=rd+1;
            end else if(q!==0 || ls)$fatal(1,"invalid-cycle output qualification");
        end
    end
    integer f,i,k;reg [31:0] rr,gg,bb;reg [63:0] sumr,sumg,sumb,ratio;
    initial begin
        repeat(3)@(negedge clk);rst=1;
        for(f=0;f<5;f=f+1)begin
            case(f)0:begin rr=40;gg=80;bb=20;end
                1:begin rr=80;gg=40;bb=160;end
                2:begin rr=250;gg=250;bb=250;end
                3:begin rr=0;gg=200;bb=0;end
                default:begin rr=255;gg=20;bb=30;end endcase
            @(negedge clk);sof=1;v=0;
            @(negedge clk);sof=0;
            sumr=1;sumg=1;sumb=1;
            for(i=0;i<16;i=i+1)begin
                if(i%5==2)begin @(negedge clk);v=0;last=0;end
                @(negedge clk);v=1;last=(i%4)==3;
                for(k=0;k<4;k=k+1)data[k*24+:24]={8'(rr>252?rr:rr+k),8'(gg>252?gg:gg+k),8'(bb>252?bb:bb+k)};
                if(rr+gg+bb<720)begin sumr=sumr+rr;sumg=sumg+gg;sumb=sumb+bb;end
            end
            @(negedge clk);v=0;last=0;
            repeat(160)@(negedge clk);
            if(wr!=rd)$fatal(1,"AWB dropped/tail pixels");
            ratio=(sumg<<16)/sumr;ref_r=ratio>20'hfffff ? 20'hfffff : ratio[19:0];
            ratio=(sumg<<16)/sumb;ref_b=ratio>20'hfffff ? 20'hfffff : ratio[19:0];
        end
        rst=0;repeat(2)@(negedge clk);if(valid || q!==0)$fatal(1,"reset left stale video");
        $display("PASS FRAME AWB: five frames, four lanes, independent integer gain ratios, frame-only updates, unity startup, white rejection, gain/output saturation, gaps/line markers, >=64-cycle SOF lead, tail/reset");$finish;
    end
endmodule
