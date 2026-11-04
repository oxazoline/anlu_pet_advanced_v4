`timescale 1ns/1ps
module tb_hdmi_serial_reset;
 reg pixel=0,serial=0,rst=0,serial_run=1;always #5 pixel=~pixel;
 always #1 if(serial_run)serial=~serial;
 reg [9:0] data=0;wire actual,reference;
 lane_lvds_10_1 #(.DEVICE("PH1P")) dut(pixel,serial,rst,data,actual);
 legacy_lane_lvds #(.DEVICE("PH1P")) gold(pixel,serial,rst,data,reference);
 integer words=0,warm=0,compared=0,round,i;reg seen_zero=0,seen_one=0;real last_serial_rise=0;
 always @(negedge pixel)begin data<=((words*79)^(words>>2)^10'h2b5)&1023;words=words+1;end
 always @(posedge pixel or posedge rst)begin if(rst)warm<=0;else if(warm<15)warm<=warm+1;end
 always @(posedge serial)last_serial_rise=$realtime;
 always @(negedge dut.S_serial_rst)begin
  if($time>0 && !rst && $realtime!=last_serial_rise)$fatal(1,"reset release outside serializer rising edge");
 end
 always @(serial)begin
  #0.05;
  if(warm>=15 && !rst && serial_run)begin
   if(actual!==reference)$fatal(1,"steady TMDS bit changed words=%0d expected=%b actual=%b",words,reference,actual);
   if(actual===0)seen_zero=1;else if(actual===1)seen_one=1;
   compared=compared+1;
  end
 end
 task assert_reset;begin
  #0.27;rst=1;#0.05;
  if(dut.S_serial_rst!==1 || actual!==0 || dut.S_shift_data!==0)$fatal(1,"reset assertion not asynchronous");
 end endtask
 task release_reset;integer n;begin
  @(negedge serial);#0.17;rst=0;
  for(n=0;n<2;n=n+1)begin
   @(posedge serial);#0.05;
   if(dut.S_serial_rst!==(n==0))$fatal(1,"reset release not exactly two serializer edges");
  end
 end endtask
 initial begin
  assert_reset;repeat(4)@(negedge pixel);release_reset;
  for(round=0;round<4;round=round+1)begin
   repeat(350)@(negedge pixel);assert_reset;
   if(round==1)begin
    // No serializer edges: release must remain blocked, asynchronous assertion
    // must still be effective; start again before the two-edge check.
    @(negedge serial);serial_run=0;#0.17;rst=0;#11;
    if(dut.S_serial_rst!==1 || actual!==0)$fatal(1,"reset released without clock");
    rst=1;serial_run=1;release_reset;
   end else release_reset;
  end
  repeat(50)@(negedge pixel);
  if(!seen_zero || !seen_one)$fatal(1,"constant serializer output invalidates comparison");
  if(compared<10000)$fatal(1,"insufficient serial comparison");
  $display("PASS HDMI SERIAL RESET: %0d native-lane TMDS bits equal frozen V8 after startup, 5 reset phases, two-edge release, immediate assertion and stopped-clock safety",compared);$finish;
 end
 initial begin #100000;$fatal(1,"test timeout");end
endmodule
