// Cross only registered, monotonic readiness bits between unrelated clocks.
// Three source SOFs guarantee at least two frames have had time to complete.
module basic_display_startup (
    input wire I_camera_clk, input wire I_pixel_clk, input wire I_rst_n,
    input wire I_sof, input wire I_ddr_ready,
    output wire O_display_rst_n
);
    reg [1:0] frames;
    reg camera_ready;
    always @(posedge I_camera_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin frames<=0; camera_ready<=0; end
        else if (I_sof && !camera_ready) begin
            if (frames==2) camera_ready<=1;
            else frames<=frames+1'b1;
        end
    end
    (* ASYNC_REG="TRUE" *) reg camera_meta, camera_sync, ddr_meta, ddr_sync;
    reg [2:0] release_pipe;
    always @(posedge I_pixel_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin camera_meta<=0; camera_sync<=0; ddr_meta<=0; ddr_sync<=0; release_pipe<=0; end
        else begin
            camera_meta<=camera_ready; camera_sync<=camera_meta;
            ddr_meta<=I_ddr_ready; ddr_sync<=ddr_meta;
            release_pipe<={release_pipe[1:0],camera_sync && ddr_sync};
        end
    end
    assign O_display_rst_n=release_pipe[2];
endmodule
