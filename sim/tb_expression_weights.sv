`timescale 1ns/1ps
module tb_expression_weights;
reg clk=0;always #5 clk=~clk;reg rst_n=0,start=0,ready=0,enable_ready=0;reg [4:0] neuron=0;
wire valid,done;wire [5:0] value;reg [7:0] reference[0:64511];
integer row,seen=0,total=0,cycles=0,expected_row=0;reg old_stall=0;reg [5:0] old_value=0;
ext_expression_weights dut(clk,rst_n,start,neuron,ready,valid,value,done);
always @(negedge clk)ready=enable_ready&&(cycles%11!=1)&&(cycles%11!=2)&&(cycles%257>=16);
always @(posedge clk)begin
 cycles=cycles+1;
 if(rst_n && old_stall && !start)if(!valid || value!==old_value)$fatal(1,"Stream instability under backpressure");
 old_stall=rst_n&&valid&&!ready&&!start;old_value=value;
 if(rst_n&&valid&&ready)begin
  if(seen>=2016 || {{2{value[5]}},value}!==reference[seen*32+expected_row])$fatal(1,"Dense original coefficient row=%0d feature=%0d",expected_row,seen);
  seen=seen+1;total=total+1;
 end
end
task launch(input integer n);begin @(negedge clk);neuron=n;expected_row=n;seen=0;start=1;@(negedge clk);start=0;end endtask
initial begin
 $readmemh("expression_w1.hex",reference);repeat(5)@(negedge clk);rst_n=1;enable_ready=1;
 for(row=31;row>=0;row=row-1)begin launch(row);wait(done);@(negedge clk);if(seen!=2016)$fatal(1,"Incomplete neuron");end
 launch(6);wait(seen>=7);launch(17);wait(done);@(negedge clk);if(seen!=2016)$fatal(1,"Restart failed");
 $display("PASS EXPRESSION WEIGHTS: all64512 original signed6 model bytes, neuron seeks, backpressure, abort/restart; total=%0d",total);$finish;
end
initial begin #50000000;$fatal(1,"Stream timeout");end
endmodule
