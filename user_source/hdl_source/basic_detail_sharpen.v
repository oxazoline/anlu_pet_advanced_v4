// V5: four grayscale pixels per beat, centered 1x3 limited sharpening.
module basic_detail_sharpen #(
    parameter integer IMAGE_WIDTH=1280,
    parameter integer NOISE_GATE=6, MAX_CORRECTION=6
)(
    input wire I_clk,I_rst_n,
    input wire [95:0] I_data,
    input wire I_valid,I_sof,
    output reg [95:0] O_data,
    output reg O_valid,O_sof,O_last
);
    reg pending,pending_last;
    reg [95:0] held_data;
    reg [7:0] held_left,input_left;
    reg [10:0] group_index;
    wire [7:0] p0=held_data[95:88],p1=held_data[71:64];
    wire [7:0] p2=held_data[47:40],p3=held_data[23:16];
    wire [7:0] right=pending_last?p3:I_data[95:88];
    // Horizontal unsharp mask after spatial denoising, before tone mapping.
    // Reject fine residuals <=6; cap correction at 6/255. No frame history.
    function [7:0] smooth;
        input [7:0] l,c,r;
        reg [8:0] neighbors;
        reg signed [9:0] laplacian,value,correction;
        reg signed [7:0] residual;
        integer level;
        begin
            // c-floor((l+2*c+r+2)/4) = floor((2*c-l-r+1)/4).
            // Direct signed residual avoids the old low/abs/gate/cap adder chain.
            neighbors={1'b0,l}+{1'b0,r};
            laplacian=$signed({1'b0,c,1'b1})-$signed({1'b0,neighbors});
            residual=laplacian[9:2];
            correction=0;
            for(level=1;level<=MAX_CORRECTION;level=level+1)begin
                if($signed(residual)>=NOISE_GATE+2*level)correction=level;
                else if($signed(residual)<=-(NOISE_GATE+2*level))correction=-level;
            end
            value=$signed({2'b0,c})+correction;
            smooth=value<0?8'd0:(value>255?8'd255:value[7:0]);
        end
    endfunction
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n)begin
            pending<=0;pending_last<=0;held_data<=0;held_left<=0;input_left<=0;
            group_index<=0;O_data<=0;O_valid<=0;O_sof<=0;O_last<=0;
        end else begin
            O_valid<=0;O_sof<=I_sof;O_last<=0;
            if(I_sof)begin pending<=0;group_index<=0;input_left<=0;end
            if(!I_sof && pending && (pending_last || I_valid))begin
                O_data<={{3{smooth(held_left,p0,p1)}},{3{smooth(p0,p1,p2)}},
                         {3{smooth(p1,p2,p3)}},{3{smooth(p2,p3,right)}}};
                O_valid<=1;O_last<=pending_last;pending<=0;
            end
            if(I_valid)begin
                pending<=1;held_data<=I_data;
                held_left<=(I_sof || group_index==0)?I_data[95:88]:input_left;
                input_left<=I_data[23:16];
                pending_last<=(!I_sof && group_index==IMAGE_WIDTH/4-1);
                group_index<=(!I_sof && group_index==IMAGE_WIDTH/4-1)?0:
                             I_sof?1:group_index+1'b1;
            end
        end
    end
endmodule
