`timescale 1ns/1ps
module tb_face_highlight_retry;
reg clk=0,rst=0,v=0,sof=0;reg[95:0] data=0;always #5 clk=~clk;wire[31:0] status;
ext_face_detector #(.ENABLE_ZOOM(0),.ENABLE_HIGHLIGHT(1)) dut(clk,rst,data,v,sof,status);
integer y,x,k,frame,p,expected_level;
task tick(input bit valid,input bit fs);begin @(negedge clk);v=valid;sof=fs;end endtask
task no_result;begin force dut.done=1;force dut.found=0;force dut.timeout=0;@(negedge clk);force dut.done=0;end endtask
initial begin
 repeat(3)@(negedge clk);rst=1;force dut.busy=0;force dut.start=0;force dut.phase=0;force dut.large_scan=0;
 tick(0,1);tick(0,0);if(dut.filter_capture)$fatal(1,"first image not raw");
 no_result;tick(0,1);tick(0,0);if(!dut.filter_capture)$fatal(1,"miss did not schedule highlight retry");
 for(frame=0;frame<2;frame=frame+1)begin
  p=frame==0?244:152;expected_level=p>192?192+((p-192)>>2):p;
  force dut.prefer_filter=1;tick(0,1);tick(0,0);
  data={12{p[7:0]}};
  for(y=0;y<=715;y=y+1)for(x=0;x<320;x=x+1)tick(1,0);
  tick(0,0);repeat(6)tick(0,0);
  for(k=0;k<14400;k=k+1)if(dut.image_ram.line_store.memory[k]!==expected_level*(k%160+1)*(k/160+1))$fatal(1,"highlight integral frame=%0d addr=%0d",frame,k);
 end
 release dut.prefer_filter;force dut.filter_capture=1;no_result;
 if(dut.prefer_filter)$fatal(1,"failed highlight retry did not return raw");
 $display("PASS HIGHLIGHT RETRY: raw-first, failed-scan retry/return, two full 14400-integral frames, exact highlight knee and ordinary-gray preservation");$finish;
end
initial begin #10000000;$fatal(1,"timeout");end
endmodule
