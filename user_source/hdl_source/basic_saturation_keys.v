// Active-low K3/K4. Q6 saturation: 0 gray, 64 normal chroma, 96 enhanced.
module basic_saturation_keys #(
    parameter integer DEBOUNCE_CYCLES=1035200,
    parameter integer REPEAT_CYCLES=12940000,
    parameter [6:0] DEFAULT_TARGET=0
)(
    input wire I_clk,I_rst_n,
    input wire [1:0] I_keys_n,
    output reg [6:0] O_target,
    output reg [1:0] O_mode
);
    (* ASYNC_REG="TRUE" *) reg [1:0] meta,sync;
    reg [1:0] stable,previous;
    reg [23:0] debounce_count,repeat_count;
    wire active=stable==1 || stable==2;
    wire step=active && (stable!=previous || repeat_count==REPEAT_CYCLES-1);
    always @(posedge I_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin
            meta<=0;sync<=0;stable<=0;previous<=0;
            debounce_count<=0;repeat_count<=0;O_target<=DEFAULT_TARGET;O_mode<=0;
        end else begin
            meta<=~I_keys_n;sync<=meta;
            if(sync==stable)debounce_count<=0;
            else if(debounce_count==DEBOUNCE_CYCLES-1)begin stable<=sync;debounce_count<=0;end
            else debounce_count<=debounce_count+1'b1;
            previous<=stable;
            // One view change per debounced chord; holding both never repeats.
            if(stable==3 && previous!=3)O_mode<=O_mode+2'd1;
            if(!active || stable!=previous || step)repeat_count<=0;
            else repeat_count<=repeat_count+1'b1;
            if(step && stable==1)O_target<=O_target<2?0:O_target-7'd2;
            else if(step && stable==2)O_target<=O_target>=94?96:O_target+7'd2;
        end
    end
endmodule
