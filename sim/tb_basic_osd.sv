`timescale 1ns/1ps
module tb_basic_osd;
    reg clk=0; always #5 clk=~clk;
    reg rst=0,vs=0,hs=0,de=0;
    reg [23:0] rgb=24'h123456;
    reg [3:0] faults=0; reg [63:0] boot_counts=0,run_counts=0;
    reg [7:0] sat_status=0;
    wire ovs,ohs,ode;wire [23:0] out_rgb;
    wire actual_vs,actual_hs,actual_de;wire [23:0] actual_rgb;
    reg [26:0] reference_delay=0,reference_delay2=0;
    always @(posedge clk)begin
        if(!rst)begin reference_delay<=0;reference_delay2<=0;end
        else begin reference_delay<={ovs,ohs,ode,out_rgb};reference_delay2<=reference_delay;end
        #1;
        if(rst && {actual_vs,actual_hs,actual_de,actual_rgb}!==reference_delay2)
            $fatal(1,"retimed OSD differs from previous renderer or sync/RGB latency mismatch");
    end
    basic_osd #(.ENABLE_CONFUSED_UI(1),.COMPACT_DEBUG(0)) dut(clk,rst,vs,hs,de,rgb,faults,boot_counts,run_counts,1'b1,32'h38123e09,{1'b1,6'd0,48'h00f9700f0080,16'd3991},sat_status,actual_vs,actual_hs,actual_de,actual_rgb,2'd2,32'd0,32'd0,168'd0,8'd0,1'b0,8'd0,);
    osd_v6_unpipelined_reference reference(clk,rst,vs,hs,de,rgb,faults,boot_counts,run_counts,1'b1,32'h38123e09,{1'b1,6'd0,48'h00f9700f0080,16'd3991},sat_status,ovs,ohs,ode,out_rgb,2'd2,32'd0);
    integer lut_index,pct,bcd;
    integer x,y,count=0,logo_hits=0,text_hits=0,fd;
    task pixel(input bit v,input bit h,input bit d,input [23:0] color);
        begin
            @(negedge clk); vs=v; hs=h; de=d; rgb=color;
            @(posedge clk);#1;
            if(ovs!==v || ohs!==h || ode!==d) $fatal(1,"OSD sync latency mismatch");
        end
    endtask
    initial begin
        for(lut_index=0;lut_index<=96;lut_index=lut_index+1)begin
            pct=lut_index*100/64;bcd=(pct/100)*256+((pct/10)%10)*16+pct%10;
            if(dut.sat_decimal(lut_index[6:0])!==bcd[15:0])$fatal(1,"SAT table mismatch");
        end
        fd=$fopen("osd_preview.ppm","w");$fwrite(fd,"P3\n1280 720\n255\n");
        repeat(4) @(negedge clk);rst=1;
        pixel(1,0,0,0);pixel(0,0,0,0);
        for(y=0;y<720;y=y+1) begin
            for(x=0;x<1280;x=x+1) begin
                pixel(0,0,1,24'h123456);count=count+1;
                if(x>=16 && x<176 && y>=16 && y<176 && out_rgb!=24'h123456) logo_hits=logo_hits+1;
                if(x>=192 && x<864 && y>=32 && y<64 && out_rgb==24'hffff00) text_hits=text_hits+1;
                if(!(x>=16 && x<176 && y>=16 && y<176) &&
                   !(x>=192 && x<864 && y>=32 && y<64) &&
                   !(x>=192 && x<672 && y>=80 && y<400) && !(x>=704 && x<720 && y>=112 && y<400) && out_rgb!==24'h123456)
                    $fatal(1,"background modified at %0d,%0d",x,y);
                if(x==704 && y==112 && out_rgb!==24'h20ff20) $fatal(1,"healthy status color mismatch");
                $fwrite(fd,"%0d %0d %0d\n",out_rgb[23:16],out_rgb[15:8],out_rgb[7:0]);
            end
            pixel(0,1,0,0);pixel(0,0,0,0);
        end
        $fclose(fd);
        if(count!=921600 || logo_hits<100 || text_hits<100) $fatal(1,"missing logo/text");
        faults=4'b1000;boot_counts=64'h0001000200030004;run_counts=64'h0005000600070008; pixel(1,0,0,0);pixel(0,0,0,0);
        for(y=0;y<=239;y=y+1) begin
            for(x=0;x<1280;x=x+1) begin
                pixel(0,0,1,24'h123456);
                if(x==704 && y==112 && out_rgb!==24'hff2020) $fatal(1,"fault status color mismatch");
            end
            pixel(0,0,0,0);
        end
        if(dut.boot_counts!==64'h0001000200030004 || dut.run_counts!==64'h0005000600070008)
            $fatal(1,"counter snapshot mismatch");
        // SAT percentage endpoints and display-frame snapshot.
        sat_status=64;pixel(1,0,0,0);pixel(0,0,0,0);
        for(y=0;y<368;y=y+1)begin pixel(0,0,1,0);pixel(0,0,0,0);end
        pixel(0,0,1,0);
        if(dut.boot_word!==16'h0100 || dut.run_word!==0)$fatal(1,"SAT 100 percent display");
        sat_status=96;pixel(0,0,1,0);
        if(dut.boot_word!==16'h0100)$fatal(1,"SAT changed inside display frame");
        pixel(1,0,0,0);pixel(0,0,0,0);
        for(y=0;y<368;y=y+1)begin pixel(0,0,1,0);pixel(0,0,0,0);end
        pixel(0,0,1,0);
        if(dut.boot_word!==16'h0150)$fatal(1,"SAT 150 percent display");
        sat_status=8'h80;pixel(1,0,0,0);pixel(0,0,0,0);
        for(y=0;y<368;y=y+1)begin pixel(0,0,1,0);pixel(0,0,0,0);end
        pixel(0,0,1,0);
        if(dut.boot_word!==0 || dut.run_word!==1)$fatal(1,"SAT gray and alignment fault display");
        $display("PASS OSD: full 1280x720 frame, logo/text/background/sync/status, SAT 0/100/150 percent and frame snapshot, all 97 LUT entries, full-stream equivalence with one additional clock verified");
        $finish;
    end
    initial begin #30000000;$fatal(1,"timeout");end
endmodule

// Independent unpipelined renderer; V5 header/mode text updated intentionally.
// Logo/font data reused from lab_ex3; independent one-cycle display overlay.
module osd_v6_unpipelined_reference (
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
    input wire [31:0] I_face_status
);
    reg vs_d, de_d;
    reg [10:0] x, y;
    wire [10:0] px=I_de && !de_d ? 11'd0 : x;
    wire logo_area=px>=16 && px<176 && y>=16 && y<176;
    wire [10:0] lx=px-11'd16, ly=y-11'd16;
    wire [14:0] logo_addr=({4'd0,ly}<<7)+({4'd0,ly}<<5)+lx;
    wire [24:0] logo_pixel;
    anlogic_logo_rom u_logo(.I_addr(logo_addr),.O_pixel(logo_pixel));
    wire text_area=px>=192 && px<864 && y>=32 && y<64;
    wire [10:0] tx=px-11'd192, ty=y-11'd32;
    reg [31:0] face_status;
    reg [1:0] view_status;
    reg [7:0] character;
    always @(*) begin
        case(tx[9:5])
            0: character=8'h80; 1: character=8'h81;
            3: character="C"; 4: character="T"; 5: character="3"; 6: character="0"; 7: character="0"+view_status;
            8: character="1"; 9: character="2"; 10: character="8"; 11: character="0";
            12: character="X"; 13: character="7"; 14: character="2"; 15: character="0";
            18:character="F";19:character=face_status[31]?"1":"0";20:character=face_status[30]?"T":(face_status[31] && face_status[7:0]==0?"H":" ");
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
    reg [7:0] percentage;
    reg [3:0] hundreds,tens,ones;
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
    always @(*) begin
        percentage=({8'd0,saturation_status[6:0]}*16'd25)>>4;
        hundreds=percentage/100;tens=(percentage/10)%10;ones=percentage%10;
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
            9:begin boot_word={4'd0,hundreds,tens,ones};run_word={15'd0,saturation_status[7]};end
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
    wire [15:0] diag_font_row;
    osd_char_lib u_diag_font(.I_char(diag_char),.I_row(dy[4:1]),.O_row_bits(diag_font_row));
    wire diag_pixel=diag_font_row[15-dx[4:1]];
    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            vs_d<=0; de_d<=0; x<=0; y<=0;
            O_vs<=0; O_hs<=0; O_de<=0; O_rgb<=0;
            boot_counts<=0;run_counts<=0;fault_snapshot<=0;running<=0;error_addresses<=0;
            readback_status<=0;saturation_status<=0;view_status<=0;face_status<=0;
        end else begin
            vs_d<=I_vs; de_d<=I_de;
            if (I_vs && !vs_d) begin
                x<=0;y<=0;boot_counts<=I_boot_counts;run_counts<=I_run_counts;
                fault_snapshot<=I_fault;running<=I_running;
                error_addresses<=I_error_addresses;
                readback_status<=I_readback_status;saturation_status<=I_saturation_status;view_status<=I_view_status;face_status<=I_face_status;
            end
            else begin
                if (I_de) x<=px+1'b1; else x<=0;
                if (!I_de && de_d) y<=y+1'b1;
            end
            O_vs<=I_vs; O_hs<=I_hs; O_de<=I_de;
            if (!I_de) O_rgb<=0;
            else if (logo_area && logo_pixel[24]) O_rgb<=logo_pixel[23:0];
            else if (text_pixel) O_rgb<=24'hffff00;
            // Preserve all-time sticky alarm as four independent small squares.
            else if (px>=704 && px<720 && y>=112 && y<240 && ((y-112)&31)<16)
                O_rgb<=fault_snapshot[3-((y-112)>>5)]?24'hff2020:24'h20ff20;
            else if (diag_area) O_rgb<=diag_pixel?diag_color:24'h101010;
            else O_rgb<=I_rgb;
        end
    end
endmodule
