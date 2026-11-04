// Capture 160x90 gray samples from a four-pixel 1280x720 stream.
// Only one low-resolution integral frame is stored; capture and scan alternate.
// Busy detector frames are skipped without affecting video valid or readiness.
module ext_face_detector #(parameter integer ENABLE_ZOOM=1, RECOVERY_CYCLES=62112000, ENABLE_PREFILTER=0, ENABLE_LARGE=1, ENABLE_HIGHLIGHT=0)(input wire I_clk,I_rst_n,input wire [95:0] I_gray,
    input wire I_valid,I_sof,output wire [31:0] O_status);
    reg [8:0] col;reg [9:0] row;
    wire [8:0] cc=I_sof?9'd0:col;
    wire [9:0] rr=I_sof?10'd0:row;
    reg [31:0] relocate_hint;reg [1:0] relocate_left;
    reg capture;reg pending_hint_gap;reg [31:0] pending_hint;reg [2:0] refresh;
    // Recently lost ROI is search memory only. It never drives the overlay or
    // bypasses the tracker's three fresh, strong, consistent confirmations.
    reg [31:0] recovery_hint;
    reg [26:0] recovery_age;
    reg [1:0] recovery_attempts;
    reg recovery_scan;
    wire using_recovery=!O_status[31] && !pending_hint[31] && recovery_hint[31] &&
        recovery_age<RECOVERY_CYCLES && recovery_attempts<2;
    wire [31:0] global_hint=relocate_left!=0?relocate_hint:(O_status[31]?O_status:(pending_hint[31]?pending_hint:(using_recovery?recovery_hint:32'd0)));
    reg zoom,next_zoom;reg [6:0] crop_x,crop_y;
    // V11: occasional true full-view search escapes a small local false lock.
    // Latched at SOF: the search field and hint must remain paired throughout capture.
    reg large_scan,prefer_large,last_large,wide_large;
    reg wide_scan,filter_capture,prefer_filter;reg [1:0] empty_scans;
    wire request_wide=O_status[31] && refresh==7;
    wire request_large=ENABLE_LARGE && (request_wide?wide_large:
        (global_hint[31]?(last_large && !global_hint[7] && global_hint[14:8]>=72):prefer_large));
    (* ram_style="dram" *) reg [11:0] area_sum[0:159];
    reg [3:0] tile_index;
    function [6:0] tile_x;input [3:0] tile;begin
        case(tile)1,4,6:tile_x=0;3,5,8:tile_x=80;default:tile_x=40;endcase
    end endfunction
    function [6:0] tile_y;input [3:0] tile;begin
        case(tile)1,2,3:tile_y=0;6,7,8:tile_y=45;default:tile_y=22;endcase
    end endfunction
    wire [7:0] hint_cx={1'b0,global_hint[29:22]}+{1'b0,global_hint[14:9]};
    wire [7:0] hint_cy={1'b0,global_hint[21:15]}+{1'b0,global_hint[14:9]};
    wire [6:0] next_crop_x=hint_cx<=40?0:(hint_cx>=120?80:hint_cx-40);
    wire [6:0] next_crop_y=hint_cy<=22?0:(hint_cy>=67?45:hint_cy-22);
    // V9: restore detail for 24..32-cell faces after their first full-view hit.
    // Hysteresis retains zoom through width40; bigger faces use the full field.
    wire choose_zoom=ENABLE_ZOOM && (global_hint[31]?(zoom?global_hint[14:8]<=40:global_hint[14:8]<=32):next_zoom);
    wire hint_inside=global_hint[29:22]>=crop_x && global_hint[21:15]>=crop_y &&
        {1'b0,global_hint[29:22]}+global_hint[14:8]<=crop_x+80 &&
        {2'b0,global_hint[21:15]}+global_hint[14:8]<=crop_y+45;
    wire [7:0] local_hint_x=(global_hint[29:22]-crop_x)<<1;
    wire [6:0] local_hint_y=(global_hint[21:15]-crop_y)<<1;
    wire [6:0] local_hint_w=global_hint[14:8]<<1;
    wire [31:0] converted_hint=zoom?(hint_inside?{global_hint[31:30],local_hint_x,local_hint_y,local_hint_w,global_hint[7:0]}:32'd0):global_hint;
    wire [31:0] base_hint=wide_scan?32'd0:(O_status[31] && O_status[6:0]!=0 && refresh==0?32'd0:converted_hint);
    wire [6:0] virtual_hint_y=base_hint[21:15]+7'd19;
    wire [31:0] scan_hint=large_scan?{base_hint[31],1'b1,base_hint[29:22],virtual_hint_y,base_hint[14:0]}:base_hint;
    reg [1:0] phase;reg valid1,valid2,last1,last2;reg [7:0] sample_x1;
    (* ram_style="distributed" *) reg [21:0] previous_row[0:159];
    reg [21:0] integral2;reg [13:0] address1;
    reg [15:0] prefix,pending_prefix;
    reg [13:0] read_address,write_address;
    reg first_row,last_sample,start;
    wire busy,done,found,timeout;
    wire [7:0] box_x,neighbors;wire [6:0] box_y,box_size;
    wire [13:0] scan_address;wire [21:0] ram_data;
    wire [9:0] local_row=rr-{crop_y,3'b0};
    wire [8:0] local_col=cc-{crop_x,1'b0};
    wire [6:0] sy=zoom?local_row[8:2]:rr[9:3];wire [7:0] sx=zoom?local_col[7:0]:cc[8:1];
    wire zoom_sample=rr>={crop_y,3'b0} && rr<{crop_y,3'b0}+360 &&
        cc>={crop_x,1'b0} && cc<{crop_x,1'b0}+160 && local_row[1:0]==3;
    wire sample=I_valid && capture && (zoom?zoom_sample:(rr[2:0]==3 && !cc[0]));
    // Four horizontal pixels over four rows. A fresh first row overwrites old
    // sums, so no RAM clear/reset and no stale-frame contribution is possible.
    wire in_field=zoom?(rr>={crop_y,3'b0} && rr<{crop_y,3'b0}+360 &&
        cc>={crop_x,1'b0} && cc<{crop_x,1'b0}+160):(!cc[0] && rr[2:0]<4);
    wire area_write=I_valid && capture && ENABLE_PREFILTER && filter_capture && in_field;
    wire [1:0] area_row=zoom?local_row[1:0]:rr[1:0];
    wire [9:0] horizontal={2'd0,I_gray[95:88]}+{2'd0,I_gray[71:64]}+
        {2'd0,I_gray[47:40]}+{2'd0,I_gray[23:16]};
    wire [11:0] area_next=area_row==0?{2'd0,horizontal}:area_sum[sx]+{2'd0,horizontal};
    wire [12:0] rounded_area={1'b0,area_next}+13'd8;
    wire [7:0] trial_pixel=ENABLE_PREFILTER?rounded_area[11:4]:I_gray[23:16];
    // Compress only the retry image's saturated highlights, not the display.
    wire [7:0] knee_pixel=trial_pixel>192?8'd192+((trial_pixel-8'd192)>>2):trial_pixel;
    wire [7:0] capture_pixel=filter_capture?(ENABLE_HIGHLIGHT?knee_pixel:trial_pixel):I_gray[23:16];
    always @(posedge I_clk)if(area_write)area_sum[sx]<=area_next;
    wire [15:0] new_prefix=sx==0?{8'd0,capture_pixel}:prefix+{8'd0,capture_pixel};
    wire [13:0] y_address=({7'd0,sy}<<7)+({7'd0,sy}<<5);
    wire [21:0] above=first_row?22'd0:previous_row[sample_x1];
    wire [21:0] sum2=above+{6'd0,pending_prefix};
    wire [13:0] address=busy?scan_address:write_address;
    ext_face_integral_ram image_ram(I_clk,I_rst_n && valid2 && !busy,address,integral2,ram_data);
    always @(posedge I_clk)if(valid1)previous_row[sample_x1]<=sum2;
    ext_face_lbp classifier(I_clk,I_rst_n,start,busy,done,found,timeout,box_x,box_y,box_size,neighbors,scan_address,ram_data,scan_hint);
    wire [6:0] clipped_size=box_size>88?7'd88:box_size;
    wire [7:0] large_x=box_x+((box_size-clipped_size)>>1);
    wire [6:0] large_y0=box_y<19?0:box_y-7'd19;
    wire [6:0] large_y=large_y0>90-clipped_size?90-clipped_size:large_y0;
    wire [7:0] mapped_x=large_scan?large_x:(zoom?{1'b0,crop_x}+{1'b0,box_x[7:1]}:box_x);
    wire [6:0] mapped_y=large_scan?large_y:(zoom?crop_y+{1'b0,box_y[6:1]}:box_y);
    wire [7:0] enlarged_size={1'b0,box_size}+1'b1;
    wire [6:0] mapped_size=large_scan?clipped_size:(zoom?enlarged_size[7:1]:box_size);
    // Only a fresh full-field frontal result enclosing the current small box
    // may propose enlargement. The tracker still needs three consistent hits.
    wire larger_enclosing=O_status[31] && !zoom && found && !timeout && !neighbors[7] && neighbors[6:0]>=5 &&
        mapped_size>({1'b0,O_status[14:8]}+({1'b0,O_status[14:8]}>>1)) &&
        mapped_size<=({2'b0,O_status[14:8]}+({2'b0,O_status[14:8]}<<1)) &&
        mapped_x<=O_status[29:22] && mapped_y<=O_status[21:15] &&
        {1'b0,mapped_x}+mapped_size>={1'b0,O_status[29:22]}+O_status[14:8] &&
        {2'b0,mapped_y}+mapped_size>={2'b0,O_status[21:15]}+O_status[14:8];
    // Register the complete mapped result before the tracker. Virtual near-face
    // clipping and tracker consistency arithmetic must not share one cycle.
    // This adds one clock (9.66 ns), not a frame or another confirmation.
    reg track_done,track_found,track_timeout,track_filter;
    reg retry_check,retry_filter;
    reg [7:0] track_x,track_neighbors;reg [6:0] track_y,track_size;
    wire track_local_shrink=track_size<O_status[14:8] &&
        {1'b0,track_x}+9'd2>={1'b0,O_status[29:22]} &&
        {2'b0,track_y}+9'd2>={2'b0,O_status[21:15]} &&
        {1'b0,track_x}+track_size<={1'b0,O_status[29:22]}+O_status[14:8]+9'd2 &&
        {2'b0,track_y}+track_size<={2'b0,O_status[21:15]}+O_status[14:8]+9'd2;
    always @(posedge I_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin
            track_done<=0;track_found<=0;track_timeout<=0;track_filter<=0;
            track_x<=0;track_y<=0;track_size<=0;track_neighbors<=0;
        end else begin
            track_done<=done;
            if(done)begin
                track_found<=found;track_timeout<=timeout;track_filter<=filter_capture;track_x<=mapped_x;
                track_y<=mapped_y;track_size<=mapped_size;track_neighbors<=neighbors;
            end
        end
    end
    ext_face_track #(.ACQUIRE_CYCLES(103520000)) tracker(I_clk,I_rst_n,track_done,track_found,track_timeout,track_x,track_y,track_size,track_neighbors,O_status);
    always @(posedge I_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin
            col<=0;row<=0;capture<=0;retry_check<=0;retry_filter<=0;large_scan<=0;wide_large<=0;prefer_large<=0;last_large<=0;relocate_hint<=0;relocate_left<=0;wide_scan<=0;filter_capture<=0;prefer_filter<=0;empty_scans<=0;pending_hint<=0;pending_hint_gap<=0;refresh<=0;recovery_hint<=0;recovery_age<=RECOVERY_CYCLES;recovery_attempts<=0;recovery_scan<=0;zoom<=0;next_zoom<=0;crop_x<=40;crop_y<=22;tile_index<=0;phase<=0;prefix<=0;pending_prefix<=0;
            read_address<=0;write_address<=0;first_row<=1;last_sample<=0;start<=0;
            valid1<=0;valid2<=0;last1<=0;last2<=0;sample_x1<=0;integral2<=0;address1<=0;
        end else begin
            start<=0;
            // Observe the tracker's registered decision one clock after it has
            // consumed this result. Strong rejected geometry is not successful
            // face support even when the classifier returned many neighbors.
            // Restrict recovery to a smaller contained candidate, so a foreign
            // full-field face cannot alter this track's photometric schedule.
            retry_check<=track_done && track_found && !track_timeout &&
                track_neighbors[6:0]>=5 && O_status[31] && track_local_shrink;
            if(track_done)retry_filter<=track_filter;
            if(ENABLE_HIGHLIGHT && retry_check && O_status[6:0]==0)prefer_filter<=!retry_filter;
            if(start)refresh<=refresh+1'b1;
            if(O_status[31])pending_hint_gap<=0;
            if(O_status[31] && O_status[6:0]!=0)begin
                // Zero support forces a frontal-first retry on remembered ROI.
                recovery_hint<={O_status[31:8],8'd0};
                recovery_age<=0;recovery_attempts<=0;
            end else if(recovery_age<RECOVERY_CYCLES)recovery_age<=recovery_age+1'b1;
            if(done)begin
                // A weak profile may also be damaged by lens highlights.
                // Alternate only the input image; search field/cost are unchanged.
                if(ENABLE_HIGHLIGHT && (timeout || !found || neighbors[6:0]<5))prefer_filter<=!filter_capture;
                if(found && !timeout && neighbors[6:0]>=5)begin
                    if(large_scan)last_large<=1;
                    else if(neighbors[7] || mapped_size<72)last_large<=0;
                end
                // Near mode is frontal-only. A failed/weak near scan must release
                // that mode so ordinary profile passes can evaluate the face.
                if(large_scan && !(found && !timeout && neighbors[6:0]>=5))last_large<=0;
                if(relocate_left!=0)begin
                    if(found && !timeout && neighbors[6:0]>=5)relocate_left<=relocate_left-1'b1;
                    else relocate_left<=0;
                end else if(wide_scan && larger_enclosing)begin
                    relocate_hint<={1'b1,1'b0,mapped_x,mapped_y,mapped_size,neighbors};relocate_left<=2;
                end
                // Preserve raw first-entry behavior. Try the filtered input only
                // after two empty scans; retain it after a supported detection.
                if(found && !timeout && neighbors[6:0]>=5)empty_scans<=0;
                else if(!O_status[31] && !pending_hint[31])begin
                    if(empty_scans==1)begin empty_scans<=0;prefer_filter<=!prefer_filter;prefer_large<=!prefer_large;end
                    else empty_scans<=empty_scans+1'b1;
                end
                if(recovery_scan && recovery_attempts<2)recovery_attempts<=recovery_attempts+1'b1;
                if(zoom && !O_status[31] && !pending_hint[31] && !recovery_scan && !(found && !timeout && neighbors[6:0]>=5))
                    tile_index<=tile_index==8?0:tile_index+1'b1;
                if(found && !timeout && (neighbors[6:0]>=5 || (neighbors[7] && neighbors[6:0]>=3)))begin
                    pending_hint<={1'b1,1'b0,mapped_x,mapped_y,mapped_size,neighbors};
                    if(!pending_hint[31] || !pending_hint[7] || !neighbors[7])pending_hint_gap<=0;
                end else if(!timeout && !found && !O_status[31] && pending_hint[31] && pending_hint[7] && !pending_hint_gap)begin
                    // One failed observation may not discard a weak profile's search ROI.
                    // This memory never drives visibility; the tracker still needs5 hits.
                    pending_hint_gap<=1;
                end else begin pending_hint<=0;pending_hint_gap<=0;end
            end
            if(I_sof)begin
                col<=0;row<=0;capture<=!busy && phase==0 && !start;prefix<=0;
                if(!busy && phase==0 && !start)begin
                    if(request_wide)wide_large<=!wide_large;
                    zoom<=(request_wide || request_large)?1'b0:choose_zoom;large_scan<=request_large;wide_scan<=request_wide;filter_capture<=(ENABLE_PREFILTER || ENABLE_HIGHLIGHT) && prefer_filter;recovery_scan<=using_recovery;
                    crop_x<=global_hint[31]?next_crop_x:tile_x(tile_index);
                    crop_y<=global_hint[31]?next_crop_y:tile_y(tile_index);
                end
            end
            if(I_valid)begin
                if(cc==319)begin col<=0;row<=rr==719?0:rr+1'b1;end else col<=cc+1'b1;
            end
            // Streaming capture: one sample/clock. A small previous-row LUT RAM
            // supplies the vertical prefix; the full integral ERAM only writes.
            valid1<=sample;valid2<=valid1;
            phase<=valid1?2:(sample?1:0);
            if(valid1)begin integral2<=sum2;write_address<=address1;last2<=last1;end
            if(valid2 && last2)begin start<=1;next_zoom<=!zoom;end
            if(sample)begin
                prefix<=new_prefix;pending_prefix<=new_prefix;
                sample_x1<=sx;address1<=y_address+sx;first_row<=sy==0;
                last1<=sy==89 && sx==159;
                if(sy==89 && sx==159)capture<=0;
            end
        end
    end
endmodule
