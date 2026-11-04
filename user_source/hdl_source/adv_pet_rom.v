module adv_pet_rom(input wire I_clk,input wire [13:0] I_addr,output reg [23:0] O_rgb);
(* ram_style="block" *) reg [3:0] image[0:16383];reg [3:0] index;
initial $readmemh("pet_pixels.hex",image);
always @(posedge I_clk)begin index<=image[I_addr];case(index)
4'd0:O_rgb<=24'hf8f0ee;
4'd1:O_rgb<=24'hc9c1c8;
4'd2:O_rgb<=24'h888499;
4'd3:O_rgb<=24'h5778c0;
4'd4:O_rgb<=24'h54629f;
4'd5:O_rgb<=24'h52536e;
4'd6:O_rgb<=24'h3d559c;
4'd7:O_rgb<=24'h37436f;
4'd8:O_rgb<=24'h2e365b;
4'd9:O_rgb<=24'h262a3f;
4'd10:O_rgb<=24'h1a2445;
4'd11:O_rgb<=24'h141726;
4'd12:O_rgb<=24'h0b0d14;
4'd13:O_rgb<=24'h040509;
4'd14:O_rgb<=24'h010105;
4'd15:O_rgb<=24'h000000;
endcase end
endmodule
