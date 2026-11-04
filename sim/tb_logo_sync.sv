`timescale 1ns/1ps
module tb_logo_sync;
    reg clk=0;always #5 clk=~clk;
    reg [14:0] address=15'h7fff;wire [24:0] old_pixel,new_pixel;
    anlogic_logo_rom reference(address,old_pixel);
    anlogic_logo_rom_sync dut(clk,address,new_pixel);
    reg [24:0] expected;
    integer n,visible=0;
    initial begin
        for(n=0;n<32768;n=n+1)begin
            @(negedge clk);address=n;@(posedge clk);#1;
            if(n>0 && new_pixel!==expected)$fatal(1,"logo alpha/RGB mismatch at %0d actual=%h expected=%h",n,new_pixel,old_pixel);
            if(n>0 && new_pixel[24])visible=visible+1;expected=old_pixel;
        end
        @(posedge clk);#1;if(new_pixel!==expected)$fatal(1,"last logo address");if(new_pixel[24])visible=visible+1;
        if(visible!=6387)$fatal(1,"visible logo count changed");
        $display("PASS LOGO SYNC: all 32768 addresses and all 25 alpha/RGB bits equal to original case ROM; two synchronous cycles");$finish;
    end
endmodule
