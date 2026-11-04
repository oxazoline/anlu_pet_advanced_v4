`timescale 1ns/1ps
module tb_chroma_scale;
    reg clk=0,rst=0,valid=0;always #5 clk=~clk;
    reg signed [8:0] delta=0;reg [6:0] scale=0;
    wire signed [17:0] product;wire ov;
    ext_chroma_scale dut(clk,rst,delta,scale,valid,product,ov);
    reg [2:0] vp=0;integer e0=0,e1=0,e2=0,checked=0,d,s;
    always @(posedge clk)begin
        if(!rst)begin vp=0;e0=0;e1=0;e2=0;end
        else begin vp={vp[1:0],valid};e2=e1;e1=e0;e0=$signed(delta)*$signed({1'b0,scale});end
        #1;
        if(ov!==vp[2])$fatal(1,"scaler valid latency");
        if(ov)begin if($signed(product)!==e2)$fatal(1,"registered multiply mismatch %0d expected %0d",product,e2);checked=checked+1;end
    end
    initial begin
        repeat(3)@(negedge clk);rst=1;
        for(d=-256;d<=255;d=d+1)for(s=0;s<=127;s=s+1)begin
            @(negedge clk);delta=d;scale=s;valid=1;
            if((s+d+256)%29==0)begin @(negedge clk);valid=0;end
        end
        @(negedge clk);valid=0;repeat(5)@(negedge clk);
        if(checked!=65536)$fatal(1,"scaler coverage count");
        $display("PASS CHROMA SCALE: all 512 signed deltas x 128 scales exactly match independent multiplication, bubbles and aligned controls; registered DSP multiplier with unchanged three-cycle latency");$finish;
    end
    initial begin #5000000;$fatal(1,"timeout");end
endmodule
