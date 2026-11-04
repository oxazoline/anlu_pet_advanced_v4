// Millisecond timer. Gray code crosses into CSI and pixel domains.
// Frame timestamp/id/mode bind to the physical four-slot DDR ring.
// Valid publication requires the expected accepted write-word count.
module adv_frame_latency #(parameter integer TICKS_PER_MS=50000,WORDS_PER_FRAME=172800)(
 input wire I_ref_clk,I_cam_clk,I_ddr_clk,I_pixel_clk,I_rst_n,
 input wire I_capture_sof,I_processed_sof,input wire [1:0] I_mode,
 input wire I_slot_start,input wire [1:0] I_write_slot,input wire I_write_accepted,
 input wire I_select,input wire [1:0] I_read_slot,input wire I_vs,I_de,
 output reg [63:0] O_metrics,output wire [15:0] O_capture_id);
 reg [15:0] divider;reg [23:0] ms,gray_ms;
 always @(posedge I_ref_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin divider<=0;ms<=0;gray_ms<=0;end
  else if(divider==TICKS_PER_MS-1)begin divider<=0;ms<=ms+1'b1;gray_ms<=((ms+24'd1)>>1)^(ms+24'd1);end
  else divider<=divider+1'b1;
 end
 function [23:0] binary_time;input [23:0] g;integer k;begin binary_time[23]=g[23];
 for(k=22;k>=0;k=k-1)binary_time[k]=binary_time[k+1]^g[k];end endfunction
 (* ASYNC_REG="TRUE" *) reg [23:0] cam_time_meta,cam_time_sync,pixel_time_meta,pixel_time_sync;
 reg [23:0] captured_ms;reg [15:0] capture_id;reg [41:0] source_meta;
 assign O_capture_id=capture_id;
 always @(posedge I_cam_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin cam_time_meta<=0;cam_time_sync<=0;captured_ms<=0;capture_id<=0;source_meta<=0;end
  else begin
   cam_time_meta<=gray_ms;cam_time_sync<=cam_time_meta;
   if(I_capture_sof)begin captured_ms<=binary_time(cam_time_sync);capture_id<=capture_id+1'b1;end
   if(I_processed_sof)source_meta<={captured_ms,capture_id,I_mode};
  end
 end
 // The slot event is registered one cycle after the existing three-stage SOF CDC.
 // Source data is held a whole camera frame; two data stages settle before use.
 (* ASYNC_REG="TRUE" *) reg [41:0] tag_meta,tag_sync;
 (* ram_style="dram" *) reg [41:0] slot_meta[0:3];reg [3:0] slot_valid;reg [1:0] active_slot;reg [17:0] writes;
 reg [42:0] selected_meta;
 always @(posedge I_ddr_clk)if(I_rst_n && I_slot_start)slot_meta[I_write_slot]<=tag_sync;
 integer n;
 always @(posedge I_ddr_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin tag_meta<=0;tag_sync<=0;slot_valid<=0;active_slot<=0;writes<=0;selected_meta<=0;

  end else begin
   tag_meta<=source_meta;tag_sync<=tag_meta;
   if(I_slot_start)begin active_slot<=I_write_slot;slot_valid[I_write_slot]<=0;writes<=0;end
   else if(I_write_accepted && writes<WORDS_PER_FRAME)begin
    writes<=writes+1'b1;if(writes==WORDS_PER_FRAME-1)slot_valid[active_slot]<=1;
   end
   if(I_select)selected_meta<={slot_valid[I_read_slot],slot_meta[I_read_slot]};
  end
 end
 (* ASYNC_REG="TRUE" *) reg [42:0] display_meta,display_sync;
 reg vs_d,await_pixel,seen;reg [15:0] last_id,max_delay;reg [5:0] repeats,drops;
 wire [23:0] now_ms=binary_time(pixel_time_sync);
 wire [23:0] delay_ms=now_ms-display_sync[41:18];
 wire [15:0] display_id=display_sync[17:2];
 wire repeated=seen && display_id==last_id;
 wire [15:0] id_gap=display_id-last_id;
 wire [15:0] bounded_delay=|delay_ms[23:16]?16'hffff:delay_ms[15:0];
 always @(posedge I_pixel_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin pixel_time_meta<=0;pixel_time_sync<=0;display_meta<=0;display_sync<=0;
   vs_d<=0;await_pixel<=1;seen<=0;last_id<=0;max_delay<=0;repeats<=0;drops<=0;O_metrics<=0;
  end else begin
   pixel_time_meta<=gray_ms;pixel_time_sync<=pixel_time_meta;
   display_meta<=selected_meta;display_sync<=display_meta;vs_d<=I_vs;
   if(I_vs && !vs_d)await_pixel<=1;
   if(I_de && await_pixel)begin
    await_pixel<=0;
    if(display_sync[42])begin
     O_metrics<={1'b1,repeated,display_sync[1:0],bounded_delay,max_delay,display_id,repeats,drops};
     if(repeated)begin if(repeats!=63)repeats<=repeats+1'b1;end
     else begin
      if(bounded_delay>max_delay)max_delay<=bounded_delay;
      if(seen && id_gap>1)begin if(id_gap>63 || {1'b0,drops}+id_gap-1>63)drops<=63;else drops<=drops+id_gap-1'b1;end
     end
     last_id<=display_id;seen<=1;
    end else O_metrics<=0;
   end
  end
 end
endmodule
