`timescale 1ns/1ps
module tb_face_overlay;
    reg clk=0,rst=0,vs=0,de=0;always #5 clk=~clk;
    reg [31:0] status=0;reg [31:0] expression=0;wire ov,oh,od;wire [23:0] rgb;
    basic_osd #(.ENABLE_CONFUSED_UI(1),.COMPACT_DEBUG(0)) dut(clk,rst,vs,1'b0,de,24'h123456,4'd0,64'd0,64'd0,1'b1,32'd0,71'd0,8'd64,ov,oh,od,rgb,2'd0,status,expression,168'd0,8'd0,1'b0,8'd0,);
    integer x,y,pass;reg [23:0] expected;reg check=0;
    task tick(input bit v,input bit d);begin @(negedge clk);vs=v;de=d;end endtask
    initial begin
        repeat(3)@(negedge clk);rst=1;
        for(pass=0;pass<2;pass=pass+1)begin
            status=pass==0?{1'b1,1'b0,8'd30,7'd20,7'd30,8'd9}:32'd0;
            tick(1,0);tick(0,0);
            for(y=0;y<420;y=y+1)begin
                for(x=0;x<640;x=x+1)begin
                    tick(0,1);@(posedge clk);#1;
                    // Match the DUT's two-stage pipeline with one extra sampled edge.
                    if(x>2 && y>=160 && y<=399)begin
                        if(pass==0 && (x-2==240 || x-2==479 || ((y==160 || y==399) && x-2>=240 && x-2<=479)))begin
                            if(rgb!==24'h20ff20)$fatal(1,"face border missing %0d %0d",x-2,y);
                        end
                        if(x-2==300 && y==200 && rgb!==24'h123456)$fatal(1,"face interior or compact-view background overwritten");
                        if(pass==1 && x-2==240 && y==200 && rgb!==24'h123456)$fatal(1,"stale face remains after next-frame clear");
                    end
                    if(pass==0 && x==500 && y==250)status=0; // must hold until next VS
                end
                tick(0,0);tick(0,0);
            end
        end
        // Isolate new header characters after full streamed border/snapshot checks.
        force dut.x=11'd832;force dut.y=11'd32;force dut.de_d=1'b1;de=1;
        force dut.face_status=32'h80000000;#1;if(dut.character!="H")$fatal(1,"coasting header missing H");
        force dut.face_status=32'hc0000000;#1;if(dut.character!="M")$fatal(1,"visual support header missing M");
        force dut.face_status=32'h40000000;#1;if(dut.character!="T")$fatal(1,"invisible timeout header missing T");
        force dut.face_status=32'd0;#1;if(dut.character!=" ")$fatal(1,"cleared header left stale H");
        force dut.x=11'd352;#1;if(dut.character!="3")$fatal(1,"V21 CT220 version header");
        force dut.x=11'd384;#1;if(dut.character!="0")$fatal(1,"V21-based CT250 tens digit");
        force dut.face_status=32'h80000089;force dut.x=11'd832;#1;if(dut.character!="P")$fatal(1,"profile header");
        force dut.x=11'd16;force dut.y=11'd680;force dut.expression_status=2'd1;
        #1;if(!dut.expression_area || dut.expression_text!="EXPR HAPPY  " || dut.expression_char!="E")$fatal(1,"happy text");
        force dut.x=11'd80;#1;if(dut.expression_char!=" ")$fatal(1,"text position");
        force dut.expression_status=2'd2;#1;if(dut.expression_text!="EXPR NEUTRAL")$fatal(1,"neutral text");
        force dut.expression_status=2'd3;#1;if(dut.expression_text!="EXPR NERVOUS")$fatal(1,"nervous text");
        force dut.expression_status=2'd0;#1;if(dut.expression_text!="            " || dut.expression_area)$fatal(1,"invalid expression must be hidden");
        force dut.face_status=0;#1;if(dut.expression_area)$fatal(1,"no face label");
        release dut.x;release dut.y;release dut.de_d;release dut.face_status;release dut.expression_status;de=0;
        $display("PASS FACE OVERLAY: coordinate x8 scaling, 2-pixel green border, interior preserved in compact full-color view, frame snapshot, next-frame clear, V5 H/T header priority");$finish;
    end
endmodule

