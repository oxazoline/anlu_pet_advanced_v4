// Four RGB96 beats (16 RGB888 pixels) become three 128-bit DDR words.
// Gaps preserve partial data. SOF resets grouping and is forwarded in blanking
// to retain the inherited video_in frame-reset lead time.
module basic_rgb_packer (
    input wire I_clk, input wire I_rst_n,
    input wire I_96b_frame_start, input wire I_96b_valid,
    input wire [95:0] I_96b_data,
    output reg O_128b_frame_start, output reg O_128b_valid,
    output reg [127:0] O_128b_data
);
    reg [1:0] phase;
    reg [95:0] previous;
    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            phase<=0; previous<=0; O_128b_frame_start<=0;
            O_128b_valid<=0; O_128b_data<=0;
        end else begin
            O_128b_frame_start<=I_96b_frame_start;
            O_128b_valid<=0;
            if (I_96b_frame_start) begin phase<=0; previous<=0; end
            if (I_96b_valid) begin
                previous<=I_96b_data;
                if (I_96b_frame_start) phase<=1;
                else begin
                    phase<=phase+1'b1;
                    case (phase)
                        0: O_128b_valid<=0;
                        1: begin O_128b_valid<=1; O_128b_data<={previous,I_96b_data[95:64]}; end
                        2: begin O_128b_valid<=1; O_128b_data<={previous[63:0],I_96b_data[95:32]}; end
                        3: begin O_128b_valid<=1; O_128b_data<={previous[31:0],I_96b_data}; end
                    endcase
                end
            end
        end
    end
endmodule
