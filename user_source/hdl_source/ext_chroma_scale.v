// Exact signed delta * unsigned Q6 scale, three cycles as in V3.
// V4 rebalances the logic bottleneck onto available DSP multipliers.
module ext_chroma_scale(
    input wire I_clk,I_rst_n,
    input wire signed [8:0] I_delta,
    input wire [6:0] I_scale,
    input wire I_valid,
    output reg signed [17:0] O_product,
    output reg O_valid
);
    reg signed [8:0] delta;
    reg signed [7:0] scale;
    reg valid_d,valid_q;
    (* use_dsp="yes" *) reg signed [17:0] multiplied;
    always @(posedge I_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin
            delta<=0;scale<=0;valid_d<=0;valid_q<=0;multiplied<=0;O_product<=0;O_valid<=0;
        end else begin
            delta<=I_delta;scale<=$signed({1'b0,I_scale});valid_d<=I_valid;
            multiplied<=delta*scale;valid_q<=valid_d;
            O_product<=multiplied;O_valid<=valid_q;
        end
    end
endmodule
