// Same-frame causal vertical stage: current row and two previous rows.
// Preserve center when either neighbor differs by >32. No frame blending.
// Synchronous dual-port line RAMs; no array reset; first two rows bypass.
module basic_vertical_denoise #(
    parameter integer IMAGE_WIDTH=1280, IMAGE_HEIGHT=720,
    parameter integer THRESHOLD=32
)(
    input wire I_clk,I_rst_n,
    input wire [95:0] I_data,
    input wire I_valid,I_sof,
    output reg [95:0] O_data,
    output reg O_valid,O_sof,O_last
);
    (* ram_style="bram" *) reg [31:0] row1[0:IMAGE_WIDTH/4-1];
    (* ram_style="bram" *) reg [31:0] row2[0:IMAGE_WIDTH/4-1];
    reg [31:0] q1,q2,current_d;
    reg [10:0] col,row,col_d;
    reg valid_d,sof_d,history_d,last_d;
    wire [10:0] addr=I_sof?11'd0:col;
    wire [31:0] gray_word={I_data[95:88],I_data[71:64],I_data[47:40],I_data[23:16]};
    always @(posedge I_clk)begin
        if(I_rst_n && I_valid)begin q1<=row1[addr];q2<=row2[addr];end
        if(I_rst_n && valid_d && !I_sof)begin
            row1[col_d]<=current_d;row2[col_d]<=q1;
        end
    end
    function [7:0] smooth;
        input [7:0] c,a,b;
        reg [7:0] da,db;reg [9:0] sum;
        begin
            da=c>a?c-a:a-c;db=c>b?c-b:b-c;
            sum=({2'b0,c}<<1)+{2'b0,a}+{2'b0,b}+10'd2;
            smooth=(da<=THRESHOLD && db<=THRESHOLD)?sum[9:2]:c;
        end
    endfunction
    wire [7:0] y0=history_d?smooth(current_d[31:24],q1[31:24],q2[31:24]):current_d[31:24];
    wire [7:0] y1=history_d?smooth(current_d[23:16],q1[23:16],q2[23:16]):current_d[23:16];
    wire [7:0] y2=history_d?smooth(current_d[15:8],q1[15:8],q2[15:8]):current_d[15:8];
    wire [7:0] y3=history_d?smooth(current_d[7:0],q1[7:0],q2[7:0]):current_d[7:0];
    always @(posedge I_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin
            col<=0;row<=0;col_d<=0;current_d<=0;valid_d<=0;sof_d<=0;
            history_d<=0;last_d<=0;O_data<=0;O_valid<=0;O_sof<=0;O_last<=0;
        end else begin
            valid_d<=I_valid;sof_d<=I_sof;
            O_valid<=valid_d && !I_sof;O_sof<=sof_d;O_last<=last_d && valid_d && !I_sof;
            O_data<={{3{y0}},{3{y1}},{3{y2}},{3{y3}}};
            if(I_sof)begin col<=0;row<=0;end
            if(I_valid)begin
                current_d<=gray_word;col_d<=addr;history_d<=!I_sof && row>=2;
                last_d<=addr==IMAGE_WIDTH/4-1;
                if(addr==IMAGE_WIDTH/4-1)begin col<=0;row<=row==IMAGE_HEIGHT-1?0:row+1'b1;end
                else col<=addr+1'b1;
            end
        end
    end
endmodule
