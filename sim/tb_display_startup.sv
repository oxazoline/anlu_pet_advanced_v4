`timescale 1ns/1ps
module tb_display_startup;
    reg cam=0,pix=0,rst=0,sof=0,ddr=0;
    always #7 cam=~cam;
    always #5 pix=~pix;
    wire released;
    basic_display_startup dut(cam,pix,rst,sof,ddr,released);
    task frame;
        begin @(negedge cam);sof=1;@(negedge cam);sof=0;repeat(8)@(negedge cam);end
    endtask
    initial begin
        repeat(4)@(negedge cam);rst=1;
        frame();frame();
        if(released!==0)$fatal(1,"released before three source frames");
        frame();repeat(12)@(negedge pix);
        if(released!==0)$fatal(1,"released without DDR calibration");
        ddr=1;repeat(8)@(negedge pix);
        if(released!==1)$fatal(1,"display not released after readiness");
        rst=0;#1;if(released!==0)$fatal(1,"asynchronous reset failed");
        repeat(3)@(negedge cam);rst=1;
        frame();frame();if(released!==0)$fatal(1,"source readiness survived reset");
        frame();repeat(8)@(negedge pix);
        if(released!==1)$fatal(1,"restart failed");
        $display("PASS STARTUP: independent clocks, three SOFs, DDR gate and reset recovery");
        $finish;
    end
endmodule
