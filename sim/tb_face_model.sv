`timescale 1ns/1ps
module tb_face_model;
    reg clk=0;always #5 clk=~clk;
    reg [8:0] fi=0;reg [11:0] si=0;reg [4:0] st=31;reg profile=0;
    wire [47:0] meta;wire [31:0] subset;wire [7:0] ending;wire signed [17:0] threshold;
    ext_face_feature_rom f(clk,fi,meta);ext_face_subset_rom s(clk,si,subset);ext_face_stage_rom t(st,ending,threshold,profile);
    reg [47:0] expected_meta[0:511];reg [31:0] expected_subset[0:4095];reg [25:0] expected_stage[0:63];integer n;
    initial begin
        $readmemh("face_meta.hex",expected_meta);$readmemh("face_subsets.hex",expected_subset);$readmemh("face_stages.hex",expected_stage);
        for(n=0;n<4096;n=n+1)begin
            @(negedge clk);fi=(n>=2048?256:0)+n%256;si=n;st=n%32;profile=n>=2048;@(posedge clk);#1;
            if(meta!==expected_meta[(n>=2048?256:0)+n%256] || subset!==expected_subset[n] || {ending,threshold}!==expected_stage[(n>=2048?32:0)+n%32])$fatal(1,"XML/RTL ROM mismatch %0d meta=%h/%h subset=%h/%h stage=%h/%h",n,meta,expected_meta[(n>=2048?256:0)+n%256],subset,expected_subset[n],{ending,threshold},expected_stage[(n>=2048?32:0)+n%32]);
        end
        $display("PASS FACE MODEL: all feature/leaf ROM words, 4096 banked category-subset words, frontal/profile stage endpoints and signed Q12 thresholds match independent XML decoding");$finish;
    end
endmodule
