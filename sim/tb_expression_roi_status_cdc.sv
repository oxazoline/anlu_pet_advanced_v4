`timescale 1ns/1ps
// Control-path reproduction only. No camera accuracy or spontaneous event rate.
// face is updated synchronously, with a nonblocking assignment on the CSI edge,
// exactly as a registered tracker output changes. Only core results are forced.
// VS phase is deliberately aligned to the observed invalid-ROI CDC bundle.
// V15 original failed this coherent-status contract; model results are mocked.
module tb_expression_roi_status_cdc;
 reg csi=0,hdmi=0,rst=0,sof=0,vs=0,de=0;
 always #5 csi=~csi;
 always #7 hdmi=~hdmi;
 reg [31:0] face=0;reg [167:0] neutral_diag;
 wire [31:0] active,display,face_display;wire [167:0] diagnostic,diagnostic_display;
 wire ov,oh,od;wire[23:0] rgb;wire[9:0] preview_address;
 ext_expression_capture #(.CONFUSED_GUARD(0),.ENABLE_CONFUSED(1),.BALANCED_POLICY(0),.ENABLE_AU(0)) capture(csi,rst,96'd0,1'b0,sof,face,active,diagnostic,,,,,);
 ext_face_status_cdc #(.WIDTH(200)) bundle(csi,hdmi,rst,{diagnostic,active},{diagnostic_display,display});
 ext_face_status_cdc face_bundle(csi,hdmi,rst,face,face_display);
 basic_osd #(.ENABLE_CONFUSED_UI(1),.COMPACT_DEBUG(0)) osd(
  .I_clk(hdmi),.I_rst_n(rst),.I_vs(vs),.I_hs(1'b0),.I_de(de),.I_rgb(24'h123456),
  .I_fault(4'd0),.I_boot_counts(64'd0),.I_run_counts(64'd0),.I_running(1'b1),
  .I_error_addresses(32'd0),.I_readback_status(71'd0),.I_saturation_status(8'd64),
  .O_vs(ov),.O_hs(oh),.O_de(od),.O_rgb(rgb),.I_view_status(2'd3),
  .I_face_status(face_display),.I_expression_status(display),.I_expression_diagnostic(diagnostic_display),
  .I_preview_gray(8'd0),.I_preview_valid(1'b0),.I_preview_id(8'd0),.O_preview_address(preview_address));
 integer src_transient_samples=0,dst_transient_samples=0,pixels_checked=0,x,y;
 reg expected_area=0;reg [2:0] area_delay=0;
 always @(posedge csi)if(rst && active[8] && active[10:9]==1 && active[15:12]==0 && active[1:0]==0)begin
  src_transient_samples=src_transient_samples+1;
  $display("SOURCE_WINDOW t=%0t raw=N rs=0 label=0 diagnostic_valid=%0d roi_consistent=%0d", $time,active[8],capture.roi_consistent);
 end
 always @(posedge hdmi)begin
  if(!rst)area_delay<=0;
  else begin
   area_delay<={area_delay[1:0],expected_area};
   if(expected_area && osd.expression_area)$fatal(1,"empty-label frame rendered expression_area");
   if(display[8] && display[10:9]==1 && display[15:12]==0 && display[1:0]==0)dst_transient_samples=dst_transient_samples+1;
   if(osd.face_status[31] && osd.expression_status[8] && osd.expression_status[10:9]==1 && osd.expression_status[15:12]==0 && osd.expression_status[1:0]==0)$fatal(1,"OSD success diagnostic with empty label");
  end
  #1;if(rst && area_delay[2])begin
   if(!od || rgb!==24'h123456)$fatal(1,"bottom expression rectangle still rendered got=%h de=%0d",rgb,od);
   pixels_checked=pixels_checked+1;
  end
 end
 task face_sof;
 begin @(negedge csi);sof=1;@(negedge csi);sof=0;end
 endtask
 task neutral_result;
 begin
  @(negedge csi);force capture.core_diagnostic=neutral_diag;force capture.result=2'd2;
  force capture.result_allowed=1'b1;force capture.done=1'b1;
  @(negedge csi);force capture.done=1'b0;release capture.core_diagnostic;release capture.result;release capture.result_allowed;
 end
 endtask
 task snapshot;
 begin @(negedge hdmi);vs=1;@(negedge hdmi);vs=0;#1;end
 endtask
 initial begin
  neutral_diag=0;neutral_diag[167]=1;neutral_diag[165:164]=1;
  neutral_diag[95:64]=32'd3000;neutral_diag[31:0]=32'd3000;
  force capture.busy=0;force capture.capture=0;force capture.start=0;force capture.done=0;
  repeat(4)@(negedge csi);rst=1;
  // Valid baseline ROI. Setup also uses a source-clock nonblocking update.
  @(posedge csi);face<={1'b1,1'b0,8'd30,7'd20,7'd32,8'd6};
  face_sof;neutral_result;
  wait(display[1:0]==2 && display[15:12]==0 && display[10:9]==1 && face_display[31]);
  repeat(20)@(negedge csi);
  if(active[1:0]!=2 || !capture.diagnostic_valid)$fatal(1,"neutral baseline missing");
  $display("BASELINE t=%0t label=2 raw=N rs=0",$time);
  // Realistic synchronous tracker-output transition: one CSI posedge, NBA.
  @(posedge csi);face<={1'b1,1'b0,8'd70,7'd20,7'd32,8'd6};
  wait(!display[8] && display[10:9]==1 && display[15:12]==15 && display[1:0]==0 && !display[5]);
  $display("CDC_WINDOW t=%0t label=0 raw=N rs=F valid=0 owner=0",$time);
  snapshot;
  if(!osd.face_status[31] || osd.expression_status[1:0]!=0 || osd.expression_status[15:12]!=15 || osd.expression_status[10:9]!=1 || osd.expression_status[8] || osd.expression_status[5])
    $fatal(1,"OSD did not snapshot the transient bundle");
  $display("OSD_SNAPSHOT t=%0t visible_face=1 label=0 raw=N rs=F diagnostic_valid=0 owner=0",$time);
  // Drive real 1280-active-pixel scan lines so the actual bottom rectangle is
  // verified through the OSD RGB pipeline, not through a forced x/y position.
  for(y=0;y<697;y=y+1)begin
   for(x=0;x<1280;x=x+1)begin
    @(negedge hdmi);de=1;
    expected_area=x>=16 && x<208 && y>=680 && y<696;
   end
   @(negedge hdmi);de=0;expected_area=0;repeat(2)@(negedge hdmi);
  end
  repeat(6)@(negedge hdmi);
  if(pixels_checked!=3072)$fatal(1,"bottom rectangle pixel count got=%0d",pixels_checked);
  if(display[15:12]!=15 || display[8])$fatal(1,"final cleared source state failed to arrive");
  if(osd.expression_status[15:12]!=15 || osd.expression_status[10:9]!=1 || osd.expression_status[1:0]!=0)
    $fatal(1,"OSD snapshot changed before VS");
  $display("ONE_FRAME_HELD source_current_rs=F snapshot_raw=N snapshot_rs=F snapshot_label=0 bottom_pixels=%0d",pixels_checked);
  snapshot;
  if(osd.expression_status[15:12]!=15 || osd.expression_status[8])$fatal(1,"next VS did not replace transient with cleared state");
  $display("NEXT_FRAME t=%0t rs=F diagnostic_valid=0; no contradictory success status",$time);
  face_sof;neutral_result;
  wait(display[1:0]==2 && display[15:12]==0);
  snapshot;
  if(osd.expression_status[1:0]!=2)$fatal(1,"fresh stable ROI could not restore NEUTRAL");
  $display("RECOVERY fresh owned ROI result restores label=2");
  if(src_transient_samples!=0 || dst_transient_samples!=0)$fatal(1,"RAW=N RS0 label0 contradiction escaped coherency gate");
  $display("PASS EXPRESSION ROI STATUS CDC: synchronous registered face change never publishes RAW=N RS0 VALID1 label0; selected VS reports RS F owner0 VALID0 while all3072 bottom pixels bypass text; fresh neutral result restores label. This is control timing, not camera accuracy. src_samples=%0d dst_samples=%0d",src_transient_samples,dst_transient_samples);
  $finish;
 end
 initial begin #30000000;$fatal(1,"focused control reproduction timeout");end
endmodule
