`timescale 1ns/1ps
module tb_video_timing;
    reg clk=0;always #5 clk=~clk;
    reg rst=0,armed=0;
    wire vs,hs,de,user,last,read_en,mvs,mhs,mde,ovs,ohs,ode;
    wire [23:0] mrgb,orgb;
    uivtc #(.H_ActiveSize(1280),.H_FrameSize(1650),.H_SyncStart(1390),.H_SyncEnd(1430),
            .V_ActiveSize(720),.V_FrameSize(750),.V_SyncStart(725),.V_SyncEnd(730))
        vtc(.I_vtc_clk(clk),.I_vtc_rstn(rst),.O_vtc_vs(vs),.O_vtc_hs(hs),
            .O_vtc_de_valid(de),.O_vtc_user(user),.O_vtc_last(last));
    always @(posedge clk or negedge rst)
        if(!rst)armed<=0;else if(vs)armed<=1;
    hdmi_mixer #(.H_OFFSET(0),.V_OFFSET(0),.IMG_WIDTH(1280),.IMG_HEIGHT(720))
        mixer(clk,rst,vs,hs,de && armed,user,last,4'd0,read_en,24'h123456,mvs,mhs,mde,mrgb);
    basic_osd #(.ENABLE_CONFUSED_UI(1),.COMPACT_DEBUG(0)) osd(clk,rst,mvs,mhs,mde,mrgb,4'd0,64'd0,64'd0,1'b1,32'd0,71'd0,8'd0,ovs,ohs,ode,orgb,2'd2,32'd0,32'd0,168'd0,8'd0,1'b0,8'd0,);
    integer pixels=0,lines=0,width=0,frames=0,cycles=0,last_frame_cycle=0;
    reg old_vs=0,old_de=0;
    always @(posedge clk) begin
        #1;
        if(rst)begin
            cycles=cycles+1;
            if(read_en && !armed)$fatal(1,"read issued in initial partial frame");
            if(ode)begin pixels=pixels+1;width=width+1;end
            if(!ode && old_de)begin
                if(width!=1280)$fatal(1,"line width %0d",width);
                width=0;lines=lines+1;
            end
            if(ovs && !old_vs)begin
                if(frames>0)begin
                    if(pixels!=921600 || lines!=720)$fatal(1,"timing pixels=%0d lines=%0d",pixels,lines);
                    if(cycles-last_frame_cycle!=1237500)$fatal(1,"incorrect total frame cycles");
                    $display("PASS TIMING: VTC/mixer/OSD integrated, 1280x720 active, 1650x750 total, initial prefetch guard");
                    $finish;
                end
                frames=frames+1;pixels=0;lines=0;last_frame_cycle=cycles;
            end
            old_vs=ovs;old_de=ode;
        end
    end
    initial begin repeat(5)@(negedge clk);rst=1;end
    initial begin #60000000;$fatal(1,"timing timeout");end
endmodule
