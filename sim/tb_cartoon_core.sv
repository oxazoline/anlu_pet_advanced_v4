`timescale 1ns/1ps
module tb_cartoon_core;
    reg clk=0,rst=0,valid=0,sof=0;
    reg [95:0] data=0;
    reg [1:0] mode=0;
    always #5 clk=~clk;
    wire [95:0] out;
    wire ov,os,ol;
    ext_cartoon_rgb96 #(.IMAGE_WIDTH(20),.IMAGE_HEIGHT(7)) dut(
        clk,rst,data,valid,sof,mode,out,ov,os,ol);
    reg [95:0] source[0:209],expected0[0:209],expected1[0:209],expected2[0:209],expected3[0:209];
    reg [95:0] expected;
    reg [6:0] vp=0,sp=0,lp=0;
    integer reference_col=0;
    integer index=0,frame=0,row,col,received=0,total=0,lines=0,frame_mode=0;
    always @(posedge clk)begin
        if(!rst)begin vp=0;sp=0;lp=0;reference_col=0;end
        else begin
            vp={vp[5:0],valid};sp={sp[5:0],sof};
            lp={lp[5:0],valid && !sof && reference_col==4};
            if(sof)reference_col=0;
            if(valid)reference_col=reference_col==4?0:reference_col+1;
        end
        #1;
        if(rst)begin
            if({ov,os,ol}!=={vp[6],sp[6],lp[6]})$fatal(1,"control latency/line-end mismatch");
            if(ov)begin
                case(frame_mode)
                    0:expected=expected0[index+received];
                    1:expected=expected1[index+received];
                    2:expected=expected2[index+received];
                    default:expected=expected3[index+received];
                endcase
                if(received>=35 || out!==expected)
                    $fatal(1,"cartoon reference frame=%0d beat=%0d mode=%0d actual=%h expected=%h",frame,received,frame_mode,out,expected);
                received=received+1;total=total+1;if(ol)lines=lines+1;
            end
        end
    end
    task tick(input bit v,input bit s,input [95:0] d);
        begin @(negedge clk);valid=v;sof=s;data=d;end
    endtask
    initial begin
        $readmemh("cartoon_small_input.hex",source);
        $readmemh("cartoon_small_mode0.hex",expected0);
        $readmemh("cartoon_small_mode1.hex",expected1);
        $readmemh("cartoon_small_mode2.hex",expected2);
        $readmemh("cartoon_small_mode3.hex",expected3);
        repeat(3)@(negedge clk);rst=1;
        for(frame=0;frame<24;frame=frame+1)begin
            // Last three frames reuse vectors after a reset with stale RAM.
            index=(frame/4)*35;received=0;lines=0;frame_mode=frame%4;mode=frame_mode;
            if(frame==6)begin rst=0;repeat(3)tick(0,0,0);rst=1;end
            if(frame%2==0)begin tick(0,1,0);tick(0,0,0);end
            for(row=0;row<7;row=row+1)begin
                for(col=0;col<5;col=col+1)begin
                    if((row+col)%3==0 && (row!=0 || col!=0))tick(0,0,0);
                    tick(1,frame%2==1 && row==0 && col==0,source[index+row*5+col]);
                    if(row==3 && col==1)mode=(frame_mode+1)%4;
                end
            end
            col=0;repeat(12)tick(0,0,0);
            if(received!=35 || lines!=7)$fatal(1,"missing pixels/lines or tail flush");
        end
        if(total!=840)$fatal(1,"total beats");
        $display("PASS CARTOON CORE: independent image reference; all modes; mid-beat split; 3x3 RGB smoothing, soft luma terraces, bounded contours and diagnostic mask; four lanes and beat boundaries; valid gaps; both SOF forms; frame-atomic mode; stale-RAM reset; 24 frames");$finish;
    end
    initial begin #100000;$fatal(1,"timeout");end
endmodule
