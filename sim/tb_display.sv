`timescale 1ns/1ps
// Behavioral read side of the configured non-show-ahead, unregistered FIFO.
// Preloaded DDR words isolate serializer ordering and HDMI control alignment.
module w128_d512_fifo(
    input rst,clkw,clkr,we,re,
    input [127:0] di,
    output reg [127:0] dout,
    output reg valid,
    output full_flag,empty_flag,afull,aempty,
    output [8:0] wrusedw,rdusedw
);
    reg [127:0] words[0:719];
    integer ptr=0;
    initial $readmemh("display_words.hex",words);
    assign wrusedw=9'd300;
    assign rdusedw=9'd300;
    assign {full_flag,empty_flag,afull,aempty}=4'b0000;
    always @(posedge clkr or posedge rst) begin
        if(rst) begin ptr<=0; dout<=0; valid<=0; end
        else begin
            valid<=re;
            if(re) begin dout<=words[ptr]; ptr<=ptr+1; end
        end
    end
endmodule

module tb_display;
    reg pixel_clk=0, ddr_clk=0, rst=0, frame=0, de=0, user=0, last=0;
    always #9.615 pixel_clk=~pixel_clk;
    always #7.5 ddr_clk=~ddr_clk;
    wire [23:0] rgb, out_rgb;
    wire out_de;
    reg [23:0] expected[0:3839];
    integer x,y,index=0,errors=0;
    video_out serializer (
        .I_rst_n(rst),.I_ddr_clk(ddr_clk),.O_video_out_rd_busy(),
        .I_video_in_wr_busy(1'b1),.I_video_out_rp(2'd0),.O_ddr_user_rd_en(),
        .O_ddr_user_addr(),.I_ddr_user_ready(1'b0),.I_ddr_user_rd_valid(1'b0),
        .I_ddr_user_rd_data(128'd0),.I_dsi_clk(pixel_clk),
        .I_video_vsync(frame),.I_video_rd_en(de),.O_vdieo_data(rgb)
    );
    hdmi_mixer #(.IMG_WIDTH(1280),.IMG_HEIGHT(720),.DEBUG_MODE(0)) mixer (
        .I_clk(pixel_clk),.I_rst_n(rst),.I_video_vsync(~frame),.I_video_hsync(1'b0),
        .I_video_de(de),.I_video_user(user),.I_video_last(last),.I_debug_status(4'd0),
        .O_video_rd_en(),.I_video_rd_data(rgb),.O_hdmi_vsync(),.O_hdmi_hsync(),
        .O_hdmi_de(out_de),.O_hdmi_data(out_rgb)
    );
    always @(posedge pixel_clk) begin
        #1;
        if(rst && out_de) begin
            if(index>=3840 || out_rgb !== expected[index]) begin
                if(errors<8) $display("DISPLAY mismatch pixel=%0d actual=%h expected=%h",index,out_rgb,expected[index]);
                errors=errors+1;
            end
            index=index+1;
        end
    end
    initial begin
        $readmemh("display_expected.hex",expected);
        repeat(10) @(negedge pixel_clk);
        rst=1; frame=1;
        repeat(20) @(negedge pixel_clk);
        frame=0;
        repeat(20) @(negedge pixel_clk);
        for(y=0;y<3;y=y+1) begin
            for(x=0;x<1280;x=x+1) begin
                @(negedge pixel_clk);
                de=1; user=(x==0 && y==0); last=(x==1279);
            end
            @(negedge pixel_clk); de=0; user=0; last=0;
            repeat(40) @(negedge pixel_clk);
        end
        repeat(10) @(negedge pixel_clk);
        if(errors || index!=3840) $fatal(1,"DISPLAY FAIL errors=%0d pixels=%0d",errors,index);
        $display("PASS: serializer and HDMI DE aligned, 3840 distinct RGB pixels in three 1280-pixel rows match packed DDR byte stream.");
        $finish;
    end
endmodule
