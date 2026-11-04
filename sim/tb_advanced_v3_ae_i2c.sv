`timescale 1ns/1ps
module tb_advanced_v3_ae_i2c;
reg clk=0,rst=0;reg[31:0]meter=0;wire req,configured,done,history,verified;wire[15:0]exposure,gain;wire[31:0]status;
wire[47:0]readback;wire[5:0]mask;wire scl;tri1 sda;
always #5 clk=~clk;
adv_auto_exposure #(.CLK_HZ(1000000),.DEBOUNCE_CYCLES(2),.REPEAT_CYCLES(100000)) control(clk,~rst,4'hf,done,configured,req,exposure,gain,meter,status);
uicfgcs520 #(.CLK_DIV(7),.RESET_WAIT_CYCLES(20),.VERIFY_WAIT_CYCLES(50)) cfg(
.I_clk(clk),.I_rst_n(rst),.I_ae_req(req),.I_ae(exposure),.I_ag(gain),.O_cam_scl(scl),.IO_cam_sda(sda),.O_cfg_done(configured),.O_ae_cfg_done(done),.O_iic_error(history),.O_readback(readback),.O_verify_mask(mask),.O_verify_valid(verified));
sc520_i2c_model sensor(rst,scl,sda,1'b0);
integer seq=0,n,checks=0,bright_e;reg old_done=0;
wire[47:0]expected={4'd0,exposure[15:12],exposure[11:4],exposure[3:0],4'd0,8'h0f,8'h00,8'h80};
always @(posedge clk)begin old_done<=done;
 if(rst && done && !old_done && verified)begin if(mask!=0 || history || readback!==expected)$fatal(1,"auto exposure physical register verification failed E%h data%h expected%h",exposure,readback,expected);checks<=checks+1;end
end
task frame(input integer v);begin @(negedge clk);seq=seq+1;meter={seq[7:0],v[7:0],v[7:0],1'b1,2'd0,1'b0,1'b0,3'd0};repeat(5000)@(negedge clk);end endtask
initial begin rst=1;#1;rst=0;repeat(5)@(negedge clk);rst=1;wait(configured && done);
 for(n=0;n<45;n=n+1)frame(230);
 wait(done && verified && control.target_ae==exposure && control.write_state==0);repeat(5)@(negedge clk);
 bright_e=exposure;if(bright_e>=1996 || checks<2)$fatal(1,"bright input did not produce verified lower sensor exposure");
 for(n=0;n<60;n=n+1)frame(60);
 wait(done && verified && control.target_ae==exposure && control.write_state==0);repeat(5)@(negedge clk);
 if(exposure<=bright_e || mask!=0 || history || readback!==expected)$fatal(1,"dark input did not produce verified higher sensor exposure");
 $display("PASS ADVANCED V3 AE I2C: automatic bright/dark decisions drive real open-drain SCL/SDA, grouped sensor writes and six-byte register readback; no forced protocol outputs, verified updates%0d",checks);$finish;end
initial begin #20000000;$fatal(1,"AE physical I2C timeout");end
endmodule
