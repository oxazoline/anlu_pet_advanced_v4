// SC520CS 30fps test: active-low K1 dims, K2 brightens.
// VTS=2000, safe exposure maximum=3991 half-line units.
module ae_set #(
 parameter integer CLK_HZ=24074074,
 parameter integer DEBOUNCE_CYCLES=CLK_HZ/100,
 parameter integer REPEAT_CYCLES=CLK_HZ/8,
 parameter [15:0] INITIAL_EXPOSURE=16'd3991,
 parameter [15:0] GAIN_CONTROL=16'd144
)(
 input wire I_clk,I_rst,
 input wire [3:0] I_btn,
 input wire I_ae_cfg_done,I_cam_cfg_done,
 output reg O_ae_req,
 output reg [15:0] O_ae,
 output wire [15:0] O_ag
);
 localparam [15:0] AE_MIN=16'd4,AE_MAX=16'd3991;
 reg [1:0] btn_meta,btn_sync,btn_stable,previous_action;
 reg [31:0] debounce_count,repeat_count;
 reg [15:0] target_ae;
 reg initial_write_pending;
 reg [1:0] write_state;
 wire [1:0] action=btn_stable==2'b01 ? 2'd1 : btn_stable==2'b10 ? 2'd2 : 2'd0;
 wire step_event=action!=0 && (action!=previous_action || repeat_count==REPEAT_CYCLES-1);
 wire [15:0] exposure_step=target_ae<16 ? 16'd4 : target_ae>>2;
 // Control 144 -> 3e09=0f (16x analog), 3e06=00, 3e07=80 (1x digital).
 // V1 control 160 was 16x analog * 1.5x digital = 24x total.
 assign O_ag=GAIN_CONTROL;
 always @(posedge I_clk or posedge I_rst) begin
  if(I_rst) begin
   btn_meta<=0;btn_sync<=0;btn_stable<=0;previous_action<=0;
   debounce_count<=0;repeat_count<=0;target_ae<=INITIAL_EXPOSURE;
  end else begin
   btn_meta<=~I_btn[1:0];btn_sync<=btn_meta;
   if(btn_sync==btn_stable) debounce_count<=0;
   else if(debounce_count==DEBOUNCE_CYCLES-1) begin
    btn_stable<=btn_sync;debounce_count<=0;
   end else debounce_count<=debounce_count+1;
   previous_action<=action;
   if(action==0 || action!=previous_action || step_event) repeat_count<=0;
   else repeat_count<=repeat_count+1;
   if(step_event && action==1)
    target_ae<=target_ae<=AE_MIN+exposure_step ? AE_MIN : target_ae-exposure_step;
   else if(step_event && action==2)
    target_ae<=target_ae+exposure_step>=AE_MAX ? AE_MAX : target_ae+exposure_step;
  end
 end
 // Keep exposure stable for the entire eight-register grouped I2C transaction.
 always @(posedge I_clk or posedge I_rst) begin
  if(I_rst) begin
   O_ae<=INITIAL_EXPOSURE;O_ae_req<=0;initial_write_pending<=1;write_state<=0;
  end else begin
   O_ae_req<=0;
   case(write_state)
    0: if(I_cam_cfg_done && I_ae_cfg_done && (initial_write_pending || target_ae!=O_ae)) begin
     O_ae<=target_ae;O_ae_req<=1;initial_write_pending<=0;write_state<=1;
    end
    1: if(!I_ae_cfg_done) write_state<=2;
    2: if(I_ae_cfg_done) write_state<=0;
    default:write_state<=0;
   endcase
  end
 end
endmodule
