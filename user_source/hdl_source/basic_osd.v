// Logo/font data reused from lab_ex3; two-stage display overlay with registered glyph selection.
module basic_osd #(parameter integer COMPACT_DEBUG=1, ENABLE_CONFUSED_UI=1) (
    input wire I_clk, input wire I_rst_n,
    input wire I_vs, input wire I_hs, input wire I_de,
    input wire [23:0] I_rgb, input wire [3:0] I_fault,
    input wire [63:0] I_boot_counts, I_run_counts,
    input wire I_running,
    input wire [31:0] I_error_addresses,
    input wire [70:0] I_readback_status,
    input wire [7:0] I_saturation_status,
    output reg O_vs, output reg O_hs, output reg O_de,
    output reg [23:0] O_rgb,
    input wire [1:0] I_view_status,
    input wire [31:0] I_face_status,
    input wire [31:0] I_expression_status,
    input wire [167:0] I_expression_diagnostic,
    input wire [7:0] I_preview_gray,
    input wire I_preview_valid,input wire [7:0] I_preview_id,
    output wire [9:0] O_preview_address
);
    reg vs_d, de_d;
    reg [10:0] x, y;
    // x is reset on every blank pixel and at frame reset, so it is already
    // zero on the first active pixel. Avoid a DE mux on all glyph/ROM paths.
    wire [10:0] px=x;
    wire logo_area=px>=16 && px<176 && y>=16 && y<176;
    wire [10:0] lx=px-11'd16, ly=y-11'd16;
    wire [14:0] logo_addr=({4'd0,ly}<<7)+({4'd0,ly}<<5)+lx;
    wire [24:0] logo_pixel;
    anlogic_logo_rom_sync u_logo(.I_clk(I_clk),.I_addr(logo_addr),.O_pixel(logo_pixel));
    wire text_area=px>=192 && px<864 && y>=32 && y<64;
    wire [10:0] tx=px-11'd192, ty=y-11'd32;
    reg [31:0] face_status,expression_status;reg [167:0] expression_diagnostic;
    reg [1:0] view_status;
    reg [7:0] character;
    always @(*) begin
        case(tx[9:5])
            0: character=8'h80; 1: character=8'h81;
            3: character="C"; 4: character="T"; 5: character="3"; 6: character="0"; 7: character="0"+view_status;
            8: character="1"; 9: character="2"; 10: character="8"; 11: character="0";
            12: character="X"; 13: character="7"; 14: character="2"; 15: character="0";
            18:character="F";19:character=face_status[31]?"1":"0";20:character=face_status[30]?(face_status[31]?"M":"T"):(face_status[31] && face_status[6:0]==0?"H":(face_status[31] && face_status[7]?"P":" "));
            default: character=" ";
        endcase
    end
    wire [15:0] font_row;
    osd_char_lib u_font(.I_char(character),.I_row(ty[4:1]),.O_row_bits(font_row));
    wire text_pixel=text_area && font_row[15-tx[4:1]];
    // Snapshot once per frame so decimal/hex digits cannot tear within a frame.
    reg [63:0] boot_counts, run_counts;
    reg [3:0] fault_snapshot;
    reg running;
    reg [31:0] error_addresses;
    reg [7:0] saturation_status;
    reg [15:0] saturation_bcd;
    reg [70:0] readback_status;
    wire [47:0] rb=readback_status[63:16];
    wire verify_ready=readback_status[70];
    wire [5:0] verify_mask=readback_status[69:64];
    wire diag_area=view_status==3 && px>=192 && px<672 && y>=80 && y<400;
    wire [10:0] dx=px-11'd192, dy=y-11'd80;
    wire [3:0] cell_x=dx[8:5];
    wire [3:0] row_index=dy[8:5];
    reg [7:0] diag_char;
    reg [15:0] boot_word,run_word;
    reg [3:0] digit;
    reg [23:0] diag_color;
    function [7:0] hexchar;
        input [3:0] n;
        begin hexchar=n<10 ? 8'h30+n : 8'h41+n-10;end
    endfunction
    // Constant conversion at frame snapshot; no decimal arithmetic in pixel path.
    function [15:0] sat_decimal;
        input [6:0] value;
        begin case(value)
            7'd0:sat_decimal=16'h0000;
            7'd1:sat_decimal=16'h0001;
            7'd2:sat_decimal=16'h0003;
            7'd3:sat_decimal=16'h0004;
            7'd4:sat_decimal=16'h0006;
            7'd5:sat_decimal=16'h0007;
            7'd6:sat_decimal=16'h0009;
            7'd7:sat_decimal=16'h0010;
            7'd8:sat_decimal=16'h0012;
            7'd9:sat_decimal=16'h0014;
            7'd10:sat_decimal=16'h0015;
            7'd11:sat_decimal=16'h0017;
            7'd12:sat_decimal=16'h0018;
            7'd13:sat_decimal=16'h0020;
            7'd14:sat_decimal=16'h0021;
            7'd15:sat_decimal=16'h0023;
            7'd16:sat_decimal=16'h0025;
            7'd17:sat_decimal=16'h0026;
            7'd18:sat_decimal=16'h0028;
            7'd19:sat_decimal=16'h0029;
            7'd20:sat_decimal=16'h0031;
            7'd21:sat_decimal=16'h0032;
            7'd22:sat_decimal=16'h0034;
            7'd23:sat_decimal=16'h0035;
            7'd24:sat_decimal=16'h0037;
            7'd25:sat_decimal=16'h0039;
            7'd26:sat_decimal=16'h0040;
            7'd27:sat_decimal=16'h0042;
            7'd28:sat_decimal=16'h0043;
            7'd29:sat_decimal=16'h0045;
            7'd30:sat_decimal=16'h0046;
            7'd31:sat_decimal=16'h0048;
            7'd32:sat_decimal=16'h0050;
            7'd33:sat_decimal=16'h0051;
            7'd34:sat_decimal=16'h0053;
            7'd35:sat_decimal=16'h0054;
            7'd36:sat_decimal=16'h0056;
            7'd37:sat_decimal=16'h0057;
            7'd38:sat_decimal=16'h0059;
            7'd39:sat_decimal=16'h0060;
            7'd40:sat_decimal=16'h0062;
            7'd41:sat_decimal=16'h0064;
            7'd42:sat_decimal=16'h0065;
            7'd43:sat_decimal=16'h0067;
            7'd44:sat_decimal=16'h0068;
            7'd45:sat_decimal=16'h0070;
            7'd46:sat_decimal=16'h0071;
            7'd47:sat_decimal=16'h0073;
            7'd48:sat_decimal=16'h0075;
            7'd49:sat_decimal=16'h0076;
            7'd50:sat_decimal=16'h0078;
            7'd51:sat_decimal=16'h0079;
            7'd52:sat_decimal=16'h0081;
            7'd53:sat_decimal=16'h0082;
            7'd54:sat_decimal=16'h0084;
            7'd55:sat_decimal=16'h0085;
            7'd56:sat_decimal=16'h0087;
            7'd57:sat_decimal=16'h0089;
            7'd58:sat_decimal=16'h0090;
            7'd59:sat_decimal=16'h0092;
            7'd60:sat_decimal=16'h0093;
            7'd61:sat_decimal=16'h0095;
            7'd62:sat_decimal=16'h0096;
            7'd63:sat_decimal=16'h0098;
            7'd64:sat_decimal=16'h0100;
            7'd65:sat_decimal=16'h0101;
            7'd66:sat_decimal=16'h0103;
            7'd67:sat_decimal=16'h0104;
            7'd68:sat_decimal=16'h0106;
            7'd69:sat_decimal=16'h0107;
            7'd70:sat_decimal=16'h0109;
            7'd71:sat_decimal=16'h0110;
            7'd72:sat_decimal=16'h0112;
            7'd73:sat_decimal=16'h0114;
            7'd74:sat_decimal=16'h0115;
            7'd75:sat_decimal=16'h0117;
            7'd76:sat_decimal=16'h0118;
            7'd77:sat_decimal=16'h0120;
            7'd78:sat_decimal=16'h0121;
            7'd79:sat_decimal=16'h0123;
            7'd80:sat_decimal=16'h0125;
            7'd81:sat_decimal=16'h0126;
            7'd82:sat_decimal=16'h0128;
            7'd83:sat_decimal=16'h0129;
            7'd84:sat_decimal=16'h0131;
            7'd85:sat_decimal=16'h0132;
            7'd86:sat_decimal=16'h0134;
            7'd87:sat_decimal=16'h0135;
            7'd88:sat_decimal=16'h0137;
            7'd89:sat_decimal=16'h0139;
            7'd90:sat_decimal=16'h0140;
            7'd91:sat_decimal=16'h0142;
            7'd92:sat_decimal=16'h0143;
            7'd93:sat_decimal=16'h0145;
            7'd94:sat_decimal=16'h0146;
            7'd95:sat_decimal=16'h0148;
            7'd96:sat_decimal=16'h0150;
            default:sat_decimal=16'h0150;
        endcase end
    endfunction
    always @(*) begin
        boot_word=0;run_word=0;diag_char=" ";digit=0;diag_color=24'hffffff;
        case(row_index)
            1:begin boot_word=boot_counts[63:48];run_word=run_counts[63:48];end
            2:begin boot_word=boot_counts[47:32];run_word=run_counts[47:32];end
            3:begin boot_word=boot_counts[31:16];run_word=run_counts[31:16];end
            4:begin boot_word=boot_counts[15:0];run_word=run_counts[15:0];end
            5:begin boot_word=error_addresses[31:16];run_word=error_addresses[15:0];end
            6:begin boot_word=readback_status[15:0];run_word={rb[43:40],rb[39:32],rb[31:28]};end
            7:begin boot_word=rb[23:8];run_word={8'd0,rb[7:0]};end
            8:begin boot_word={15'd0,verify_ready};run_word={10'd0,verify_mask};end
            9:begin boot_word=saturation_bcd;run_word={15'd0,saturation_status[7]};end
            default:begin end
        endcase
        if(row_index==0) begin
            // V2 G4 B    R: R is gray until RUN accounting is armed.
            case(cell_x)
                0:diag_char="E";1:diag_char="4";3:diag_char="G";4:diag_char="1";5:diag_char="6";
                7:diag_char="B";11:diag_char="R";
                default:diag_char=" ";
            endcase
            if(cell_x==11)diag_color=running?24'h20ff20:24'h808080;
        end else begin
            case(row_index)
                1:case(cell_x) 0:diag_char="I";1:diag_char="2";2:diag_char="C";default:diag_char=" ";endcase
                2:case(cell_x) 0:diag_char="W";1:diag_char="I";2:diag_char="N";default:diag_char=" ";endcase
                3:case(cell_x) 0:diag_char="W";1:diag_char="O";2:diag_char="U";3:diag_char="T";default:diag_char=" ";endcase
                4:case(cell_x) 0:diag_char="R";1:diag_char="O";2:diag_char="U";3:diag_char="T";default:diag_char=" ";endcase
                5:case(cell_x) 0:diag_char="E";1:diag_char="R";2:diag_char="R";default:diag_char=" ";endcase
                6:case(cell_x) 0:diag_char="A";1:diag_char="E";default:diag_char=" ";endcase
                7:case(cell_x) 0:diag_char="A";1:diag_char="G";default:diag_char=" ";endcase
                8:case(cell_x) 0:diag_char="C";1:diag_char="H";2:diag_char="K";default:diag_char=" ";endcase
                9:case(cell_x) 0:diag_char="S";1:diag_char="A";2:diag_char="T";default:diag_char=" ";endcase
                default:diag_char=" ";
            endcase
            if(cell_x>=5 && cell_x<=8)begin
                case(cell_x)5:digit=boot_word[15:12];6:digit=boot_word[11:8];7:digit=boot_word[7:4];default:digit=boot_word[3:0];endcase
                diag_char=hexchar(digit);diag_color=boot_word!=0?24'hffb020:24'h20ff20;
            end
            if(cell_x>=10 && cell_x<=13)begin
                case(cell_x)10:digit=run_word[15:12];11:digit=run_word[11:8];12:digit=run_word[7:4];default:digit=run_word[3:0];endcase
                diag_char=hexchar(digit);diag_color=run_word!=0?24'hff2020:24'h20ff20;
            end
            if(row_index==5)diag_color=24'hffb020;
            if(row_index>=6 && row_index<=8)diag_color=!verify_ready?24'h808080:
                (verify_mask!=0?24'hff2020:24'h20ff20);
        end
    end
    wire [10:0] face_x={face_status[29:22],3'b0};
    wire [10:0] face_y={1'b0,face_status[21:15],3'b0};
    wire [10:0] face_size={1'b0,face_status[14:8],3'b0};
    wire [10:0] face_right=face_x+face_size-1'b1,face_bottom=face_y+face_size-1'b1;
    wire face_border=face_status[31] && face_size!=0 && px>=face_x && px<=face_right &&
        y>=face_y && y<=face_bottom && (px<face_x+2 || px+2>face_right || y<face_y+2 || y+2>face_bottom);
    wire [10:0] label_y=face_y>=16?face_y-11'd16:face_y;
    wire [10:0] face_dx=px-face_x,face_dy=y-label_y;
    wire face_label=face_status[31] && px>=face_x && px<face_x+64 && y>=label_y && y<label_y+16;
    reg [7:0] face_char;
    always @(*)case(face_dx[5:4])0:face_char="F";1:face_char="A";2:face_char="C";default:face_char="E";endcase
    wire confused_label=ENABLE_CONFUSED_UI && expression_status[11] && expression_status[1:0]==0 && expression_status[8] && expression_status[6] && expression_status[5];
    wire [103:0] confused_text="EXPR CONFUSED";
    wire expression_area=face_status[31] && (expression_status[1:0]!=0 || confused_label) && px>=16 && px<(confused_label?224:208) && y>=680 && y<696;
    wire [10:0] ex=px-16;
    reg [95:0] expression_text;
    always @(*)case(expression_status[1:0])
      1:expression_text="EXPR HAPPY  ";2:expression_text="EXPR NEUTRAL";
      3:expression_text="EXPR NERVOUS";default:expression_text="            ";
    endcase
    wire [7:0] expression_char=confused_label?confused_text[103-ex[7:4]*8-:8]:expression_text[95-ex[7:4]*8-:8];
    // V7 diagnostics use the existing CT73 view. Metadata is frame-snapshotted;
    // preview bank and its ID also change only at display frame boundaries.
    wire [10:0] debug_dx=px-944,debug_dy=y-80;
    wire [4:0] debug_col=debug_dx[8:4],debug_row=debug_dy[8:4];
    wire expression_debug_area=view_status==3 && px>=944 && px<1232 && y>=80 && y<304;
    wire [10:0] preview_dx=px-944,preview_dy=y-304;
    wire preview_area=view_status==3 && px>=944 && px<1072 && y>=304 && y<432;
    assign O_preview_address={preview_dy[6:2],preview_dx[6:2]};
    reg [143:0] debug_text;reg [31:0] debug_word;
    always @(*)begin
        debug_text="                  ";debug_word=0;
        case(debug_row)
          0:debug_text="EXPR DEBUG        ";
          1:begin debug_text=COMPACT_DEBUG?"H:LITE            ":"H:                ";debug_word=expression_diagnostic[63:32];end
          2:begin debug_text=COMPACT_DEBUG?"N:LITE            ":"N:                ";debug_word=expression_diagnostic[95:64];end
          3:begin debug_text=COMPACT_DEBUG?"R:LITE            ":"R:                ";debug_word=expression_diagnostic[127:96];end
          4:begin debug_text="A:                ";debug_word=expression_diagnostic[159:128];end
          5:begin debug_text="M:                ";debug_word=expression_diagnostic[31:0];end
          6:begin
            debug_text="CT 00 RS 0        ";
            debug_text[143-3*8-:8]=hexchar(expression_status[23:20]);
            debug_text[143-4*8-:8]=hexchar(expression_status[19:16]);
            debug_text[143-9*8-:8]=hexchar(expression_status[15:12]);
          end
          7:begin
            debug_text="ID 00 ROI 00      ";
            debug_text[143-3*8-:8]=hexchar(expression_status[31:28]);
            debug_text[143-4*8-:8]=hexchar(expression_status[27:24]);
            debug_text[143-10*8-:8]=hexchar(I_preview_id[7:4]);
            debug_text[143-11*8-:8]=hexchar(I_preview_id[3:0]);
          end
          8:begin
            debug_text="ROT 0 RAW H A0    ";
            debug_text[143-13*8-:8]=expression_diagnostic[129]?("0"+expression_diagnostic[128]):"?";
            debug_text[143-4*8-:8]="0"+expression_diagnostic[166];
            debug_text[143-14*8-:8]="J";debug_text[143-15*8-:8]="0"+expression_diagnostic[152];
            if(ENABLE_CONFUSED_UI)begin debug_text[143-16*8-:8]="Q";debug_text[143-17*8-:8]="0"+expression_diagnostic[155];end
            else begin debug_text[143-14*8-:8]="H";debug_text[143-15*8-:8]="R";end
            case(expression_status[10:9])
              0:debug_text[143-10*8-:8]="H";1:debug_text[143-10*8-:8]="N";
              2:debug_text[143-10*8-:8]="R";default:debug_text[143-10*8-:8]="O";
            endcase
          end
          9:begin debug_text="WIDTH             ";debug_word={21'd0,face_size};end
          10:begin
            debug_text="VALID 0 WAIT 0    ";
            debug_text[143-6*8-:8]="0"+expression_status[8];
            debug_text[143-13*8-:8]="0"+expression_status[7];
          end
          11:begin
            debug_text="LBL - E0 O0 P0    ";
            case(expression_status[1:0])
              1:debug_text[143-4*8-:8]="H";2:debug_text[143-4*8-:8]="N";
              3:debug_text[143-4*8-:8]="R";default:debug_text[143-4*8-:8]="-";
            endcase
            if(confused_label)debug_text[143-4*8-:8]="C";
            debug_text[143-7*8-:8]="0"+expression_status[6];
            debug_text[143-10*8-:8]="0"+expression_status[5];
            debug_text[143-13*8-:8]="0"+expression_status[4];
          end
          12:begin
            debug_text="SUP 0 BUSY 0 CAP 0";
            debug_text[143-4*8-:8]="0"+(face_status[6:0]!=0);
            debug_text[143-11*8-:8]="0"+expression_status[3];
            debug_text[143-17*8-:8]="0"+expression_status[2];
          end
          13:begin
            debug_text="ACT C0 B0 D0 O0 S0";
            debug_text[143-5*8-:8]="0"+expression_diagnostic[135];
            debug_text[143-8*8-:8]="0"+expression_diagnostic[134];
            debug_text[143-11*8-:8]="0"+expression_diagnostic[133];
            debug_text[143-14*8-:8]="0"+expression_diagnostic[132];
            debug_text[143-17*8-:8]="0"+expression_diagnostic[131];
            if(!ENABLE_CONFUSED_UI)begin
             debug_text="ACT B0 D0 S0      ";
             debug_text[143-5*8-:8]="0"+expression_diagnostic[134];
             debug_text[143-8*8-:8]="0"+expression_diagnostic[133];
             debug_text[143-11*8-:8]="0"+expression_diagnostic[131];
            end
          end
          default:begin end
        endcase
        if((debug_row>=1 && debug_row<=5) && !(COMPACT_DEBUG && debug_row<=3) && debug_col>=2 && debug_col<=9)
            debug_text[143-debug_col*8-:8]=hexchar(debug_word[31-(debug_col-2)*4-:4]);
        if(debug_row==9 && debug_col>=6 && debug_col<=9)
            debug_text[143-debug_col*8-:8]=hexchar(debug_word[15-(debug_col-6)*4-:4]);
    end
    wire [7:0] expression_debug_char=debug_text[143-debug_col*8-:8];
    reg pixel_face_border,pixel_preview_hit;
    reg [7:0] glyph_char;
    reg [3:0] glyph_row,glyph_col;
    reg [23:0] pixel_rgb,pixel_logo, glyph_color,pixel_fault_color;
    reg pixel_vs,pixel_hs,pixel_de,pixel_logo_hit,pixel_text_hit,pixel_fault_hit,pixel_diag_hit;
    wire [15:0] diag_font_row;
    osd_char_lib u_diag_font(.I_char(glyph_char),.I_row(glyph_row),.O_row_bits(diag_font_row));
    wire diag_pixel=diag_font_row[15-glyph_col];
    reg base_vs,base_hs,base_de,logo_hit2;reg [23:0] base_rgb;
    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            vs_d<=0; de_d<=0; x<=0; y<=0;
            O_vs<=0; O_hs<=0; O_de<=0; O_rgb<=0;
            base_vs<=0;base_hs<=0;base_de<=0;logo_hit2<=0;base_rgb<=0;
            boot_counts<=0;run_counts<=0;fault_snapshot<=0;running<=0;error_addresses<=0;
            readback_status<=0;saturation_status<=0;view_status<=0;face_status<=0;expression_status<=0;expression_diagnostic<=0;saturation_bcd<=0;
            glyph_char<=0;glyph_row<=0;glyph_col<=0;glyph_color<=0;
            pixel_rgb<=0;pixel_logo<=0;pixel_fault_color<=0;
            pixel_vs<=0;pixel_hs<=0;pixel_de<=0;
            pixel_face_border<=0;pixel_preview_hit<=0;pixel_logo_hit<=0;pixel_text_hit<=0;pixel_fault_hit<=0;pixel_diag_hit<=0;
        end else begin
            vs_d<=I_vs; de_d<=I_de;
            if (I_vs && !vs_d) begin
                x<=0;y<=0;boot_counts<=I_boot_counts;run_counts<=I_run_counts;
                fault_snapshot<=I_fault;running<=I_running;
                error_addresses<=I_error_addresses;
                readback_status<=I_readback_status;saturation_status<=I_saturation_status;view_status<=I_view_status;face_status<=I_face_status;expression_status<=I_expression_status;expression_diagnostic<=I_expression_diagnostic;
                saturation_bcd<=sat_decimal(I_saturation_status[6:0]);
            end
            else begin
                if (I_de) x<=px+1'b1; else x<=0;
                if (!I_de && de_d) y<=y+1'b1;
            end
            // Stage 1: select glyph and save pixel position/attributes.
            glyph_char<=expression_debug_area?expression_debug_char:(expression_area?expression_char:(face_label?face_char:diag_char));
            glyph_row<=expression_debug_area?debug_dy[3:0]:(expression_area?y[3:0]-4'd8:(face_label?face_dy[3:0]:dy[4:1]));
            glyph_col<=expression_debug_area?debug_dx[3:0]:(expression_area?ex[3:0]:(face_label?face_dx[3:0]:dx[4:1]));
            glyph_color<=expression_debug_area?24'h80ffff:(expression_area?24'hffff80:(face_label?24'h20ff20:diag_color));
            pixel_vs<=I_vs;pixel_hs<=I_hs;pixel_de<=I_de;pixel_rgb<=I_rgb;
            pixel_logo_hit<=logo_area;
            pixel_preview_hit<=preview_area;pixel_face_border<=face_border && !expression_debug_area && !preview_area;pixel_text_hit<=text_pixel;pixel_diag_hit<=diag_area || face_label || expression_area || expression_debug_area;
            pixel_fault_hit<=px>=704 && px<720 && y>=112 && y<240 && ((y-112)&31)<16;
            pixel_fault_color<=fault_snapshot[3-((y-112)>>5)]?24'hff2020:24'h20ff20;
            // Stage 2: render registered glyph. Sync and RGB have equal latency.
            base_vs<=pixel_vs;base_hs<=pixel_hs;base_de<=pixel_de;logo_hit2<=pixel_logo_hit;
            O_vs<=base_vs;O_hs<=base_hs;O_de<=base_de;
            O_rgb<=!base_de?24'd0:(logo_hit2 && logo_pixel[24]?logo_pixel[23:0]:base_rgb);
            if(!pixel_de)base_rgb<=0;
            else if(pixel_text_hit)base_rgb<=24'hffff00;
            else if(pixel_preview_hit)base_rgb<={3{I_preview_gray}};
            else if(pixel_face_border)base_rgb<=24'h20ff20;
            else if(pixel_fault_hit)base_rgb<=pixel_fault_color;
            else if(pixel_diag_hit)base_rgb<=diag_pixel?glyph_color:24'h101010;
            else base_rgb<=pixel_rgb;
        end
    end
endmodule
