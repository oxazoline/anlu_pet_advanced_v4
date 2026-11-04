`timescale 1ns/1ps
module tb_face_shrink_guard;
reg clk=0,rst=0,done=0,found=1,tmo=0;always #5 clk=~clk;reg[7:0] x=40,votes=7;reg[6:0] y=10,w=60;wire[31:0] status;
ext_face_track #(.HOLD_CYCLES(300),.ACQUIRE_CYCLES(1000)) dut(clk,rst,done,found,tmo,x,y,w,votes,status);
task result(input[6:0] size,input[7:0] support);begin @(negedge clk);w=size;votes=support;done=1;@(negedge clk);done=0;end endtask
task acquire;begin x=40;y=10;result(60,7);result(60,7);result(60,7);if(!status[31])$fatal(1,"initial acquisition");end endtask
task reset;begin rst=0;repeat(3)@(negedge clk);rst=1;end endtask
integer i;
initial begin
 reset;acquire;x=55;y=25;
 for(i=0;i<3;i=i+1)begin result(30,2);if(!status[31] || status[14:8]!=60)$fatal(1,"weak lens candidate shrank face");end
 result(30,2);if(status[31])$fatal(1,"lens-only weak evidence retained stale face indefinitely");
 reset;acquire;x=55;y=25;
 result(30,7);if(status[14:8]!=60)$fatal(1,"single strong lens/shrink candidate");
 result(30,7);if(status[14:8]!=60)$fatal(1,"two strong lens/shrink candidates");
 result(30,7);if(!status[31] || status[14:8]!=30)$fatal(1,"three consistent strong smaller-face observations not accepted");
 reset;acquire;x=55;y=25;result(30,7);found=0;result(0,0);found=1;result(30,7);if(status[14:8]!=60)$fatal(1,"interrupted shrink confirmation reused");
 // Moderate real distance changes still follow the normal low-support path.
 reset;acquire;x=44;y=14;result(52,2);if(!status[31] || status[14:8]!=56)$fatal(1,"ordinary distance tracking regressed");
 tmo=1;result(52,7);if(status[31] || !status[30])$fatal(1,"timeout did not clear");
 $display("PASS SHRINK GUARD: weak eye-only geometry rejected, bounded disappearance, three strong consistent shrink confirmations, interruption and ordinary retreat preserved");$finish;
end
initial begin #100000;$fatal(1,"timeout");end
endmodule
