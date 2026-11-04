`timescale 1ns/1ps
module tb_sensor_startup_retry;
 reg clk=0,rst=0;always #5 clk=~clk;wire req;wire [15:0] ae,ag;wire configured,done,verified,history;wire[5:0] mask;wire[47:0] rb;tri1 sda;wire scl;
 ae_set #(.CLK_HZ(1000),.DEBOUNCE_CYCLES(3),.REPEAT_CYCLES(12)) ae_driver(clk,!rst,4'hf,done,configured,req,ae,ag);
 uicfgcs520 #(.CLK_DIV(19),.RESET_WAIT_CYCLES(20),.VERIFY_WAIT_CYCLES(50)) dut(
 .I_clk(clk),.I_rst_n(rst),.I_ae_req(req),.I_ae(ae),.I_ag(ag),.O_cam_scl(scl),.IO_cam_sda(sda),.O_cfg_done(configured),.O_ae_cfg_done(done),.O_iic_error(history),
 .O_readback(rb),.O_verify_mask(mask),.O_verify_valid(verified));
 sc520_i2c_model #(.DROP_FIRST_GROUP(1)) sensor(rst,scl,sda,1'b0);
 initial begin
 rst=1;#1;rst=0;repeat(4)@(negedge clk);rst=1;
 wait(configured);wait(!done);wait(verified && done);repeat(4)@(negedge clk);
 if(sensor.grouped_writes!=2 || dut.verify_retries!=1)$fatal(1,"Startup did not retry exactly one ignored exposure group");
 if(rb!==48'h00f9700f0080 || mask!==0 || history)$fatal(1,"Automatic startup recovery did not establish desired/readback agreement");
 if(ae!=3991 || ag!=144)$fatal(1,"Recovery changed requested exposure/gain");
 repeat(100)@(negedge clk);if(sensor.grouped_writes!=2)$fatal(1,"Successful recovery kept rewriting");
 $display("PASS STARTUP READBACK RETRY: real ae_set and SCL/SDA, no keys, first exposure group deliberately ignored, automatic same-value rewrite and verified green, no fake expected values or endless retry");$finish;
 end
 initial begin #10000000;$fatal(1,"startup retry timeout");end
endmodule
