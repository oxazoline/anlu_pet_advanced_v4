// V3: seven-cycle, four-pixel RGB pipeline; no frame-history buffer.
// Separable 3x3 [1,2,1] smoothing using two native line RAMs.
// Continuous, bounded luminance terraces preserve channel differences.
// Supported weak/strong contours darken by only 25%, never paint black ink.
// Modes: 0 enhanced color; 1 split smooth; 2 split soft style; 3 split edge mask.
module ext_cartoon_rgb96 #(
    parameter integer IMAGE_WIDTH=1280, IMAGE_HEIGHT=720,
    parameter integer EDGE_THRESHOLD=18, STRONG_THRESHOLD=28
)(
    input wire I_clk,I_rst_n,input wire [95:0] I_data,
    input wire I_valid,I_sof,input wire [1:0] I_mode,
    output reg [95:0] O_data,output reg O_valid,O_sof,O_last
);
    localparam integer GROUPS=IMAGE_WIDTH/4;
    reg [10:0] col,row;
    reg [1:0] mode;
    wire [10:0] address=I_sof?11'd0:col;
    wire [10:0] current_row=I_sof?11'd0:row;
    reg [47:0] raw_left;
    function [23:0] smooth3;
        input [23:0] a,b,c;
        integer k; reg [9:0] sum;
        begin
            for(k=0;k<3;k=k+1)begin
                sum={2'b0,a[23-k*8 -:8]}+({2'b0,b[23-k*8 -:8]}<<1)+
                    {2'b0,c[23-k*8 -:8]}+10'd2;
                smooth3[23-k*8 -:8]=sum[9:2];
            end
        end
    endfunction
    function [7:0] luma;
        input [23:0] a; reg [9:0] sum;
        begin sum={2'b0,a[23:16]}+({2'b0,a[15:8]}<<1)+{2'b0,a[7:0]};luma=sum[9:2];end
    endfunction
    function [7:0] absdiff;
        input [7:0] a,b;
        begin absdiff=a>b?a-b:b-a;end
    endfunction
    function [8:0] gradient;
        input [7:0] a,b,dy;
        begin gradient={1'b0,absdiff(a,b)}+{1'b0,dy};end
    endfunction
    function signed [5:0] terrace_delta;
        input [4:0] rem32;
        reg signed [6:0] r;
        begin
            r=$signed({2'b0,rem32});
            if(rem32<8)terrace_delta=-(r>>>1);
            else if(rem32<24)terrace_delta=(r-7'sd16)>>>1;
            else terrace_delta=(7'sd32-r)>>>1;
        end
    endfunction
    function [23:0] soft_style;
        input [23:0] rgb; input [7:0] y;
        reg signed [5:0] delta;
        reg signed [9:0] value;
        integer k;
        begin
            delta=terrace_delta(y[4:0]);
            for(k=0;k<3;k=k+1)begin
                value=$signed({2'b0,rgb[23-k*8 -:8]})+delta;
                soft_style[23-k*8 -:8]=value<0?8'd0:value>255?8'd255:value[7:0];
            end
        end
    endfunction
    function [23:0] contour;
        input [23:0] rgb;
        integer k; reg [7:0] c;
        begin
            for(k=0;k<3;k=k+1)begin
                c=rgb[23-k*8 -:8];contour[23-k*8 -:8]=c-(c>>2);
            end
        end
    endfunction
    reg [95:0] raw1,raw2,raw3,raw4,raw5,raw6;
    reg [95:0] h1,h2,h3,a3,filtered4,filtered5,filtered6,styled5,styled6;
    reg [31:0] dy4;
    reg [10:0] col1,col2,col3,col4,col5,row1,row2,row3,row4,row5;
    reg [1:0] mode1,mode2,mode3,mode4,mode5,mode6;
    reg v1,v2,v3,v4,v5,v6,s1,s2,s3,s4,s5,s6,l1,l2,l3,l4,l5,l6;
    reg [3:0] weak5,strong5,edge6,apply5,apply6;
    reg [7:0] filtered_left;
    reg weak_left,strong_left;
    reg [7:0] edge_line[0:GROUPS-1];
    wire [95:0] prior_h,prior2_h;
    ext_line_ram_rgb96 row_one(I_clk,I_rst_n && v1,col1[8:0],h1,prior_h);
    // RAM2 stores the first RAM's old row, with a full cycle for its output.
    ext_line_ram_rgb96 row_two(I_clk,I_rst_n && v2,col2[8:0],prior_h,prior2_h);
    wire [95:0] history2=row3<2?a3:prior2_h;
    wire [31:0] fy4={luma(filtered4[95:72]),luma(filtered4[71:48]),
                     luma(filtered4[47:24]),luma(filtered4[23:0])};
    wire [31:0] left_y={col4==0?fy4[31:24]:filtered_left,fy4[31:8]};
    wire [3:0] left_weak={col5==0?1'b0:weak_left,weak5[3:1]};
    wire [3:0] left_strong={col5==0?1'b0:strong_left,strong5[3:1]};
    wire [7:0] above=row5==0?8'd0:edge_line[col5];
    always @(posedge I_clk)if(I_rst_n && v5)edge_line[col5]<={strong5,weak5};
    integer lane;
    reg [23:0] p,prev1,prev2;
    reg [8:0] strength;
    reg [7:0] vertical_difference;
    always @(posedge I_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin
            col<=0;row<=0;mode<=2;raw_left<=0;
            raw1<=0;raw2<=0;raw3<=0;raw4<=0;raw5<=0;raw6<=0;
            h1<=0;h2<=0;h3<=0;a3<=0;filtered4<=0;filtered5<=0;filtered6<=0;styled5<=0;styled6<=0;dy4<=0;
            col1<=0;col2<=0;col3<=0;col4<=0;col5<=0;
            row1<=0;row2<=0;row3<=0;row4<=0;row5<=0;
            mode1<=2;mode2<=2;mode3<=2;mode4<=2;mode5<=2;mode6<=2;
            v1<=0;v2<=0;v3<=0;v4<=0;v5<=0;v6<=0;
            s1<=0;s2<=0;s3<=0;s4<=0;s5<=0;s6<=0;
            l1<=0;l2<=0;l3<=0;l4<=0;l5<=0;l6<=0;
            weak5<=0;strong5<=0;edge6<=0;apply5<=0;apply6<=0;
            filtered_left<=0;weak_left<=0;strong_left<=0;
            O_data<=0;O_valid<=0;O_sof<=0;O_last<=0;
        end else begin
            if(I_sof)begin col<=0;row<=0;mode<=I_mode;raw_left<=0;end
            // S1: causal horizontal smoothing, repeating the first pixel.
            v1<=I_valid;s1<=I_sof;l1<=I_valid && address==GROUPS-1;
            if(I_valid)begin
                raw1<=I_data;col1<=address;row1<=current_row;mode1<=I_sof?I_mode:mode;
                for(lane=0;lane<4;lane=lane+1)begin
                    p=I_data[95-lane*24 -:24];
                    if(lane==0)begin
                        prev1=address==0?p:raw_left[23:0];
                        prev2=address==0?p:raw_left[47:24];
                    end else begin
                        prev1=I_data[119-lane*24 -:24];
                        if(lane==1)prev2=address==0?I_data[95:72]:raw_left[23:0];
                        else prev2=I_data[143-lane*24 -:24];
                    end
                    h1[95-lane*24 -:24]<=smooth3(prev2,prev1,p);
                end
                raw_left<=I_data[47:0];
                if(address==GROUPS-1)begin col<=0;row<=current_row==IMAGE_HEIGHT-1?0:current_row+1'b1;end
                else col<=address+1'b1;
            end
            // S2/S3: cascaded one-cycle read-before-write native row stores.
            v2<=v1;s2<=s1;l2<=l1;raw2<=raw1;h2<=h1;col2<=col1;row2<=row1;mode2<=mode1;
            v3<=v2;s3<=s2;l3<=l2;raw3<=raw2;h3<=h2;col3<=col2;row3<=row2;mode3<=mode2;
            a3<=row2==0?h2:prior_h;
            // S4: centered vertical smoothing and derivative at the same row.
            v4<=v3;s4<=s3;l4<=l3;raw4<=raw3;col4<=col3;row4<=row3;mode4<=mode3;
            for(lane=0;lane<4;lane=lane+1)begin
                filtered4[95-lane*24 -:24]<=smooth3(history2[95-lane*24 -:24],a3[95-lane*24 -:24],h3[95-lane*24 -:24]);
                vertical_difference=absdiff(luma(h3[95-lane*24 -:24]),luma(history2[95-lane*24 -:24]));
                dy4[31-lane*8 -:8]<=row3==0?8'd0:{1'b0,vertical_difference[7:1]};
            end
            // S5: continuous +/-4 luma terraces; no independent RGB bins.
            v5<=v4;s5<=s4;l5<=l4;raw5<=raw4;filtered5<=filtered4;col5<=col4;row5<=row4;mode5<=mode4;
            if(v4)filtered_left<=fy4[7:0];
            for(lane=0;lane<4;lane=lane+1)begin
                strength=gradient(fy4[31-lane*8 -:8],left_y[31-lane*8 -:8],dy4[31-lane*8 -:8]);
                weak5[3-lane]<=strength>=EDGE_THRESHOLD;
                strong5[3-lane]<=strength>=STRONG_THRESHOLD;
                styled5[95-lane*24 -:24]<=soft_style(filtered4[95-lane*24 -:24],fy4[31-lane*8 -:8]);
                apply5[3-lane]<=col4*4+lane>=IMAGE_WIDTH/2;
            end
            // S6: local two-threshold support, not full connected hysteresis.
            v6<=v5;s6<=s5;l6<=l5;raw6<=raw5;filtered6<=filtered5;styled6<=styled5;mode6<=mode5;apply6<=apply5;
            edge6<=weak5 & (left_weak | above[3:0]) & (strong5 | left_strong | above[7:4]);
            if(v5)begin weak_left<=weak5[0];strong_left<=strong5[0];end
            // S7: all views retain exact enhanced-color bypass on the left.
            O_valid<=v6;O_sof<=s6;O_last<=v6 && l6;
            for(lane=0;lane<4;lane=lane+1)begin
                if(mode6==0 || !apply6[3-lane])O_data[95-lane*24 -:24]<=raw6[95-lane*24 -:24];
                else if(mode6==1)O_data[95-lane*24 -:24]<=filtered6[95-lane*24 -:24];
                else if(mode6==3)O_data[95-lane*24 -:24]<=edge6[3-lane]?24'hffffff:24'h000000;
                else O_data[95-lane*24 -:24]<=edge6[3-lane]?contour(styled6[95-lane*24 -:24]):styled6[95-lane*24 -:24];
            end
        end
    end
endmodule
