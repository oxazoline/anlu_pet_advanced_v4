`timescale 1ns/1ps
module tb_saturation_keys;
    reg clk=0,rst=0;reg [1:0] keys=3;
    always #5 clk=~clk;
    wire [6:0] target;
    wire [1:0] mode,extension_mode;
    basic_saturation_keys #(5,20) dut(clk,rst,keys,target,mode);
    wire [6:0] extension_target;
    basic_saturation_keys #(5,20,64) extension_default(clk,rst,keys,extension_target,extension_mode);
    reg slow_clk=0;always #17 slow_clk=~slow_clk;
    reg [7:0] status=0;wire [7:0] received;
    basic_status_cdc cdc(clk,slow_clk,rst,status,received);
    integer saved,k;
    reg [7:0] previous_held=0;reg was_pending=0;
    always @(negedge clk)begin
        if(!rst)begin previous_held=0;was_pending=0;end
        else begin
            if(was_pending && cdc.held!==previous_held)$fatal(1,"CDC bus changed before ack");
            previous_held=cdc.held;was_pending=cdc.request!=cdc.ack_sync[1];
        end
    end
    task clocks(input integer n);
        begin repeat(n)@(negedge clk);end
    endtask
    initial begin
        clocks(3);rst=1;clocks(10);
        if(target!=0)$fatal(1,"default must retain V5 gray");
        if(extension_target!=64)$fatal(1,"extension must start at 100 percent saturation");
        keys=1;clocks(2);keys=3;clocks(12);
        if(target!=0)$fatal(1,"contact bounce changed target");
        if(extension_target!=64)$fatal(1,"extension default changed on bounce");
        keys=1;clocks(12);
        if(target!=2)$fatal(1,"K4 single step");
        if(extension_target!=66)$fatal(1,"extension K4 single step");
        clocks(1000);if(target!=96)$fatal(1,"hold increase/upper clamp");
        keys=3;clocks(12);saved=target;clocks(100);
        if(target!=saved)$fatal(1,"release keeps repeating");
        keys=0;clocks(12);saved=target;clocks(100);
        if(target!=saved)$fatal(1,"both keys must not change saturation");
        if(mode!=1 || extension_mode!=1)$fatal(1,"chord must advance view once, no hold repeats");
        for(k=0;k<4;k=k+1)begin
            keys=3;clocks(12);keys=0;clocks(80);
            if(mode!==2'((k+2)%4))$fatal(1,"view cycle/debounce mismatch");
        end
        keys=3;clocks(12);keys=2;clocks(1100);
        if(target!=0)$fatal(1,"K3 decrease/lower clamp");
        keys=3;clocks(12);keys=1;clocks(12);
        if(target!=2)$fatal(1,"must recover after reaching minimum");
        // Faster source updates must coalesce safely and eventually deliver.
        for(k=0;k<80;k=k+1)begin status=8'(k*17);clocks(1);end
        status=8'ha5;clocks(100);
        if(received!==8'ha5)$fatal(1,"CDC lost final rapid update");
        status=8'h40;clocks(100);
        if(received!==8'h40)$fatal(1,"CDC next value");
        rst=0;clocks(2);if(received!==0)$fatal(1,"CDC reset");if(target!=0)$fatal(1,"reset");if(mode!=0)$fatal(1,"view reset");
        $display("PASS SAT KEYS: synchronizer/debounce/tap/hold/both/release/clamps/reset; asynchronous bundled CDC rapid updates/held bus/reset");$finish;
    end
    initial begin #100000;$fatal(1,"timeout");end
endmodule
