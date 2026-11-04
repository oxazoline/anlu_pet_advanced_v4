`timescale 1ns/1ps
module tb_face_capture;
    reg clk=0,rst=0,valid=0,sof=0;reg [95:0] data=0;always #5 clk=~clk;
    wire [31:0] status;ext_face_detector dut(clk,rst,data,valid,sof,status);
    defparam dut.classifier.MAX_CYCLES=100;
    defparam dut.ENABLE_ZOOM=0;
    reg [7:0] pixels[0:14399];reg [21:0] expected[0:14399];integer row,col,k,frame,idx;
    task tick(input bit v,input bit s,input [7:0] p);begin @(negedge clk);valid=v;sof=s;data={12{p}};end endtask
    initial begin
        $readmemh("face_face_center_pixels.hex",pixels);$readmemh("face_face_center_integral.hex",expected);
        repeat(3)@(negedge clk);rst=1;
        for(frame=0;frame<2;frame=frame+1)begin
            tick(0,1,0);tick(0,0,0);
            for(row=0;row<=715;row=row+1)begin
                for(col=0;col<320;col=col+1)begin
                    if((row+col)%11==0)tick(0,0,0);
                    idx=(row/8)*160+col/2;tick(1,0,pixels[idx]);
                end
                if(row%3==0)tick(0,0,0);
            end
            tick(0,0,0);wait(dut.busy);tick(0,1,0);tick(0,0,0);
            if(dut.capture)$fatal(1,"busy-frame capture was not skipped");
            wait(!dut.busy);repeat(3)tick(0,0,0);
            for(k=0;k<14400;k=k+1)if(dut.image_ram.line_store.memory[k]!==expected[k])$fatal(1,"integral mismatch frame=%0d address=%0d actual=%h expected=%h",frame,k,dut.image_ram.line_store.memory[k],expected[k]);
            if(status[31] || !status[30])$fatal(1,"watchdog must clear visibility and publish timeout");
        end
        rst=0;tick(0,0,0);if(status!==0)$fatal(1,"reset status");
        $display("PASS FACE CAPTURE: real four-pixel stream, 160x90 integral exact over two captures without clearing RAM; gaps/row strides/prefix arithmetic, busy SOF skipping, watchdog clears status and reset");$finish;
    end
    initial begin #12000000;$fatal(1,"timeout");end
endmodule
