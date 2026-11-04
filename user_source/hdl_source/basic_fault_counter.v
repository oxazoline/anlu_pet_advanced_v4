// Count source-clock cycles containing a failed transfer, saturating at FFFF.
// I2C supplies one pulse for each newly asserted bus error.
// Gray counts cross through two registers; only their first stage is excepted.
module basic_fault_counter (
    input wire I_source_clk, I_display_clk, I_rst_n,
    input wire I_event, I_running,
    output wire [15:0] O_boot, O_run
);
    (* ASYNC_REG="TRUE" *) reg run_meta, run_sync;
    reg [15:0] boot_count, run_count, boot_gray, run_gray;
    (* ASYNC_REG="TRUE" *) reg [15:0] boot_meta, boot_sync, count_meta, count_sync;
    wire [15:0] next_boot=boot_count+16'd1, next_run=run_count+16'd1;
    always @(posedge I_source_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            run_meta<=0;run_sync<=0;boot_count<=0;run_count<=0;
            boot_gray<=0;run_gray<=0;
        end else begin
            run_meta<=I_running;run_sync<=run_meta;
            if(I_event) begin
                if(run_sync && run_count!=16'hffff) begin
                    run_count<=next_run;run_gray<=(next_run>>1)^next_run;
                end else if(!run_sync && boot_count!=16'hffff) begin
                    boot_count<=next_boot;boot_gray<=(next_boot>>1)^next_boot;
                end
            end
        end
    end
    always @(posedge I_display_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin boot_meta<=0;boot_sync<=0;count_meta<=0;count_sync<=0;end
        else begin
            boot_meta<=boot_gray;boot_sync<=boot_meta;
            count_meta<=run_gray;count_sync<=count_meta;
        end
    end
    function [15:0] ungray;
        input [15:0] g;
        integer i;
        begin ungray[15]=g[15];for(i=14;i>=0;i=i-1)ungray[i]=ungray[i+1]^g[i];end
    endfunction
    assign O_boot=ungray(boot_sync), O_run=ungray(count_sync);
endmodule
