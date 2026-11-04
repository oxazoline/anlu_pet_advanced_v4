`timescale 1ns/1ps
module tb_face_weak_profile_entry;
reg clk=0,rst=0,done=0,found=1,tmo=0;always #5 clk=~clk;
reg [7:0] x=30,votes=131;reg[6:0] y=20,w=40;wire[31:0] status;
ext_face_track #(.HOLD_CYCLES(200),.ACQUIRE_CYCLES(400)) dut(clk,rst,done,found,tmo,x,y,w,votes,status);
task step(input[7:0] v);begin @(negedge clk);votes=v;done=1;@(negedge clk);done=0;end endtask
task reset;begin rst=0;repeat(2)@(negedge clk);rst=1;end endtask
integer i;
initial begin
 reset;
 for(i=0;i<10;i=i+1)step(3);if(status[31])$fatal(1,"weak frontal acquired");
 for(i=0;i<4;i=i+1)begin step(131);if(status[31])$fatal(1,"weak profile entry before five");end
 step(131);if(!status[31] || !status[7])$fatal(1,"five consistent weak profile hits not accepted");
 repeat(201)@(negedge clk);if(status[31])$fatal(1,"weak profile unbounded hold");
 reset;step(131);step(131);found=0;step(0);step(0);found=1;
 for(i=0;i<4;i=i+1)begin step(131);if(status[31])$fatal(1,"interrupted evidence reused");end
 step(131);if(!status[31])$fatal(1,"fresh five reentry");
 reset;step(131);step(131);found=0;step(0);found=1;
 step(131);step(131);if(status[31])$fatal(1,"one-gap acquired before five real hits");
 step(131);if(!status[31])$fatal(1,"one missed observation discarded profile confirmation");
 reset;step(131);step(9);step(9);if(status[31])$fatal(1,"mixed weak evidence bypassed five-hit requirement");
 step(9);if(status[31])$fatal(1,"four mixed entry");step(9);if(!status[31])$fatal(1,"five mixed entry");
 reset;step(9);step(9);if(status[31])$fatal(1,"strong two entry");step(9);if(!status[31])$fatal(1,"strong three regressed");
 reset;step(131);x=105;step(131);x=30;step(131);x=105;step(131);x=30;step(131);if(status[31])$fatal(1,"foreign weak profile accumulation");
 reset;step(131);repeat(401)@(negedge clk);
 for(i=0;i<4;i=i+1)begin step(131);if(status[31])$fatal(1,"expired weak pending evidence reused");end
 step(131);if(!status[31])$fatal(1,"new five after expiry");
 tmo=1;step(131);if(status[31] || !status[30])$fatal(1,"timeout retained weak profile");
 $display("PASS WEAK PROFILE ENTRY: frontal weak rejection, five consistent profile hits, mixed-strength guard, strong three preserved, one-gap tolerance, two-miss/spatial/deadline/timeout rejection");$finish;
end
initial begin #100000;$fatal(1,"hang");end
endmodule
