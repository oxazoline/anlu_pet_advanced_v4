`timescale 1ns/1ps
// Isolated grouped-candidate selection tests. Cascade arithmetic is covered by tb_face_lbp.
module tb_face_select;
    reg clk=0,rst=0,start=0;always #5 clk=~clk;
    reg [31:0] hint=0;
    wire busy,done,found,timeout;wire [7:0] x,votes;wire [6:0] y,size;wire [13:0] address;
    ext_face_lbp #(.ENABLE_PRIORITY(0)) dut(clk,rst,start,busy,done,found,timeout,x,y,size,votes,address,22'd0,hint);
    integer k;
    task select_groups(input bit use_hint,input [7:0] local_votes,input [7:0] local_width);begin
        @(negedge clk);hint=use_hint?{1'b1,1'b0,8'd20,7'd20,7'd48,8'd9}:32'd0;start=1;
        @(negedge clk);start=0;
        // Verify scan-time hint snapshot: incoming status changes must not tear selection.
        hint=0;
        dut.state=dut.RESULT_READ;dut.ci=0;dut.best_count=0;dut.local_count=0;
        for(k=0;k<8;k=k+1)begin dut.count[k]=0;dut.cx[k]=0;dut.cy[k]=0;dut.cw[k]=0;end
        dut.count[0]=9;dut.cx[0]=132;dut.cy[0]=44;dut.cw[0]=48;
        dut.count[7]=local_votes;dut.cx[7]=44;dut.cy[7]=44;dut.cw[7]=local_width;
        wait(done);@(negedge clk);
    end endtask
    initial begin
        repeat(3)@(negedge clk);rst=1;
        select_groups(0,5,48);if(!found || x!=108 || votes!=9)$fatal(1,"global strongest acquisition");
        select_groups(1,2,48);if(!found || x!=20 || votes!=2)$fatal(1,"local two-vote face lost to remote stronger group");
        select_groups(1,1,48);if(!found || x!=108 || votes!=9)$fatal(1,"single local window must not sustain target");
        select_groups(1,5,24);if(x!=32 || size!=24)$fatal(1,"allowed relative size change");
        select_groups(1,5,23);if(x!=108)$fatal(1,"excessive relative size change selected");
        rst=0;repeat(2)@(negedge clk);if(busy || done || found || timeout)$fatal(1,"reset");
        $display("PASS FACE SELECT V5: global acquisition, local priority over stronger foreign group, minimum local support, relative-size association, last-slot inclusion, scan-start hint snapshot/reset");$finish;
    end
endmodule
