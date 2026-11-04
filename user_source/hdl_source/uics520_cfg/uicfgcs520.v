`timescale 1ns / 1ps

module uicfgcs520 #(
    parameter integer CLK_DIV = 16'd239,
    parameter integer RESET_WAIT_CYCLES = 119048,
    parameter integer VERIFY_WAIT_CYCLES = 2380952
) (
    input  wire        I_clk,
    input  wire        I_rst_n,
    input  wire        I_ae_req,
    input  wire [15:0] I_ae,
    input  wire [15:0] I_ag,
    output wire        O_cam_scl,
    inout  wire        IO_cam_sda,
    output reg         O_cfg_done,
    output reg         O_ae_cfg_done,
    output reg  [15:0] O_sensor_id,
    output reg         O_sensor_id_ok,
    output reg         O_iic_error,
    output wire        O_iic_error_event,
    output reg [15:0]  O_first_error_addr,O_last_error_addr,
    output reg [47:0] O_readback,
    output reg [5:0] O_verify_mask,
    output reg O_verify_valid
);
    localparam [7:0] CAM_ID = 8'h6c;

    localparam [3:0] ST_IDH_REQ  = 4'd0;
    localparam [3:0] ST_IDH_BUSY = 4'd1;
    localparam [3:0] ST_IDH_DONE = 4'd2;
    localparam [3:0] ST_IDL_REQ  = 4'd3;
    localparam [3:0] ST_IDL_BUSY = 4'd4;
    localparam [3:0] ST_IDL_DONE = 4'd5;
    localparam [3:0] ST_CHECK_ID = 4'd6;
    localparam [3:0] ST_IDLE     = 4'd7;
    localparam [3:0] ST_WR_REQ   = 4'd8;
    localparam [3:0] ST_WR_BUSY  = 4'd9;
    localparam [3:0] ST_WR_DONE  = 4'd10;
    localparam [3:0] ST_ERROR    = 4'd11;
    localparam [3:0] ST_RESET_WAIT = 4'd12;
    localparam [4:0] ST_VERIFY_WAIT=13,ST_VERIFY_REQ=14,ST_VERIFY_BUSY=15,ST_VERIFY_DONE=16;

    reg  [4:0]  state;
    reg [2:0] verify_index;reg [1:0] verify_retries;
    // A startup group may not yet have latched. Retry the same held request,
    // never change the expected value or hide a persistent mismatch.
    reg [31:0] verify_wait_count;
    reg verify_transaction_error;
    reg         iic_req;
    reg         iic_mode;
    reg  [7:0]  wr_cnt;
    reg  [7:0]  rd_cnt;
    reg  [31:0] wr_data;
    reg  [8:0]  reg_index;
    reg  [16:0] reset_wait_cnt;
    reg         ae_table_active;
    wire        iic_busy;
    wire        iic_bus_error;
    (* ASYNC_REG="TRUE" *) reg bus_error_meta,bus_error_sync;
    reg bus_error_previous;
    reg first_error_seen;
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n)begin first_error_seen<=0;O_first_error_addr<=0;O_last_error_addr<=0;end
        else if(O_iic_error_event)begin
            O_last_error_addr<={wr_data[15:8],wr_data[23:16]};
            if(!first_error_seen)begin
                O_first_error_addr<={wr_data[15:8],wr_data[23:16]};first_error_seen<=1;
            end
        end
    end
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin bus_error_meta<=0;bus_error_sync<=0;bus_error_previous<=0;end
        else begin
            bus_error_meta<=iic_bus_error;bus_error_sync<=bus_error_meta;
            bus_error_previous<=bus_error_sync;
        end
    end
    assign O_iic_error_event=bus_error_sync && !bus_error_previous;
    wire [7:0]  rd_data;

    wire [23:0] init_reg_data;
    wire [8:0]  init_reg_size;
    wire [23:0] ae_reg_data;
    wire [8:0]  ae_reg_size;
    wire [23:0] gain_value;
    wire [23:0] selected_reg_data = ae_table_active ? ae_reg_data : init_reg_data;
    wire [8:0]  selected_reg_size = ae_table_active ? ae_reg_size : init_reg_size;
    reg [15:0] verify_address;
    reg [7:0] verify_expected;
    reg [7:0] verify_bits;
    wire verify_byte_failed=verify_transaction_error || ((rd_data & verify_bits)!=(verify_expected & verify_bits));
    always @(*)begin
        verify_bits=8'hff;
        case(verify_index)
            0:begin verify_address=16'h3e00;verify_expected={4'd0,I_ae[15:12]};end
            1:begin verify_address=16'h3e01;verify_expected=I_ae[11:4];end
            2:begin verify_address=16'h3e02;verify_expected={I_ae[3:0],4'd0};end
            3:begin verify_address=16'h3e09;verify_expected=gain_value[23:16];end
            4:begin verify_address=16'h3e06;verify_expected=gain_value[15:8];end
            default:begin verify_address=16'h3e07;verify_expected=gain_value[7:0];end
        endcase
        if(verify_index==0)verify_bits=8'h0f;
        if(verify_index==2)verify_bits=8'hf0;
        if(verify_index==3)verify_bits=8'h1f;
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            state            <= ST_IDH_REQ;
            iic_req          <= 1'b0;
            iic_mode         <= 1'b1;
            wr_cnt           <= 8'd3;
            rd_cnt           <= 8'd1;
            wr_data          <= 32'd0;
            reg_index        <= 9'd0;
            reset_wait_cnt   <= 17'd0;
            ae_table_active  <= 1'b0;
            O_cfg_done       <= 1'b0;
            O_ae_cfg_done    <= 1'b0;
            O_sensor_id      <= 16'd0;
            O_sensor_id_ok   <= 1'b0;
            O_iic_error      <= 1'b0;
            verify_index<=0;verify_retries<=0;verify_wait_count<=0;verify_transaction_error<=0;
            O_readback<=0;O_verify_mask<=0;O_verify_valid<=0;
        end else begin
            if(O_iic_error_event)verify_transaction_error<=1;
            if (iic_bus_error)
                O_iic_error <= 1'b1;

            case (state)
                ST_IDH_REQ: if (!iic_busy) begin
                    wr_data <= {8'h00, 8'h07, 8'h31, CAM_ID};
                    wr_cnt <= 8'd3;
                    rd_cnt <= 8'd1;
                    iic_mode <= 1'b1;
                    iic_req <= 1'b1;
                    state <= ST_IDH_BUSY;
                end
                ST_IDH_BUSY: if (iic_busy) begin
                    iic_req <= 1'b0;
                    state <= ST_IDH_DONE;
                end
                ST_IDH_DONE: if (!iic_busy) begin
                    O_sensor_id[15:8] <= rd_data;
                    state <= ST_IDL_REQ;
                end
                ST_IDL_REQ: if (!iic_busy) begin
                    wr_data <= {8'h00, 8'h08, 8'h31, CAM_ID};
                    wr_cnt <= 8'd3;
                    rd_cnt <= 8'd1;
                    iic_mode <= 1'b1;
                    iic_req <= 1'b1;
                    state <= ST_IDL_BUSY;
                end
                ST_IDL_BUSY: if (iic_busy) begin
                    iic_req <= 1'b0;
                    state <= ST_IDL_DONE;
                end
                ST_IDL_DONE: if (!iic_busy) begin
                    O_sensor_id[7:0] <= rd_data;
                    state <= ST_CHECK_ID;
                end
                ST_CHECK_ID: begin
                    if ((O_sensor_id == 16'hee4b) ||
                        (O_sensor_id == 16'h9e4b)) begin
                        O_sensor_id_ok <= 1'b1;
                        reg_index <= 9'd0;
                        ae_table_active <= 1'b0;
                        state <= ST_IDLE;
                    end else begin
                        state <= ST_ERROR;
                    end
                end
                ST_IDLE: begin
                    if (!O_cfg_done) begin
                        if (reg_index == init_reg_size) begin
                            O_cfg_done <= 1'b1;
                            O_ae_cfg_done <= 1'b1;
                        end else begin
                            state <= ST_WR_REQ;
                        end
                    end else if (ae_table_active) begin
                        if (reg_index == ae_reg_size) begin
                            ae_table_active <= 1'b0;
                            verify_index<=0;verify_wait_count<=0;O_verify_mask<=0;
                            state<=ST_VERIFY_WAIT;
                        end else begin
                            state <= ST_WR_REQ;
                        end
                    end else if (I_ae_req) begin
                        verify_retries<=0;O_verify_valid<=0;
                        ae_table_active <= 1'b1;
                        O_ae_cfg_done <= 1'b0;
                        reg_index <= 9'd0;
                    end
                end
                ST_WR_REQ: if (!iic_busy) begin
                    wr_data[7:0]   <= CAM_ID;
                    wr_data[15:8]  <= selected_reg_data[23:16];
                    wr_data[23:16] <= selected_reg_data[15:8];
                    wr_data[31:24] <= selected_reg_data[7:0];
                    wr_cnt <= 8'd4;
                    rd_cnt <= 8'd0;
                    iic_mode <= 1'b0;
                    iic_req <= 1'b1;
                    state <= ST_WR_BUSY;
                end
                ST_WR_BUSY: if (iic_busy) begin
                    iic_req <= 1'b0;
                    state <= ST_WR_DONE;
                end
                ST_WR_DONE: if (!iic_busy) begin
                    reg_index <= reg_index + 1'b1;
                    if (!ae_table_active && (reg_index == 9'd0)) begin
                        reset_wait_cnt <= 17'd0;
                        state <= ST_RESET_WAIT;
                    end else begin
                        state <= ST_IDLE;
                    end
                end
                ST_RESET_WAIT: begin
                    if (reset_wait_cnt == RESET_WAIT_CYCLES - 1) begin
                        state <= ST_IDLE;
                    end else begin
                        reset_wait_cnt <= reset_wait_cnt + 1'b1;
                    end
                end
                ST_VERIFY_WAIT:begin
                    if(verify_wait_count==VERIFY_WAIT_CYCLES-1)state<=ST_VERIFY_REQ;
                    else verify_wait_count<=verify_wait_count+1'b1;
                end
                ST_VERIFY_REQ:if(!iic_busy)begin
                    wr_data<={8'h00,verify_address[7:0],verify_address[15:8],CAM_ID};
                    wr_cnt<=3;rd_cnt<=1;iic_mode<=1;iic_req<=1;
                    verify_transaction_error<=0;state<=ST_VERIFY_BUSY;
                end
                ST_VERIFY_BUSY:if(iic_busy)begin iic_req<=0;state<=ST_VERIFY_DONE;end
                ST_VERIFY_DONE:if(!iic_busy)begin
                    O_readback[47-verify_index*8 -:8]<=rd_data;
                    O_verify_mask[verify_index]<=verify_transaction_error ||
                        ((rd_data & verify_bits)!=(verify_expected & verify_bits));
                    if(verify_index==5)begin
                        if((|O_verify_mask || verify_byte_failed) && verify_retries<2)begin
                            verify_retries<=verify_retries+1'b1;reg_index<=0;
                            ae_table_active<=1;O_verify_valid<=0;state<=ST_IDLE;
                        end else begin O_verify_valid<=1;O_ae_cfg_done<=1;state<=ST_IDLE;end
                    end
                    else begin verify_index<=verify_index+1'b1;state<=ST_VERIFY_REQ;end
                end
                ST_ERROR: begin
                    iic_req <= 1'b0;
                    O_cfg_done <= 1'b0;
                    O_ae_cfg_done <= 1'b0;
                end
                default: state <= ST_ERROR;
            endcase
        end
    end

    uii2c #(
        .WMEN_LEN(4),
        .RMEN_LEN(1),
        .CLK_DIV(CLK_DIV)
    ) u_i2c (
        .I_clk(I_clk),
        .I_rstn(I_rst_n),
        .O_iic_scl(O_cam_scl),
        .IO_iic_sda(IO_cam_sda),
        .I_wr_data(wr_data),
        .I_wr_cnt(wr_cnt),
        .O_rd_data(rd_data),
        .I_rd_cnt(rd_cnt),
        .I_iic_req(iic_req),
        .I_iic_mode(iic_mode),
        .O_iic_busy(iic_busy),
        .O_iic_bus_error(iic_bus_error),
        .IO_iic_sda_dg()
    );

    // SC520CS true 1280x720@60 mode.  This test keeps the factory 0x89 table
    // but clears register 0x3222 to verify Free-run operation.
    uics520reg_720p60 u_init_regs (
        .REG_INDEX(reg_index),
        .REG_DATA(init_reg_data),
        .REG_SIZE(init_reg_size)
    );

    SC520GainTbl u_gain (
        .I_AG(I_ag),
        .O(gain_value)
    );

    uics520regAE u_ae_regs (
        .REG_INDEX(reg_index),
        .REG_DATA(ae_reg_data),
        .REG_SIZE(ae_reg_size),
        .I_AE(I_ae),
        .I_AG(gain_value)
    );
endmodule
