`timescale 1ns/1ps
module tb_expression_cdc;
 reg a=0,b=0,rst=0;always #5 a=~a;always #7 b=~b;
 reg [199:0] value=0;wire [199:0] result;
 ext_face_status_cdc #(.WIDTH(200)) dut(a,b,rst,value,result);
 integer i,transfers=0,stable_start=0;reg [199:0] final_value;
 reg [199:0] held_before;reg pending_before,request_before;
 always @(posedge a)begin
  if(!rst)transfers=0;
  else begin
   held_before=dut.held;pending_before=dut.request!=dut.ack_sync[1];request_before=dut.request;
   #1;if(pending_before && dut.held!==held_before)$fatal(1,"Source bundle changed before acknowledgement");
   if(dut.request!=request_before)transfers=transfers+1;
  end
 end
 initial begin
  repeat(3)@(negedge a);rst=1;
  // Emulate one receive-edge of data/control skew. A two-stage request with
  // an equally delayed data bus acknowledges stale data; the extra stage must
  // allow the bus to settle before acknowledgement.
  force dut.data_meta=200'd0;
  @(negedge a);value={8'h55,32'd1105,32'd1445,32'd1615,32'd1955,32'd2465,32'd2635};
  wait(dut.request!=dut.seen);@(posedge b);#1;release dut.data_meta;
  repeat(12)@(negedge b);if(result!==value)$fatal(1,"request acknowledged before delayed data settled");
  for(i=1;i<=40;i=i+1)begin
   @(negedge a);value={8'(i),32'(i*13),32'(i*17),32'(i*19),32'(i*23),32'(i*29),32'(i*31)};
  end
  final_value=value;stable_start=transfers;repeat(30)@(negedge b);
  if(transfers-stable_start<3)$fatal(1,"Idle snapshot publication not running");
  if(result!==final_value)$fatal(1,"final 200-bit bundle lost or incoherent");
  rst=0;repeat(4)@(negedge b);if(result!==0)$fatal(1,"wide CDC reset");
  value={8'd77,32'd1001,32'd1309,32'd1463,32'd1771,32'd2233,32'd2387};rst=1;
  repeat(30)@(negedge b);if(result!==value)$fatal(1,"CDC did not recover with a fresh bundle after reset");
  $display("PASS EXPRESSION CDC: held-until-ack invariant, periodic idle snapshots without wide compare, reset recovery; 200-bit score/status bundle, one-edge data/control skew, rapid coalesced updates, final stable value and reset");$finish;
 end
 always @(negedge b)if(rst && result!=0)begin
  if(result[191:160]!==result[199:192]*13 || result[31:0]!==result[199:192]*31)$fatal(1,"torn expression bundle");
 end
endmodule
