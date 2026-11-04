`timescale 1ns/1ps
module tb_face_lbp;
    reg clk=0,rst=0,start=0;always #5 clk=~clk;
    wire busy,done,found,timeout;wire [7:0] x,neighbors;wire [6:0] y,size;
    wire [13:0] address;reg [21:0] q;
    reg [21:0] memory[0:14399];reg [31:0] expected[0:10];reg [31:0] hits[0:255];reg [15:0] hit_counts[0:10];
    ext_face_lbp #(.ENABLE_PRIORITY(0)) dut(clk,rst,start,busy,done,found,timeout,x,y,size,neighbors,address,q,32'd0);
    always @(posedge clk)q<=memory[address];
    integer frame,cycles,hit_count,total_cycles=0;reg [3:0] previous_state=0;
    always @(posedge clk)begin
        previous_state=dut.state;
        #1;
        if(rst && busy && (dut.state==4 || dut.state==5) && (dut.corner_x>160 || dut.corner_y>90))$fatal(1,"corner out of bounds x=%0d y=%0d pass=%0d scale=%0d wx=%0d wy=%0d fx=%0d fy=%0d fw=%0d fh=%0d pc=%0d pr=%0d rpc=%0d rpr=%0d",dut.corner_x,dut.corner_y,dut.model_pass,dut.scale_index,dut.wx,dut.wy,dut.fx,dut.fy,dut.fw,dut.fh,dut.pc,dut.pr,dut.rpc,dut.rpr);
        if(rst && dut.state==dut.GROUP_READ && previous_state==dut.DECIDE)begin
            if(hit_count>=hit_counts[frame] || {5'd0,dut.model_pass,dut.wx,dut.wy,dut.win}!==hits[hit_count])$fatal(1,"raw hit stream mismatch frame=%0d hit=%0d",frame,hit_count);
            hit_count=hit_count+1;
        end
    end
    initial begin
        $readmemh("face_groups.hex",expected);$readmemh("face_hit_counts.hex",hit_counts);
        repeat(3)@(negedge clk);rst=1;
        for(frame=0;frame<11;frame=frame+1)begin
            case(frame)
                0:begin $readmemh("face_face_center_integral.hex",memory);$readmemh("face_face_center_hits.hex",hits);end
                1:begin $readmemh("face_face_left_integral.hex",memory);$readmemh("face_face_left_hits.hex",hits);end
                2:begin $readmemh("face_face_right_integral.hex",memory);$readmemh("face_face_right_hits.hex",hits);end
                3:begin $readmemh("face_blank_integral.hex",memory);$readmemh("face_blank_hits.hex",hits);end
                4:begin $readmemh("face_skin_flat_integral.hex",memory);$readmemh("face_skin_flat_hits.hex",hits);end
                5:begin $readmemh("face_noise_integral.hex",memory);$readmemh("face_noise_hits.hex",hits);end
                6:begin $readmemh("face_ramp_integral.hex",memory);$readmemh("face_ramp_hits.hex",hits);end
                7:begin $readmemh("face_profile_right_integral.hex",memory);$readmemh("face_profile_right_hits.hex",hits);end
                8:begin $readmemh("face_profile_left_integral.hex",memory);$readmemh("face_profile_left_hits.hex",hits);end
                9:begin $readmemh("face_profile_right_upside_integral.hex",memory);$readmemh("face_profile_right_upside_hits.hex",hits);end
                10:begin $readmemh("face_profile_left_upside_integral.hex",memory);$readmemh("face_profile_left_upside_hits.hex",hits);end
            endcase
            hit_count=0;cycles=0;
            @(negedge clk);start=1;@(negedge clk);start=0;
            while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>12000010)$fatal(1,"scan hangs");end
            if(timeout || found!==expected[frame][31] || neighbors!==expected[frame][7:0])$fatal(1,"group decision mismatch frame=%0d",frame);
            if(found && {x,y,size}!==expected[frame][29:8])$fatal(1,"group coordinates mismatch frame=%0d actual %0d %0d %0d",frame,x,y,size);
            if(hit_count!=hit_counts[frame])$fatal(1,"missing trained-classifier hits");
            $display("FACE SCENE frame=%0d found=%0d x=%0d y=%0d size=%0d votes=%0d cycles=%0d",frame,found,x,y,size,neighbors,cycles);
            total_cycles=total_cycles+cycles;repeat(3)@(negedge clk);
        end
        $display("PASS FACE LBP: 11 full integral scenes, actual trained 20-stage cascade, all raw hit positions/order and grouped results match independent Q12 reference; float comparison logged separately, including quantized early-exit differences; 3 frontal placements, normal/upside-down left/right profiles and 4 negatives; cycles=%0d",total_cycles);$finish;
    end
    initial begin #1200000000;$fatal(1,"timeout");end
endmodule
