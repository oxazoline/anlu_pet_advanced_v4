// Static palette sprite. All layout/state is held per output frame.
module adv_pet_overlay(input wire I_clk,I_rst_n,I_vs,I_hs,I_de,input wire [23:0] I_rgb,
 input wire [31:0] I_ref,I_face,I_expression,output reg O_vs,O_hs,O_de,output reg [23:0] O_rgb);
 reg vd,dd;reg [10:0] x,y,px,py;reg [1:0] pose;reg mirror;
 wire [10:0] bx={I_ref[29:22],3'd0},by={1'b0,I_ref[21:15],3'd0};
 wire [10:0] bw={I_ref[14:7],3'd0},bh={1'b0,I_ref[6:0],3'd0};
 wire [11:0] cx={1'b0,bx}+{1'b0,bw[10:1]},cy={1'b0,by}+{1'b0,bh[10:1]};
 wire right_side=cx>=640;
 wire [11:0] right_x={1'b0,bx}+bw+12'd8;
 wire [10:0] next_x=right_side ? (bx>=200 ? bx-11'd200 : 11'd0) : (right_x>1088 ? 11'd1088 : right_x[10:0]);
 wire [10:0] next_y=cy<160 ? 11'd16 : cy>560 ? 11'd416 : cy-12'd144;
 wire hit=I_de && x>=px && x<px+192 && y>=py && y<py+288;
 wire [10:0] dx=x-px,dy=y-py;wire [5:0] sx=mirror ? 6'd47-dx[7:2] : dx[7:2];wire [6:0] sy=dy[8:2];
 // 4096-address bank, 48 columns. No general multiplier or divider.
 wire [11:0] local_addr=({5'd0,sy}<<5)+({5'd0,sy}<<4)+sx;
 wire [13:0] address={pose,12'd0}+local_addr;wire [23:0] pixel;
 adv_pet_rom rom(I_clk,address,pixel);
 reg vs1,hs1,de1,hit1,vs2,hs2,de2,hit2;reg [23:0] rgb1,rgb2;
 always @(posedge I_clk or negedge I_rst_n)begin
 if(!I_rst_n)begin vd<=0;dd<=0;x<=0;y<=0;px<=1072;py<=416;pose<=0;mirror<=0;
 vs1<=0;hs1<=0;de1<=0;hit1<=0;rgb1<=0;vs2<=0;hs2<=0;de2<=0;hit2<=0;rgb2<=0;O_vs<=0;O_hs<=0;O_de<=0;O_rgb<=0;end
 else begin
 vd<=I_vs;dd<=I_de;
 if(I_vs && !vd)begin x<=0;y<=0;end
 else begin if(I_de)x<=x+1'b1;else x<=0;if(!I_de && dd)y<=y+1'b1;end
 // Upstream frame-associated boxes are ready after output line zero.
 if(I_de && x==8 && y==1)begin
  if(I_ref[31])begin pose<=3;px<=next_x;py<=next_y;mirror<=!right_side;end
  else begin px<=1072;py<=416;mirror<=0;
   pose<=!I_face[31] ? 0 : I_expression[1:0]==1 ? 1 : I_expression[1:0]==3 ? 2 : 0;
  end
 end
 vs1<=I_vs;hs1<=I_hs;de1<=I_de;hit1<=hit;rgb1<=I_rgb;
 vs2<=vs1;hs2<=hs1;de2<=de1;hit2<=hit1;rgb2<=rgb1;
 O_vs<=vs2;O_hs<=hs2;O_de<=de2;O_rgb<=!de2 ? 24'd0 : hit2 ? pixel : rgb2;
 end end
endmodule
