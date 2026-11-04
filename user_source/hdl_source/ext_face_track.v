// V5: strict acquisition, scale-relative association and bounded motion coasting.
// Coasting is prediction, not an independent visual tracker or face evidence.
// 31,056,000 cycles at the nominal 103.52 MHz CSI clock = about 300 ms.
module ext_face_track #(
    parameter integer HOLD_CYCLES=31056000,
    parameter integer ACQUIRE_CYCLES=HOLD_CYCLES,
    parameter integer ENTRY_VOTES=5, CONTINUE_VOTES=2
)(input wire I_clk,I_rst_n,I_done,I_found,I_timeout,
    input wire [7:0] I_x,input wire [6:0] I_y,I_size,input wire [7:0] I_neighbors,
    output wire [31:0] O_status);
    reg visible,timeout_flag;
    reg [2:0] pending_hits;reg pending_weak,profile_gap;reg [1:0] misses,expand_hits;
    reg [7:0] ex;reg [6:0] ey,ew;
    // Stable face geometry, independent of each smoothed small-box update.
    reg [7:0] anchor_x;reg [6:0] anchor_y,anchor_w;
    reg [26:0] age;
    wire [26:0] deadline=visible?HOLD_CYCLES:ACQUIRE_CYCLES;
    reg [7:0] x,px,neighbors;
    reg [6:0] y,w,py,pw;
    reg signed [4:0] vx,vy;
    function [8:0] distance;
        input [8:0] a,b;
        begin distance=a>b?a-b:b-a;end
    endfunction
    function [7:0] average;
        input [7:0] a,b;reg [8:0] sum;
        begin sum={1'b0,a}+{1'b0,b};average=sum[8:1];end
    endfunction
    function signed [4:0] motion;
        input [7:0] a,b;reg signed [9:0] delta;
        begin
            delta=$signed({2'b0,a})-$signed({2'b0,b});
            if(delta>8)motion=5'sd4;else if(delta< -8)motion= -5'sd4;
            else motion=delta>>>1;
        end
    endfunction
    function [7:0] predict;
        input [7:0] position;input signed [4:0] velocity;input [7:0] limit;
        reg signed [9:0] sum;
        begin
            sum=$signed({2'b0,position})+velocity;
            if(sum<0)predict=0;else if(sum>$signed({2'b0,limit}))predict=limit;
            else predict=sum[7:0];
        end
    endfunction
    wire valid_box=I_size>=12 && I_size<=88 && {1'b0,I_x}+I_size<=160 && {2'b0,I_y}+I_size<=90;
    wire [8:0] nx={1'b0,I_x}+{3'b0,I_size[6:1]},ny={2'b0,I_y}+{3'b0,I_size[6:1]};
    wire [8:0] ox={1'b0,x}+{3'b0,w[6:1]},oy={2'b0,y}+{3'b0,w[6:1]};
    wire [8:0] qx={1'b0,px}+{3'b0,pw[6:1]},qy={2'b0,py}+{3'b0,pw[6:1]};
    wire pending_match=distance(nx,qx)<=({2'b0,pw}>>2)+2 &&
        distance(ny,qy)<=({2'b0,pw}>>2)+2 && distance({2'b0,I_size},{2'b0,pw})<=({2'b0,pw}>>2)+2;
    wire current_match=distance(nx,ox)<=({2'b0,w}>>1)+4 &&
        distance(ny,oy)<=({2'b0,w}>>1)+4 && distance({2'b0,I_size},{2'b0,w})<=({2'b0,w}>>1);
    wire expand_box=I_found && valid_box && !I_neighbors[7] && I_neighbors[6:0]>=ENTRY_VOTES &&
        I_size>({1'b0,w}+({1'b0,w}>>1)) && I_size<=({2'b0,w}+({2'b0,w}<<1)) &&
        I_x<=x && I_y<=y && {1'b0,I_x}+I_size>={1'b0,x}+w && {2'b0,I_y}+I_size>={2'b0,y}+w;
    wire expand_match=distance(nx,{1'b0,ex}+{3'b0,ew[6:1]})<=({2'b0,ew}>>2)+2 &&
        distance(ny,{2'b0,ey}+{3'b0,ew[6:1]})<=({2'b0,ew}>>2)+2 &&
        distance({2'b0,I_size},{2'b0,ew})<=({2'b0,ew}>>2)+2;
    // Reflections may produce an eye-only candidate far smaller than the face.
    // Reuse enlargement confirmation storage; weak abrupt shrink cannot update geometry.
    wire sudden_shrink={1'b0,I_size}+8'd2 < {1'b0,w}-({1'b0,w}>>2);
    wire [8:0] anchor_cx={1'b0,anchor_x}+{3'b0,anchor_w[6:1]};
    wire [8:0] anchor_cy={2'b0,anchor_y}+{3'b0,anchor_w[6:1]};
    wire [7:0] anchor_shrink_limit={1'b0,anchor_w}-({1'b0,anchor_w}>>2)-8'd2;
    wire cumulative_shrink={1'b0,I_size}<anchor_shrink_limit;
    wire anchor_contains={1'b0,I_x}+9'd2>={1'b0,anchor_x} && {2'b0,I_y}+9'd2>={2'b0,anchor_y} &&
        {1'b0,I_x}+I_size<={1'b0,anchor_x}+anchor_w+9'd2 &&
        {2'b0,I_y}+I_size<={2'b0,anchor_y}+anchor_w+9'd2;
    // A contained box moving towards the upper face can be a reflective lens
    // cluster. A confirmed profile or same-center distance change is different
    // evidence: neither is rejected solely because its scale is smaller.
    wire [8:0] anchor_upper_limit={2'b0,anchor_y}+({2'b0,anchor_w}>>1)-({2'b0,anchor_w}>>3);
    wire upper_shrink=!I_neighbors[7] && cumulative_shrink && anchor_contains &&
        ny<=anchor_upper_limit;
    wire centered_retreat=cumulative_shrink &&
        distance(nx,anchor_cx)<=({2'b0,anchor_w}>>4)+1 &&
        distance(ny,anchor_cy)<=({2'b0,anchor_w}>>4)+1;
    wire shrink_box=I_found && valid_box && I_neighbors[6:0]>=ENTRY_VOTES && current_match && sudden_shrink && !upper_shrink;
    wire resize_box=expand_box || shrink_box;
    wire expand_confirmed=resize_box && expand_hits==2 && expand_match;
    wire strong_entry=I_neighbors[6:0]>=ENTRY_VOTES;
    // Weak global profile clusters require five fresh consistent observations.
    // Frontal weak evidence still cannot acquire a new box.
    wire weak_profile_entry=I_neighbors[7] && I_neighbors[6:0]>=3;
    wire entry_confirmed=(pending_weak || !strong_entry)?pending_hits>=4:pending_hits>=2;
    wire accepted=I_found && valid_box && I_neighbors[6:0]>=CONTINUE_VOTES && current_match && !upper_shrink && (!sudden_shrink || expand_confirmed);
    assign O_status={visible,timeout_flag,x,y,w,neighbors};
    always @(posedge I_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin
            visible<=0;timeout_flag<=0;pending_hits<=0;profile_gap<=0;pending_weak<=0;misses<=0;expand_hits<=0;ex<=0;ey<=0;ew<=0;anchor_x<=0;anchor_y<=0;anchor_w<=0;age<=0;
            x<=0;y<=0;w<=0;px<=0;py<=0;pw<=0;neighbors<=0;vx<=0;vy<=0;
        end else begin
            if(I_done)begin
                timeout_flag<=I_timeout;
                if(visible && !I_timeout && resize_box && !accepted)begin
                    ex<=I_x;ey<=I_y;ew<=I_size;
                    if(expand_hits!=0 && expand_match)expand_hits<=expand_hits==2?0:expand_hits+1'b1;
                    else expand_hits<=1;
                end else expand_hits<=0;
            end
            if((visible || pending_hits!=0) && age<deadline-1)age<=age+1'b1;
            // Absolute clock deadline also works if no detector result arrives.
            if((visible || pending_hits!=0) && age>=deadline-1 && !(I_done && !I_timeout && (accepted || expand_confirmed)))begin
                visible<=0;pending_hits<=0;profile_gap<=0;misses<=0;neighbors<=0;vx<=0;vy<=0;
            end else if(I_done)begin
                if(I_timeout)begin
                    visible<=0;pending_hits<=0;profile_gap<=0;misses<=0;neighbors<=0;vx<=0;vy<=0;
                end else if(visible)begin
                    pending_hits<=0;profile_gap<=0;
                    if(expand_confirmed)begin
                        x<=I_x;y<=I_y;w<=I_size;neighbors<=I_neighbors;age<=0;misses<=0;vx<=0;vy<=0;
                        anchor_x<=I_x;anchor_y<=I_y;anchor_w<=I_size;
                    end else if(accepted)begin
                        // Follow real motion/growth, confirmed pose changes, or
                        // centered retreat; never walk the anchor down an
                        // incrementally shrinking upper-face/lens cluster.
                        if(I_neighbors[7] || I_size>=anchor_w || centered_retreat)begin
                            anchor_x<=I_x;anchor_y<=I_y;anchor_w<=I_size;
                        end
                        x<=average(x,I_x);y<=average({1'b0,y},{1'b0,I_y});w<=average({1'b0,w},{1'b0,I_size});
                        vx<=motion(I_x,x);vy<=motion({1'b0,I_y},{1'b0,y});
                        neighbors<=I_neighbors;misses<=0;age<=0;
                    end else begin
                        neighbors<=0;
                        // Foreign candidates cannot refresh age or replace a visible face.
                        if(misses==3)begin visible<=0;misses<=0;vx<=0;vy<=0;end
                        else begin
                            misses<=misses+1'b1;
                            x<=predict(x,vx,8'd160-{1'b0,w});
                            y<=predict({1'b0,y},vy,8'd90-{1'b0,w});
                            // Decay: at most three prediction steps per loss episode.
                            vx<=vx/2;vy<=vy/2;
                        end
                    end
                end else begin
                    misses<=0;neighbors<=0;vx<=0;vy<=0;
                    if(I_found && valid_box && (strong_entry || weak_profile_entry))begin
                        px<=I_x;py<=I_y;pw<=I_size;
                        if(pending_hits!=0 && pending_match)begin
                            if(entry_confirmed)begin
                                visible<=1;x<=I_x;y<=I_y;w<=I_size;neighbors<=I_neighbors;age<=0;pending_hits<=0;profile_gap<=0;
                                anchor_x<=I_x;anchor_y<=I_y;anchor_w<=I_size;
                            end else begin pending_hits<=pending_hits+1'b1;pending_weak<=pending_weak || !strong_entry;end
                        end else begin pending_hits<=1;pending_weak<=!strong_entry;profile_gap<=0;age<=0;end
                    end else if(!I_found && pending_hits!=0 && pending_weak && !profile_gap)profile_gap<=1;
                    else begin pending_hits<=0;profile_gap<=0;end
                end
            end
        end
    end
endmodule
