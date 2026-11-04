`timescale 1ns/1ps
`default_nettype none
module tb_expression_pipeline;
 reg S_csi_rx_clk=0,S_hdmi_pixel_clk=0,S_rst_n=0,S_hdmi_out_vsync=0;
 always #5 S_csi_rx_clk=~S_csi_rx_clk;always #7 S_hdmi_pixel_clk=~S_hdmi_pixel_clk;
 reg [95:0] data=0;reg valid=0,sof=0;reg [31:0] face=0;wire [31:0] status;wire [167:0] diagnostic;
 wire patch_write,patch_commit,preview_valid;wire [9:0] patch_address;reg [9:0] preview_address=0;
 wire [7:0] patch_pixel,patch_id,preview_gray,preview_id;
 ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.BALANCED_POLICY(0),.ENABLE_AU(0)) capture(S_csi_rx_clk,S_rst_n,data,valid,sof,face,status,diagnostic,patch_write,patch_address,patch_pixel,patch_commit,patch_id);
 `include "expression_preview_instance.vh"
 integer y,x,k,i,writes=0,commits=0,exp_pixel;reg [7:0] expected[0:1023];
 function [7:0] pixel(input integer xx,yy);begin pixel=(xx*13+yy*9+xx*yy)%256;end endfunction
 always @(posedge S_csi_rx_clk)if(S_rst_n)begin
  if(patch_write)begin expected[patch_address]=patch_pixel;writes=writes+1;end
  if(patch_commit)commits=commits+1;
 end
 initial begin
  repeat(3)@(negedge S_csi_rx_clk);S_rst_n=1;
  face={1'b1,1'b0,8'd20,7'd12,7'd32,8'd9};
  @(negedge S_csi_rx_clk);sof=1;@(negedge S_csi_rx_clk);sof=0;
  for(y=0;y<720;y=y+1)for(x=0;x<320;x=x+1)begin
   @(negedge S_csi_rx_clk);valid=1;
   for(k=0;k<4;k=k+1)data[95-k*24-:24]={3{pixel(x*4+k,y)}};
  end
  @(negedge S_csi_rx_clk);valid=0;
  wait(commits==1);repeat(12)@(negedge S_hdmi_pixel_clk);
  if(preview_valid)$fatal(1,"preview switched before actual VS");
  if(writes!=1024)$fatal(1,"writes %0d",writes);
  S_hdmi_out_vsync=1;@(negedge S_hdmi_pixel_clk);S_hdmi_out_vsync=0;repeat(6)@(negedge S_hdmi_pixel_clk);
  if(!preview_valid || preview_id!=status[31:24])$fatal(1,"complete real capture never published id %0d/%0d",preview_id,status[31:24]);
  for(i=0;i<1024;i=i+1)begin
   @(negedge S_hdmi_pixel_clk);preview_address=i;@(posedge S_hdmi_pixel_clk);#1;
   if(preview_gray!==expected[i])$fatal(1,"real pipeline preview mismatch at %0d",i);
  end
  if(!status[8])$fatal(1,"real inference missing");
  $display("PASS EXPRESSION PIPELINE: actual top-level preview instance, 1024 samples through real capture/model/commit/async-preview, IDs and VS-only publication, no forced inference");$finish;
 end
 initial begin #20000000;$fatal(1,"expression pipeline timeout");end
endmodule
`default_nettype wire
