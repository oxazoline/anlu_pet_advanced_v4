// Four grayscale pixels per beat, centered horizontal 1x3 edge-aware smoothing.
// Neighbors differing from the center by >24 levels are excluded as edges.
// One pending beat supplies the right neighbor across beat boundaries. End-of-
// line is derived from pixel count, never from valid gaps. No temporal blending.
module basic_spatial_denoise #(
    parameter integer IMAGE_WIDTH=1280,
    parameter integer THRESHOLD=24
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
    function [7:0] smooth;
        input [7:0] l,c,r;
        reg [7:0] dl,dr;
        reg [9:0] sum;
        begin
            dl=l>c?l-c:c-l;dr=r>c?r-c:c-r;
            sum={2'b0,l}+({2'b0,c}<<1)+{2'b0,r}+10'd2;
            smooth=(dl<=THRESHOLD && dr<=THRESHOLD)?sum[9:2]:c;
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
