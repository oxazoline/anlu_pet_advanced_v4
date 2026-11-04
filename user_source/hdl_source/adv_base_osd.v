// V1 baseline view: exact original logo, face box and unchanged expression labels.
// Legacy large diagnostics are replaced by adv_overlay; four fault lamps remain.
module adv_base_osd #(parameter V4_MODE=0)(input wire I_clk,I_rst_n,I_vs,I_hs,I_de,input wire [23:0] I_rgb,
 input wire [31:0] I_face,I_expression,input wire [3:0] I_fault,
 output reg O_vs,O_hs,O_de,output reg [23:0] O_rgb);
 reg vs_d,de_d;reg [10:0] x,y;reg[31:0]face,expression;reg[3:0]fault;
 wire logo_hit=x>=16 && x<176 && y>=16 && y<176;
 wire[10:0]lx=x-16,ly=y-16;wire[14:0]logo_address=(ly<<7)+(ly<<5)+lx;wire[24:0]logo_pixel;
 generate if(V4_MODE)begin:compact
 wire [12:0] ca=((ly>>1)<<6)+((ly>>1)<<4)+(lx>>1);
 adv_logo_compact logo(I_clk,ca,logo_pixel);
 end else begin:original
 anlogic_logo_rom_sync logo(I_clk,logo_address,logo_pixel);end endgenerate
 wire[10:0]fx={face[29:22],3'd0},fy={1'b0,face[21:15],3'd0},fw={1'b0,face[14:8],3'd0};
 wire border=face[31] && x>=fx && x<fx+fw && y>=fy && y<fy+fw && (x<fx+2 || x+2>=fx+fw || y<fy+2 || y+2>=fy+fw);
 wire c_label=expression[11] && expression[1:0]==0 && expression[8] && expression[6] && expression[5];
 wire[103:0]c_text="EXPR CONFUSED";reg[95:0]label;
 always @(*)case(expression[1:0])1:label="EXPR HAPPY  ";2:label="EXPR NEUTRAL";3:label="EXPR NERVOUS";default:label="            ";endcase
 wire expression_hit=face[31] && (expression[1:0]!=0 || c_label) && x>=16 && x<(c_label?224:208) && y>=680 && y<696;
 wire[10:0]ex=x-16;
 wire brand_hit=x>=192 && x<448 && y>=32 && y<64;
 reg[7:0]character;reg[3:0]row_sel,col_sel;
 always @(*)begin
  row_sel=brand_hit?y[4:1]:y[3:0]-4'd8;col_sel=brand_hit?x[4:1]:ex[3:0];character=8'h20;
  if(brand_hit)case((x-192)>>5)0:character=8'h80;1:character=8'h81;3:character="A";4:character="D";5:character="V";6:character=V4_MODE?"4":"3";default:character=8'h20;endcase
  else if(expression_hit)character=c_label?c_text[103-ex[7:4]*8-:8]:label[95-ex[7:4]*8-:8];
 end
 reg[7:0]glyph_char;reg[3:0]glyph_row,glyph_col;wire[15:0]font_bits;adv_font_rom font(I_clk,character,row_sel,font_bits);
 wire fault_hit=x>=704 && x<720 && y>=112 && y<240 && ((y-112)&31)<16;
 reg vs1,hs1,de1,logo1,text1,border1,fault1;reg[23:0]rgb1,fault_color1;
 reg vs2,hs2,de2,logo2;reg[23:0]rgb2;
 always @(posedge I_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin
   vs_d<=0;de_d<=0;x<=0;y<=0;face<=0;expression<=0;fault<=0;
   glyph_char<=0;glyph_row<=0;glyph_col<=0;vs1<=0;hs1<=0;de1<=0;logo1<=0;text1<=0;border1<=0;fault1<=0;rgb1<=0;fault_color1<=0;
   vs2<=0;hs2<=0;de2<=0;logo2<=0;rgb2<=0;O_vs<=0;O_hs<=0;O_de<=0;O_rgb<=0;
  end else begin
   vs_d<=I_vs;de_d<=I_de;
   if(I_vs && !vs_d)begin x<=0;y<=0;face<=I_face;expression<=I_expression;fault<=I_fault;end
   else begin if(I_de)x<=x+1'b1;else x<=0;if(!I_de && de_d)y<=y+1'b1;end
   glyph_char<=character;glyph_row<=row_sel;glyph_col<=col_sel;
   vs1<=I_vs;hs1<=I_hs;de1<=I_de;logo1<=logo_hit;text1<=brand_hit || expression_hit;border1<=border;fault1<=fault_hit;rgb1<=I_rgb;
   fault_color1<=fault[3-((y-112)>>5)]?24'hff2020:24'h20ff20;
   vs2<=vs1;hs2<=hs1;de2<=de1;logo2<=logo1;
   rgb2<=text1?(font_bits[15-glyph_col]?24'hffff80:24'h101010):(border1?24'h20ff20:fault1?fault_color1:rgb1);
   O_vs<=vs2;O_hs<=hs2;O_de<=de2;O_rgb<=!de2?24'd0:logo2 && logo_pixel[24]?logo_pixel[23:0]:rgb2;
  end
 end
endmodule
