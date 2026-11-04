`timescale 1ns/1ps
module tb_fault_events;
    reg px=0,ddr=0,rst=0,de=0,rdvalid=0,camvalid=0;
    always #5 px=~px;always #7 ddr=~ddr;
    wire under,over,ue,oe,win,wie;
    video_out out_dut(.I_rst_n(rst),.I_ddr_clk(ddr),.I_dsi_clk(px),
        .I_video_in_wr_busy(1'b1),.I_video_out_rp(2'd0),.I_ddr_user_ready(1'b0),
        .I_ddr_user_rd_valid(rdvalid),.I_ddr_user_rd_data(128'd0),
        .I_video_vsync(1'b0),.I_video_rd_en(de),
        .O_fifo_underflow(under),.O_fifo_overflow(over),
        .O_fifo_underflow_event(ue),.O_fifo_overflow_event(oe));
    video_in in_dut(.I_rst_n(rst),.I_camera_clk(px),.I_camera_frame_start(1'b0),
        .I_camera_valid(camvalid),.I_camera_data(128'd0),.I_mipi_rx_error(1'b0),
        .I_ddr_clk(ddr),.I_display_pause(1'b0),.I_video_out_rd_busy(1'b1),
        .I_ddr_user_ready(1'b0),.O_fifo_overflow(win),.O_fifo_overflow_event(wie));
    initial begin
        force out_dut.S_fifo_emtpy=1;
        force out_dut.S_fifo_full=1;
        force in_dut.S_fifo_full=1;
        force in_dut.S_fifo_rst=0;
        repeat(5)@(negedge px);rst=1;
        repeat(5)@(negedge px);
        if(under||over||win||oe||wie)$fatal(1,"flag without transfer");
        camvalid=1;rdvalid=1;de=1;
        repeat(18)@(negedge px);
        if(!under||!over||!win)$fatal(1,"failed transfers must latch each diagnostic");
        camvalid=0;rdvalid=0;de=0;repeat(5)@(negedge px);
        if(!under||!over||!win||ue||oe||wie)$fatal(1,"events should stop, history must persist");
        rst=0;repeat(4)@(negedge px);
        if(under||over||win)$fatal(1,"history reset");
        rst=1;repeat(5)@(negedge px);
        force out_dut.S_fifo_rst=1;force in_dut.S_fifo_rst=1;
        repeat(4)@(negedge px);camvalid=1;rdvalid=1;de=1;
        repeat(8)@(negedge px);
        if(under||over||win||ue||oe||wie)$fatal(1,"FIFO reset must not create spurious fault events");
        $display("PASS FIFO EVENTS: real video_in/out transfer qualification, sticky history/reset, reset suppression");$finish;
    end
    initial begin #10000;$fatal(1,"timeout");end
endmodule
