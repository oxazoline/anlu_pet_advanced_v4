// Frame-statistics AWB. One shared 48/32 restoring divider computes R/B gains.
// A completed frame updates gains at the next SOF only; all four pixels share gains.
// Keep early SOF and >=64-cycle pixel delay for existing video FIFO reset ordering.
module awb #(parameter IMG_HEIGHT=1080,IMG_WIDTH=1920)(
    input wire I_clk,I_rst_n,I_tlast,I_tuser,input wire [95:0] I_tdata,
    input wire I_tvalid,output wire I_tready,output wire O_tlast,O_tuser,
    output wire [95:0] O_tdata,output wire O_tvalid,input wire O_tready);
    reg [31:0] sr,sg,sb,beat;
    reg [19:0] gain_r,gain_b,pending_r,pending_b;
    reg pending_valid,busy,blue;
    reg [47:0] numerator,quotient;
    reg [32:0] remainder;
    reg [31:0] denominator,den_b;
    reg [47:0] saved_n;
    reg [5:0] step;
    wire [9:0] rgb_sum={2'b0,I_tdata[23:16]}+{2'b0,I_tdata[15:8]}+{2'b0,I_tdata[7:0]};
    wire eligible=rgb_sum<720;
    wire [31:0] nr=(I_tuser?32'd1:sr)+(eligible?I_tdata[23:16]:8'd0);
    wire [31:0] ng=(I_tuser?32'd1:sg)+(eligible?I_tdata[15:8]:8'd0);
    wire [31:0] nb=(I_tuser?32'd1:sb)+(eligible?I_tdata[7:0]:8'd0);
    wire [32:0] shifted={remainder[31:0],numerator[47]};
    wire take=shifted>={1'b0,denominator};
    wire [47:0] next_q={quotient[46:0],take};
    wire [19:0] clipped_q=|next_q[47:20]?20'hfffff:next_q[19:0];
    wire [19:0] active_r=I_tuser && pending_valid?pending_r:gain_r;
    wire [19:0] active_b=I_tuser && pending_valid?pending_b:gain_b;
    always @(posedge I_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin
            sr<=1;sg<=1;sb<=1;beat<=0;gain_r<=20'h10000;gain_b<=20'h10000;
            pending_r<=20'h10000;pending_b<=20'h10000;pending_valid<=0;
            busy<=0;blue<=0;numerator<=0;quotient<=0;remainder<=0;denominator<=1;den_b<=1;saved_n<=0;step<=0;
        end else begin
            if(I_tuser)begin
                sr<=1;sg<=1;sb<=1;beat<=0;
                if(pending_valid)begin gain_r<=pending_r;gain_b<=pending_b;pending_valid<=0;end
            end
            if(I_tvalid)begin
                sr<=nr;sg<=ng;sb<=nb;
                if((I_tuser?32'd0:beat)==IMG_HEIGHT*IMG_WIDTH/4-1)begin
                    beat<=0;
                    if(!busy)begin
                        numerator<={ng,16'd0};saved_n<={ng,16'd0};denominator<=nr;den_b<=nb;
                        quotient<=0;remainder<=0;step<=47;blue<=0;busy<=1;
                    end
                end else beat<=(I_tuser?32'd0:beat)+1'b1;
            end
            if(busy)begin
                numerator<={numerator[46:0],1'b0};quotient<=next_q;
                remainder<=take?shifted-{1'b0,denominator}:shifted;
                if(step==0)begin
                    if(!blue)begin
                        pending_r<=clipped_q;blue<=1;denominator<=den_b;numerator<=saved_n;
                        quotient<=0;remainder<=0;step<=47;
                    end else begin pending_b<=clipped_q;pending_valid<=1;busy<=0;end
                end else step<=step-1'b1;
            end
        end
    end
    reg [27:0] pr[0:3],pb[0:3];reg [7:0] pg[0:3];reg pv,pl;
    integer n;
    always @(posedge I_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin pv<=0;pl<=0;for(n=0;n<4;n=n+1)begin pr[n]<=0;pg[n]<=0;pb[n]<=0;end end
        else begin
            pv<=I_tvalid;pl<=I_tlast;
            for(n=0;n<4;n=n+1)begin
                pr[n]<=active_r*I_tdata[n*24+16+:8];pb[n]<=active_b*I_tdata[n*24+:8];pg[n]<=I_tdata[n*24+8+:8];
            end
        end
    end
    wire [95:0] corrected;
    genvar k;generate for(k=0;k<4;k=k+1)begin:lane
        assign corrected[k*24+:24]={((|pr[k][27:24])?8'hff:pr[k][23:16]),pg[k],((|pb[k][27:24])?8'hff:pb[k][23:16])};
    end endgenerate
    (* ram_style="distributed" *) reg [96:0] delay_mem[0:63];
    reg [5:0] pointer;reg [63:0] valid_pipe;reg [96:0] delayed;reg valid_out;
    always @(posedge I_clk)begin
        delay_mem[pointer]<={pl,corrected};delayed<=delay_mem[pointer];
    end
    always @(posedge I_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin pointer<=0;valid_pipe<=0;valid_out<=0;end
        else begin pointer<=pointer+1'b1;valid_pipe<={valid_pipe[62:0],pv};valid_out<=valid_pipe[63];end
    end
    assign O_tdata=valid_out?delayed[95:0]:96'd0;
    assign O_tvalid=valid_out;assign O_tlast=valid_out && delayed[96];
    assign O_tuser=I_tuser;assign I_tready=O_tready;
endmodule
