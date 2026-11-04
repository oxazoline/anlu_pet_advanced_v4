`timescale 1ns/1ps
module tb_fault_counter;
    reg src=0,disp=0,rst=0,event_in=0,running=0;
    always #7 src=~src;always #5 disp=~disp;
    wire [15:0] boot_count,run_count;
    basic_fault_counter dut(src,disp,rst,event_in,running,boot_count,run_count);
    task events(input integer n);
        begin @(negedge src);event_in=1;repeat(n)@(negedge src);event_in=0;end
    endtask
    initial begin
        repeat(4)@(negedge src);rst=1;
        events(7);repeat(10)@(negedge disp);
        if(boot_count!==7||run_count!==0)$fatal(1,"startup counts lost");
        running=1;repeat(4)@(negedge src);
        events(13);repeat(10)@(negedge disp);
        if(boot_count!==7||run_count!==13)$fatal(1,"RUN/BOOT classification mismatch");
        events(65540);repeat(10)@(negedge disp);
        if(run_count!==16'hffff||boot_count!==7)$fatal(1,"counter must saturate without clearing BOOT");
        rst=0;repeat(3)@(negedge disp);
        if(boot_count!==0||run_count!==0)$fatal(1,"reset mismatch");
        $display("PASS COUNTER: asynchronous clocks, BOOT/RUN split, event cycles, CDC settle, saturation/reset");$finish;
    end
    initial begin #2000000;$fatal(1,"timeout");end
endmodule
