// Frame-atomic object boxes and readable status, coordinates and real slot latency.
// Two pixel stages; RGB/VS/HS/DE stay aligned. No sprite data or frame buffer.
module adv_overlay(input wire I_clk,I_rst_n,I_vs,I_hs,I_de,input wire [23:0] I_rgb,
 input wire [31:0] I_ref,I_yeah,I_motion,I_info,input wire [63:0] I_metrics,
 output reg O_vs,O_hs,O_de,output reg [23:0] O_rgb,input wire [31:0] I_debug,input wire [31:0] I_ae,output wire [31:0] O_pet_ref);
 reg vs_d,de_d;reg [10:0] x,y;
 reg [31:0] ref_box,hand_box,motion_box,info;reg [63:0] metrics;
 assign O_pet_ref=ref_box;
 (* ram_style="distributed" *) reg [111:0] results[0:3];
 reg [15:0] query_id;reg [1:0] query_step,lookup_match;reg found;reg [95:0] lookup_boxes;
 wire [111:0] selected_results=results[query_id[1:0]];
 reg [1:0] draw_match;reg [31:0] debug,ae;
 always @(posedge I_clk)if(I_rst_n)results[I_info[17:16]]<={I_info[31:16],I_ref,I_yeah,I_motion};
 reg [19:0] lat_bcd,max_bcd,id_bcd,decimal_work;reg [15:0] binary_work;
 reg [4:0] decimal_step;reg [1:0] decimal_slot;reg decimal_busy;
 reg [19:0] adjusted;
 integer k,j;
 always @(*)begin adjusted=decimal_work;for(k=0;k<5;k=k+1)if(decimal_work[k*4+:4]>=5)adjusted[k*4+:4]=decimal_work[k*4+:4]+4'd3;end
 wire [19:0] next_bcd={adjusted[18:0],binary_work[15]};
 function [7:0] hexchar;input [3:0] a;begin hexchar=a<10?8'h30+a:8'h41+a-10;end endfunction
 function border;input [31:0] b;input [10:0] px,py;reg [10:0] bx,by,bw,bh;
 begin bx={b[29:22],3'd0};by={1'b0,b[21:15],3'd0};bw={b[14:7],3'd0};bh={1'b0,b[6:0],3'd0};
 border=b[31] && px>=bx && px<bx+bw && py>=by && py<by+bh &&
 (px<bx+2 || px+2>=bx+bw || py<by+2 || py+2>=by+bh);end endfunction
 wire ref_edge=border(ref_box,x,y),hand_edge=border(hand_box,x,y),motion_edge=border(motion_box,x,y);
 wire roi_edge=((x==32 || x==767) && y>=48 && y<688 || (y==48 || y==687) && x>=32 && x<768) && x[3];
 wire panel=x>=192 && x<928 && y>=80 && y<176;
 wire [5:0] column=(x-192)>>4;wire [2:0] text_row=(y-80)>>4;
 reg [367:0] text;reg [7:0] ch;reg [10:0] rx,ry,hx,hy;
 always @(*)begin
  rx={ref_box[29:22],3'd0};ry={1'b0,ref_box[21:15],3'd0};hx={hand_box[29:22],3'd0};hy={1'b0,hand_box[21:15],3'd0};
  case(text_row)
   0:begin text="ADV4 REF:0 YEAH:0 MOVE:0 AWB:A                ";text[367-9*8-:8]=ref_box[31]?"1":"0";text[367-16*8-:8]=hand_box[31]?"1":"0";text[367-23*8-:8]=motion_box[31]?"1":"0";end
   1:begin
    text="REF X:000 Y:000 YEAH X:000 Y:000 HEX          ";
    text[367-6*8-:8]=hexchar({1'b0,rx[10:8]});text[367-7*8-:8]=hexchar(rx[7:4]);text[367-8*8-:8]=hexchar(rx[3:0]);
    text[367-12*8-:8]=hexchar({1'b0,ry[10:8]});text[367-13*8-:8]=hexchar(ry[7:4]);text[367-14*8-:8]=hexchar(ry[3:0]);
    text[367-23*8-:8]=hexchar({1'b0,hx[10:8]});text[367-24*8-:8]=hexchar(hx[7:4]);text[367-25*8-:8]=hexchar(hx[3:0]);
    text[367-29*8-:8]=hexchar({1'b0,hy[10:8]});text[367-30*8-:8]=hexchar(hy[7:4]);text[367-31*8-:8]=hexchar(hy[3:0]);
   end
   2:begin
    text="LAT:00000MS MAX:00000MS ID:00000 V:0 R:0      ";
    for(j=0;j<5;j=j+1)begin text[367-(4+j)*8-:8]=8'h30+lat_bcd[19-j*4-:4];
     text[367-(16+j)*8-:8]=8'h30+max_bcd[19-j*4-:4];text[367-(27+j)*8-:8]=8'h30+id_bcd[19-j*4-:4];end
    text[367-35*8-:8]=metrics[63]?"1":"0";text[367-39*8-:8]=metrics[62]?"1":"0";
   end
   4:begin
    text="LIVE C:0 RAW:0 HOLD:0 SCORE:0000 HEX          ";
    text[367-7*8-:8]=debug[7]?"1":"0";text[367-13*8-:8]=debug[6]?"1":"0";text[367-20*8-:8]=debug[5]?"1":"0";
    for(j=0;j<4;j=j+1)text[367-(28+j)*8-:8]=hexchar(debug[31-j*4-:4]);
   end
   5:begin
    text="DRAW:0 MATCH:0 REF R:0 TRK:0 TP:00 HEX        ";
    text[367-5*8-:8]=hand_box[31]?"1":"0";text[367-13*8-:8]=8'h30+draw_match;
    text[367-21*8-:8]=debug[4]?"1":"0";text[367-27*8-:8]=ref_box[30]?"1":"0";text[367-32*8-:8]=hexchar(debug[15:12]);text[367-33*8-:8]=hexchar(debug[11:8]);
   end
   default:begin
    text="MODE:0 AE:A EXP:000 Y:00 T:00 BUSY:0          ";
    text[367-5*8-:8]=8'h30+metrics[61:60];text[367-10*8-:8]=ae[31]?"A":"M";
    for(j=0;j<3;j=j+1)text[367-(16+j)*8-:8]=hexchar(ae[11-j*4-:4]);
    text[367-22*8-:8]=hexchar(ae[19:16]);text[367-23*8-:8]=hexchar(ae[15:12]);
    text[367-27*8-:8]=hexchar(ae[27:24]);text[367-28*8-:8]=hexchar(ae[23:20]);text[367-35*8-:8]=ae[29]?"1":"0";
   end
  endcase
  ch=column<46?text[367-column*8-:8]:8'h20;
 end
 reg [7:0] glyph_char;reg [3:0] glyph_row,glyph_column;wire [15:0] font_bits;
 adv_font_rom font(I_clk,ch,y[3:0],font_bits);
 reg vs1,hs1,de1,panel1;reg [23:0] rgb1,edge_color1;reg edge1;
 always @(posedge I_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin
   vs_d<=0;de_d<=0;x<=0;y<=0;ref_box<=0;hand_box<=0;motion_box<=0;info<=0;metrics<=0;draw_match<=0;debug<=0;ae<=0;query_id<=0;query_step<=0;lookup_match<=0;found<=0;lookup_boxes<=0;
   lat_bcd<=0;max_bcd<=0;id_bcd<=0;decimal_work<=0;binary_work<=0;decimal_step<=0;decimal_slot<=0;decimal_busy<=0;
   glyph_char<=0;glyph_row<=0;glyph_column<=0;vs1<=0;hs1<=0;de1<=0;rgb1<=0;panel1<=0;edge1<=0;edge_color1<=0;
   O_vs<=0;O_hs<=0;O_de<=0;O_rgb<=0;
  end else begin
   vs_d<=I_vs;de_d<=I_de;
   if(I_vs && !vs_d)begin x<=0;y<=0;ref_box<=0;hand_box<=0;motion_box<=0;info<=I_info;end
   else begin if(I_de)x<=x+1'b1;else x<=0;if(!I_de && de_d)y<=y+1'b1;end
   // Metrics become valid at the first output pixel. Snapshot after line0,
   // then serially convert 3 fields well before the status panel at line80.
   // Serial cache lookup during line0 uses one RAM read port.
   if(I_de && y==0 && x==3)begin query_id<=I_metrics[27:12];query_step<=0;found<=0;lookup_match<=0;end
   if(I_de && y==0 && x>=4 && x<=6 && !found)begin
    if(selected_results[111:96]==query_id)begin found<=1;lookup_boxes<=selected_results[95:0];lookup_match<=query_step==0?1:2;end
    else begin query_id<=query_id-16'd1;query_step<=query_step+1'b1;end
   end
   if(I_de && x==1279 && y==0)begin
    metrics<=I_metrics;debug<=I_debug;ae<=I_ae;
    if(I_metrics[63] && I_metrics[59:44]<500 && found && (lookup_match==1 || I_metrics[59:44]<200))begin
     draw_match<=lookup_match;ref_box<=lookup_boxes[95:64];hand_box<=lookup_boxes[63:32];motion_box<=lookup_boxes[31:0];
    end else begin draw_match<=0;ref_box<=0;hand_box<=0;motion_box<=0;end
    binary_work<=I_metrics[59:44];decimal_work<=0;decimal_step<=0;decimal_slot<=0;decimal_busy<=1;
   end else if(decimal_busy)begin
    decimal_work<=next_bcd;binary_work<={binary_work[14:0],1'b0};
    if(decimal_step==15)begin
     decimal_step<=0;decimal_work<=0;
     case(decimal_slot)
      0:begin lat_bcd<=next_bcd;binary_work<=metrics[43:28];decimal_slot<=1;end
      1:begin max_bcd<=next_bcd;binary_work<=metrics[27:12];decimal_slot<=2;end
      default:begin id_bcd<=next_bcd;decimal_busy<=0;end
     endcase
    end else decimal_step<=decimal_step+1'b1;
   end
   glyph_char<=ch;glyph_row<=y[3:0];glyph_column<=x[3:0];panel1<=panel;
   vs1<=I_vs;hs1<=I_hs;de1<=I_de;rgb1<=I_rgb;edge1<=!(x>=16 && x<176 && y>=16 && y<176) && (ref_edge || hand_edge || roi_edge);
   edge_color1<=ref_edge?24'hff40ff:hand_edge?24'h20ffff:24'h408080;
   O_vs<=vs1;O_hs<=hs1;O_de<=de1;
   O_rgb<=!de1?24'd0:panel1?(font_bits[15-glyph_column]?24'hffffff:24'h101820):(edge1?edge_color1:rgb1);
  end
 end
endmodule
