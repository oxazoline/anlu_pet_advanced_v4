`timescale 1ns/1ps
module tb_face_track;
    reg clk=0,rst=0,done=0,found=0,timeout=0;
    reg [7:0] x=0,votes=9;reg [6:0] y=20,size=48;
    wire [31:0] status,received;
    reg slow=0;always #17 slow=~slow;always #5 clk=~clk;
    ext_face_track #(.HOLD_CYCLES(2000)) dut(clk,rst,done,found,timeout,x,y,size,votes,status);
    ext_face_status_cdc cdc(clk,slow,rst,status,received);
    task result(input bit f,input bit t,input [7:0] bx,input [7:0] support);begin
        @(negedge clk);done=1;found=f;timeout=t;x=bx;votes=support;
        @(negedge clk);done=0;
    end endtask
    task acquire(input [7:0] bx);begin
        result(1,0,bx,9);result(1,0,bx,9);result(1,0,bx,9);
        if(!status[31])$fatal(1,"three strong consistent detections must confirm");
    end endtask
    task settle;begin repeat(80)@(negedge clk);if(received!==status)$fatal(1,"atomic CDC lost final update");end endtask
    integer k;reg [7:0] held_x;
    initial begin
        repeat(3)@(negedge clk);rst=1;
        // Repeated weak background evidence cannot create a face.
        for(k=0;k<8;k=k+1)result(1,0,20,4);
        if(status[31])$fatal(1,"weak repeated background confirmed");
        result(1,0,20,9);result(1,0,22,9);
        if(status[31])$fatal(1,"two hits must not confirm");
        result(0,0,0,0);result(1,0,22,9);
        if(status[31])$fatal(1,"entry must use consecutive evidence");
        result(1,0,70,9);result(1,0,22,9);
        if(status[31])$fatal(1,"spatially inconsistent background confirmed");
        result(1,0,22,9);result(1,0,22,9);if(!status[31])$fatal(1,"acquisition");
        result(1,0,30,2);if(status[29:22]!=26)$fatal(1,"weak local support must maintain existing face");
        // Last observed movement predicts +4, +2, +1 low-resolution pixels only.
        result(0,0,0,0);if(!status[31] || status[29:22]!=30 || status[7:0]!=0)$fatal(1,"first loss prediction");
        result(0,0,0,0);if(!status[31] || status[29:22]!=32)$fatal(1,"second loss prediction");
        result(1,0,34,2);if(!status[31] || status[7:0]!=2)$fatal(1,"recover without three-hit reentry");settle;
        // A foreign face/background cannot steal the box or refresh its lifetime.
        held_x=status[29:22];
        for(k=0;k<3;k=k+1)begin result(1,0,110,9);if(!status[31] || status[29:22]>held_x+7)$fatal(1,"foreign candidate stole target");end
        result(1,0,110,9);if(status[31])$fatal(1,"four unsupported rounds must clear");
        acquire(110);result(1,1,110,9);if(status[31] || !status[30])$fatal(1,"watchdog clear");settle;
        // Simultaneous absolute expiry and watchdog must still report the latest timeout.
        acquire(20);while(dut.age<1998)@(negedge clk);result(0,1,0,0);
        if(status[31] || !status[30])$fatal(1,"deadline/watchdog coincidence lost T status");
        // Absolute deadline expires without any done pulse, not just a round counter.
        acquire(20);repeat(2001)@(negedge clk);if(status[31])$fatal(1,"absolute loss deadline failed");
        result(1,0,20,9);repeat(2001)@(negedge clk);result(1,0,20,9);result(1,0,20,9);
        if(status[31])$fatal(1,"expired pending observations reused");
        result(1,0,20,9);if(!status[31])$fatal(1,"reentry after pending expiration");
        // Convex smoothing must stay in bounds when position/size parity differs.
        result(1,1,0,0);size=48;y=42;acquire(112);
        size=47;y=43;result(1,0,113,9);
        if({1'b0,status[29:22]}+{2'b0,status[14:8]}>160 || {2'b0,status[21:15]}+{2'b0,status[14:8]}>90)$fatal(1,"smoothing moved edge box out of bounds");
        // Predictions saturate at image edges rather than wrapping unsigned coordinates.
        result(1,1,0,0);size=24;y=66;acquire(132);result(1,0,136,9);
        for(k=0;k<3;k=k+1)begin result(0,0,0,0);if(status[29:22]>136 || status[21:15]>66)$fatal(1,"positive edge wrap");end
        result(1,1,0,0);y=0;acquire(4);result(1,0,0,9);
        for(k=0;k<3;k=k+1)begin result(0,0,0,0);if(status[29:22]>4 || status[21:15]!=0)$fatal(1,"negative edge wrap");end
        result(1,1,0,0);size=89;y=0;
        begin : acquire_invalid
            for(k=0;k<4;k=k+1)result(1,0,0,9);
            if(status[31])$fatal(1,"invalid box admitted");
        end
        rst=0;repeat(3)@(negedge clk);if(status!==0 || received!==0)$fatal(1,"reset");
        $display("PASS FACE TRACK V5: weak/background entry rejection, three-hit spatial confirmation, low-support maintenance, bounded decaying prediction, local recovery, foreign candidate isolation, loss-round and absolute deadlines, pending expiry, clipping including smoothed edge boxes, timeout, asynchronous CDC/reset");$finish;
    end
endmodule
