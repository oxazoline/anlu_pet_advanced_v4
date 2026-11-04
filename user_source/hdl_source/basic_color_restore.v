// V4: exact DSP-backed chroma scaling. Preserve the V5 processed luminance; reattach co-located source chroma.
// Input streams represent the SAME frame/pixel order; source precedes luma.
// 32 beats cover V5 pipeline latency even with valid gaps (not line storage).
module basic_color_restore(
    input wire I_clk,I_rst_n,
    input wire [95:0] I_color,
    input wire I_color_valid,I_color_sof,
    input wire [95:0] I_luma,
    input wire I_luma_valid,I_luma_sof,I_luma_last,
    input wire [6:0] I_target,
    output reg [6:0] O_active,
    output reg [95:0] O_data,
    output reg O_valid,O_sof,O_last,
    output reg O_alignment_error
);
    (* ram_style="distributed" *) reg [95:0] fifo[0:31];
    reg [4:0] wp,rp;
    reg [5:0] count;
    reg waiting_sof;
    wire aligned=!waiting_sof || I_luma_sof;
    wire pop=I_luma_valid && aligned && !I_color_sof && count!=0;
    wire push=I_color_valid && (count<32 || pop);
    wire [95:0] head=fifo[rp];
    reg [95:0] rgb1;
    reg [31:0] y1,tone1,tone2,tone3,tone4;
    reg [6:0] sat1;
    reg v1,s1,l1,s2,l2,s3,l3,s4,l4;
    wire signed [17:0] product[0:11];
    wire [11:0] product_valid;
    genvar lane,channel;
    generate for(lane=0;lane<4;lane=lane+1)begin: scale_pixel
        for(channel=0;channel<3;channel=channel+1)begin: scale_channel
            wire signed [8:0] delta=$signed({1'b0,rgb1[95-lane*24-channel*8 -:8]})-
                $signed({1'b0,y1[31-lane*8 -:8]});
            ext_chroma_scale scaler(I_clk,I_rst_n,delta,sat1,v1,
                product[lane*3+channel],product_valid[lane*3+channel]);
        end
    end endgenerate
    integer p,c;
    function [7:0] luminance;
        input [23:0] rgb;
        reg [15:0] r,g,b,sum;
        begin
            r={8'd0,rgb[23:16]};g={8'd0,rgb[15:8]};b={8'd0,rgb[7:0]};
            sum=77*r+150*g+29*b;luminance=sum[15:8];
        end
    endfunction
    function [7:0] clip;
        input [7:0] y;
        input signed [17:0] chroma;
        reg signed [18:0] value;
        begin
            value=$signed({1'b0,y})+(chroma>>>6);
            clip=value<0?8'd0:value>255?8'd255:value[7:0];
        end
    endfunction
    wire fifo_write=I_color_valid && (I_color_sof || push);
    wire [4:0] fifo_write_address=I_color_sof?5'd0:wp;
    always @(posedge I_clk)if(I_rst_n && fifo_write)fifo[fifo_write_address]<=I_color;
    always @(posedge I_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin
            wp<=0;rp<=0;count<=0;waiting_sof<=1;O_active<=0;O_alignment_error<=0;
            rgb1<=0;y1<=0;tone1<=0;tone2<=0;tone3<=0;tone4<=0;sat1<=0;
            v1<=0;s1<=0;l1<=0;s2<=0;l2<=0;s3<=0;l3<=0;s4<=0;l4<=0;
            O_data<=0;O_valid<=0;O_sof<=0;O_last<=0;

        end else begin
            if(I_color_sof)begin
                waiting_sof<=1;
                wp<=I_color_valid?1:0;rp<=0;count<=I_color_valid?1:0;
                O_active<=I_target>96?7'd96:I_target;
            end else begin
                if(I_luma_sof)waiting_sof<=0;
                if(push)wp<=wp+1'b1;
                if(pop)rp<=rp+1'b1;
                case({push,pop})
                    2'b10:count<=count+1'b1;
                    2'b01:count<=count-1'b1;
                endcase
                if((I_color_valid && !push)||(I_luma_valid && aligned && !pop))O_alignment_error<=1;
            end
            // Independently propagate early SOF, as in the V5 pipeline.
            v1<=pop;s1<=I_luma_sof;l1<=I_luma_last;
            rgb1<=head;sat1<=O_active;
            for(p=0;p<4;p=p+1)begin
                y1[31-p*8 -:8]<=luminance(head[95-p*24 -:24]);
                tone1[31-p*8 -:8]<=I_luma[95-p*24 -:8];
            end
            // Delay luma and markers through the three-stage exact scaler.
            s2<=s1;l2<=l1;tone2<=tone1;
            s3<=s2;l3<=l2;tone3<=tone2;
            s4<=s3;l4<=l3;tone4<=tone3;
            O_valid<=product_valid[0];O_sof<=s4;O_last<=l4;
            for(p=0;p<4;p=p+1)for(c=0;c<3;c=c+1)
                O_data[95-p*24-c*8 -:8]<=clip(tone4[31-p*8 -:8],product[p*3+c]);
        end
    end
endmodule
