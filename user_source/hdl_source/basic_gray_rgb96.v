// Independent four-pixel luminance pipeline, fixed two-clock latency.
// SOF may arrive in blanking and is propagated independently of valid.
// V16 timing: register each color's exact constant product before the final sum.
module basic_gray_rgb96 (
    input wire I_clk, input wire I_rst_n,
    input wire [95:0] I_data,
    input wire I_valid, input wire I_sof, input wire I_last,
    output reg [95:0] O_data,
    output reg O_valid, output reg O_sof, output reg O_last
);
    // Exact maxima: 19635, 38250 and 7395; no RAM or DSP multiplication.
    reg [14:0] red77[0:3];
    reg [15:0] green150[0:3];
    reg [12:0] blue29[0:3];
    reg valid_d, sof_d, last_d;
    function [14:0] red_product;
        input [7:0] pixel;
        reg [14:0] value;
        begin
            value={7'd0,pixel};
            red_product=((value<<6)+(value<<3))+((value<<2)+value);
        end
    endfunction
    function [15:0] green_product;
        input [7:0] pixel;
        reg [15:0] value;
        begin
            value={8'd0,pixel};
            green_product=((value<<7)+(value<<4))+((value<<2)+(value<<1));
        end
    endfunction
    function [12:0] blue_product;
        input [7:0] pixel;
        reg [12:0] value;
        begin
            value={5'd0,pixel};
            blue_product=((value<<4)+(value<<3))+((value<<2)+value);
        end
    endfunction
    wire [15:0] total[0:3];
    genvar lane;
    generate for(lane=0;lane<4;lane=lane+1)begin:combine
        assign total[lane]={1'b0,red77[lane]}+green150[lane]+{3'd0,blue29[lane]};
    end endgenerate
    integer n;
    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            for(n=0;n<4;n=n+1)begin red77[n]<=0;green150[n]<=0;blue29[n]<=0;end
            valid_d<=0; sof_d<=0; last_d<=0;
            O_data<=0; O_valid<=0; O_sof<=0; O_last<=0;
        end else begin
            for(n=0;n<4;n=n+1)begin
                red77[n]<=red_product(I_data[95-n*24-:8]);
                green150[n]<=green_product(I_data[87-n*24-:8]);
                blue29[n]<=blue_product(I_data[79-n*24-:8]);
                O_data[95-n*24-:24]<={3{total[n][15:8]}};
            end
            valid_d<=I_valid; sof_d<=I_sof; last_d<=I_last;
            O_valid<=valid_d; O_sof<=sof_d; O_last<=last_d;
        end
    end
endmodule
