`timescale 1ns/1ps
module tb_advanced_overlay;
reg clk=0,rst=0,vs=0,hs=0,de=0;reg[23:0]rgb=24'h304050;
reg[31:0]refbox=0,hand=0,motion=0;wire ov,oh,od;wire[23:0]out;
wire[63:0]metrics={1'b1,1'b0,2'd2,16'd42,16'd100,16'd7,6'd0,6'd0};
adv_overlay dut(clk,rst,vs,hs,de,rgb,refbox,hand,motion,32'h00070000,metrics,ov,oh,od,out,32'd0,32'hD98987CC);
always #5 clk=~clk;
integer x,y,f,count=0;reg write_image=0;
always @(negedge clk)if(write_image && od)begin $fwrite(f,"%c%c%c",out[23:16],out[15:8],out[7:0]);if(count==480*1280+800 && out!==24'h304050)$fatal(1,"yellow motion outline was not hidden");count=count+1;end
initial begin
 repeat(3)@(negedge clk);rst=1;refbox={2'b10,8'd80,7'd30,8'd30,7'd20};hand={2'b10,8'd20,7'd20,8'd25,7'd45};motion={2'b10,8'd100,7'd60,8'd30,7'd20};
 @(negedge clk);vs=1;@(negedge clk);vs=0;repeat(3)@(negedge clk);
 f=$fopen("advanced_overlay.ppm","wb");$fwrite(f,"P6\n1280 720\n255\n");write_image=1;
 for(y=0;y<720;y=y+1)begin
  for(x=0;x<1280;x=x+1)begin @(negedge clk);de=1;end
  @(negedge clk);de=0;repeat(3)@(negedge clk);
  if(y==2 && !dut.motion_box[31])$fatal(1,"MOVE status disappeared with hidden outline");
  if(y==2 && (dut.lat_bcd!==20'h00042 || dut.max_bcd!==20'h00100 || dut.id_bcd!==20'h00007))$fatal(1,"decimal metric conversion");
  if(y==200)begin refbox=0;if(!dut.ref_box[31])$fatal(1,"frame atomic box changed");end
 end
 repeat(5)@(negedge clk);write_image=0;$fclose(f);
 if(count!=1280*720)$fatal(1,"active pixel count: %0d",count);
 @(negedge clk);vs=1;@(negedge clk);vs=0;repeat(3)@(negedge clk);if(dut.ref_box[31])$fatal(1,"new frame did not withdraw box");
 $display("PASS ADVANCED OVERLAY: full720p raster, decimal latency/max/id, frame-atomic boxes, exact active pixel count and aligned two-stage output");$finish;
end
initial begin #20000000;$fatal(1,"overlay timeout");end
endmodule
