// Closed-loop SC520 exposure. Same verified grouped I2C interface as ae_set.
// K1/K2: target brightness in AUTO, exposure in MANUAL. K1+K2 toggles mode.
module adv_auto_exposure #(
 parameter integer V4_MODE=0,CLK_HZ=23809524,DEBOUNCE_CYCLES=CLK_HZ/100,REPEAT_CYCLES=CLK_HZ/8,
 parameter [15:0] INITIAL_EXPOSURE=16'd1996,GAIN_CONTROL=16'd144,
 parameter [7:0] INITIAL_TARGET=8'd152,parameter integer SETTLE_FRAMES=4
)(input wire I_clk,I_rst,input wire [3:0] I_btn,input wire I_ae_cfg_done,I_cam_cfg_done,
 output reg O_ae_req,output reg [15:0] O_ae,output wire [15:0] O_ag,
 input wire [31:0] I_meter,output wire [31:0] O_status);
 localparam [15:0] AE_MIN=16'd4,AE_MAX=16'd3991;
 reg [1:0] btn_meta,btn_sync,btn_stable,previous_action;
 reg [31:0] debounce_count,repeat_count;
 reg [15:0] target_ae;reg [7:0] target_y;
 reg initial_write_pending;reg [1:0] write_state;
 reg auto_mode,combo_hold,seen_meter,last_highlight;
 reg [7:0] last_seq,last_y;reg [25:0] meter_age;reg [2:0] settle_count;
 reg [1:0] vote_direction;reg vote;
 wire [1:0] action=btn_stable==2'b01 ? 2'd1:btn_stable==2'b10 ? 2'd2:btn_stable==2'b11 ? 2'd3:2'd0;
 wire step_event=!combo_hold && action!=0 && (action!=previous_action || (action!=3 && repeat_count==REPEAT_CYCLES-1));
 wire [15:0] manual_step=target_ae<16 ? 16'd4:target_ae>>2;
 wire fresh=I_meter[7] && (!seen_meter || I_meter[31:24]!=last_seq);
 wire [8:0] mean_sum={1'b0,I_meter[23:16]}+{1'b0,I_meter[15:8]}+9'd1;
 wire [7:0] measured_y=I_meter[6] ? (I_meter[5] ? I_meter[15:8]:I_meter[23:16]):mean_sum[8:1];
 wire [7:0] lower_y=target_y-(V4_MODE?8'd16:8'd24),upper_y=target_y+(V4_MODE?8'd16:8'd24);
 wire clip_down=I_meter[4] && (!V4_MODE || !I_meter[6] || measured_y>target_y);
 wire clip_up_block=I_meter[3] && (!V4_MODE || !I_meter[6]);
 wire [1:0] direction=clip_down || measured_y>upper_y ? 2'd2:(measured_y<lower_y && !clip_up_block) ? 2'd1:2'd0;
 wire very_far=I_meter[4] || {1'b0,measured_y}+9'd48<{1'b0,target_y} || {1'b0,measured_y}>{1'b0,target_y}+9'd48;
 wire [15:0] auto_step0=V4_MODE ? (very_far ? (target_ae>>1) : (target_ae>>3)) : (very_far ? (target_ae>>3):(target_ae>>4));
 wire [15:0] auto_step=auto_step0<4 ? 16'd4:auto_step0;
 wire write_finished=write_state==2 && I_ae_cfg_done;
 assign O_ag=GAIN_CONTROL;
 assign O_status={auto_mode,(seen_meter && meter_age<CLK_HZ),(write_state!=0 || settle_count!=0 || initial_write_pending),last_highlight,target_y,last_y,O_ae[11:0]};
 always @(posedge I_clk or posedge I_rst)begin
 if(I_rst)begin
 btn_meta<=0;btn_sync<=0;btn_stable<=0;previous_action<=0;debounce_count<=0;repeat_count<=0;
 target_ae<=INITIAL_EXPOSURE;target_y<=INITIAL_TARGET;auto_mode<=1;combo_hold<=0;seen_meter<=0;last_seq<=0;last_y<=0;last_highlight<=0;meter_age<=CLK_HZ;
 settle_count<=V4_MODE ? 2 : SETTLE_FRAMES;vote_direction<=0;vote<=0;
 end else begin
 btn_meta<=~I_btn[1:0];btn_sync<=btn_meta;
 if(btn_sync==btn_stable)debounce_count<=0;
 else if(debounce_count==DEBOUNCE_CYCLES-1)begin btn_stable<=btn_sync;debounce_count<=0;end else debounce_count<=debounce_count+1'b1;
 previous_action<=action;
 if(action==0 || action!=previous_action || step_event)repeat_count<=0;else if(repeat_count<REPEAT_CYCLES-1)repeat_count<=repeat_count+1'b1;
 if(action==0)combo_hold<=0;
 if(meter_age<CLK_HZ)meter_age<=meter_age+1'b1;
 if(fresh)begin seen_meter<=1;last_seq<=I_meter[31:24];last_y<=measured_y;last_highlight<=I_meter[4];meter_age<=0;end
 if(write_finished)begin settle_count<=V4_MODE ? 2 : SETTLE_FRAMES;vote_direction<=0;vote<=0;end
 else if(fresh && settle_count!=0)settle_count<=settle_count-1'b1;
 if(step_event)begin
 vote_direction<=0;vote<=0;
 if(action==3)begin auto_mode<=!auto_mode;combo_hold<=1;settle_count<=V4_MODE ? 2 : SETTLE_FRAMES;end
 else if(auto_mode)begin
 if(action==1)target_y<=target_y<=88 ? 8'd80:target_y-8'd8;
 else target_y<=target_y>=200 ? 8'd208:target_y+8'd8;
 end else if(action==1)target_ae<=target_ae<=AE_MIN+manual_step ? AE_MIN:target_ae-manual_step;
 else target_ae<=target_ae+manual_step>=AE_MAX ? AE_MAX:target_ae+manual_step;
 end else if(fresh && auto_mode && write_state==0 && I_ae_cfg_done && I_cam_cfg_done && !initial_write_pending && settle_count==0)begin
 if(direction==0)begin vote<=0;vote_direction<=0;end
 else if(direction!=vote_direction && !(V4_MODE && very_far))begin vote<=1;vote_direction<=direction;end
 else if(vote || (V4_MODE && very_far))begin
 if(direction==1)target_ae<=target_ae+auto_step>=AE_MAX ? AE_MAX:target_ae+auto_step;
 else target_ae<=target_ae<=AE_MIN+auto_step ? AE_MIN:target_ae-auto_step;
 vote<=0;vote_direction<=0;
 end else vote<=1;
 end
 end end
 // Exposure and gain remain stable for the entire grouped write/readback.
 always @(posedge I_clk or posedge I_rst)begin
 if(I_rst)begin O_ae<=INITIAL_EXPOSURE;O_ae_req<=0;initial_write_pending<=1;write_state<=0;end
 else begin O_ae_req<=0;case(write_state)
 0:if(I_cam_cfg_done && I_ae_cfg_done && (initial_write_pending || target_ae!=O_ae))begin O_ae<=target_ae;O_ae_req<=1;initial_write_pending<=0;write_state<=1;end
 1:if(!I_ae_cfg_done)write_state<=2;
 2:if(I_ae_cfg_done)write_state<=0;
 default:write_state<=0;
 endcase end end
endmodule
