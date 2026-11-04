module adv_logo_compact(input wire I_clk,input wire [12:0] I_addr,output reg [24:0] O_pixel);
(* ram_style="block" *) reg [3:0] image[0:8191];reg [3:0] index;initial $readmemh("logo_compact.hex",image);
always @(posedge I_clk)begin index<=image[I_addr];case(index)
4'd0:O_pixel<=25'h0000000;
4'd1:O_pixel<=25'h1debbbf;
4'd2:O_pixel<=25'h1c18790;
4'd3:O_pixel<=25'h1ea7f84;
4'd4:O_pixel<=25'h1f86a6f;
4'd5:O_pixel<=25'h1f56167;
4'd6:O_pixel<=25'h1354461;
4'd7:O_pixel<=25'h11d2d4f;
4'd8:O_pixel<=25'h11c2d4f;
4'd9:O_pixel<=25'h11c2d4e;
4'd10:O_pixel<=25'h1f12128;
4'd11:O_pixel<=25'h1ef1e26;
4'd12:O_pixel<=25'h1f11d25;
4'd13:O_pixel<=25'h1ef1c25;
4'd14:O_pixel<=25'h1ed1c24;
4'd15:O_pixel<=25'h1000000;
endcase end endmodule
