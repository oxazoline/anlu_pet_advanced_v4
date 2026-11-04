// Complete OpenCV 20-stage block-LBP cascade, serial hardware evaluator.
// Eight approximate feature scales; no CPU, skin gate, or video backpressure.
// Corner sums share one RAM port and one arithmetic datapath.
module ext_face_lbp #(
    parameter integer WIDTH=160,HEIGHT=90,STRIDE=2,MAX_CYCLES=12000000,ENABLE_PRIORITY=1
)(input wire I_clk,I_rst_n,I_start,
    output reg O_busy,O_done,O_found,O_timeout,
    output reg [7:0] O_x,output reg [6:0] O_y,O_size,
    output reg [7:0] O_neighbors,
    output wire [13:0] O_address,input wire [21:0] I_integral,
    input wire [31:0] I_hint);
    localparam IDLE=0,WINDOW_START=1,META_WAIT=2,GEOMETRY=3,
        POINT_REQ=4,POINT_GET=5,LBP_BITS=6,SUB_WAIT=7,SUB_ADD=8,
        DECIDE=9,NEXT_WINDOW=10,GROUP=11,RESULT=12,PUBLISH=13,
        GROUP_READ=14,RESULT_READ=15;
    reg [3:0] state;reg [2:0] model_pass;reg large_mode;
    reg [1:0] profile_phase,profile_phase_active;
    wire [7:0] profile_x0=ENABLE_PRIORITY?{7'd0,profile_phase_active[0]}:8'd0;
    wire [7:0] profile_y0=ENABLE_PRIORITY?{7'd0,profile_phase_active[1]}:8'd0;
    // A weak local frontal result may not starve profile evidence. Probe one
    // direction, then publish the saved geometry if the probe is not stronger.
    reg weak_probe_active;reg [2:0] weak_probe_pass;
    reg [7:0] weak_count,weak_x,weak_y,weak_w;
    wire [7:0] scan_height=large_mode?8'd128:HEIGHT;
    // Every pass is evaluated at most once. A known direction is first for a
    // hinted target. Global and unsupported/coasting targets always try frontal
    // first; only the following profile order rotates. No loss of frontal budget.
    reg [2:0] pass_rank,priority_pass,search_priority,remembered_pass;
    wire [2:0] probe_pass=remembered_pass!=0?remembered_pass:weak_probe_pass;

    reg [1:0] frontal_probe_count;reg frontal_probe_first;
    wire frontal_probe_due=ENABLE_PRIORITY && I_hint[31] && remembered_pass!=0 && frontal_probe_count[0];
    wire [2:0] starting_pass=ENABLE_PRIORITY?(I_hint[31]?remembered_pass:search_priority):3'd0;
    wire frontal_first=ENABLE_PRIORITY && (!I_hint[31] || I_hint[6:0]==0 || frontal_probe_due);
    function [2:0] ordered_pass;
        input [2:0] priority_id,rank_id;
        begin
            if(priority_id==0)ordered_pass=rank_id;
            else if(rank_id==0)ordered_pass=priority_id;
            else if(rank_id==1)ordered_pass=0;
            else ordered_pass=rank_id<=priority_id?rank_id-1'b1:rank_id;
        end
    endfunction
    wire profile=model_pass!=0;
    wire mirror_x=model_pass==2 || model_pass==4,mirror_y=model_pass==3 || model_pass==4;
    reg [23:0] cycles;
    reg [2:0] scale_index;
    reg [7:0] wx,wy,node;
    reg [4:0] stage;
    reg signed [17:0] stage_sum;
    wire [7:0] stage_end;wire signed [17:0] stage_threshold;
    ext_face_stage_rom stage_info(stage,stage_end,stage_threshold,profile);
    wire [47:0] meta;
    ext_face_feature_rom feature_info(I_clk,{profile,node},meta);
    reg [6:0] fx,fy,fw,fh;
    reg [1:0] geom,pc,pr,rpc,rpr,request_pc,request_pr,point_valid;
    reg issued_last,zero_request;
    reg [7:0] window_pad,window_ex,window_ey;
    reg flip_x,flip_y;reg [8:0] origin_x,origin_y,address_x,address_y;
    reg [4:0] base_coordinate;
    always @(*)case(geom)
        0:base_coordinate=meta[47:43];1:base_coordinate=meta[42:38];
        2:base_coordinate=meta[37:33];default:base_coordinate=meta[32:28];
    endcase
    function [7:0] window_size;
        input [2:0] s;input prof;
        begin if(large_mode)window_size=8'd72+({5'd0,s}<<2)+({5'd0,s}<<1);else if(prof)case(s)
0:window_size=34;1:window_size=42;2:window_size=51;3:window_size=59;4:window_size=68;5:window_size=85;6:window_size=102;default:window_size=119;endcase
else case(s)0:window_size=24;1:window_size=30;2:window_size=36;
            3:window_size=42;4:window_size=48;5:window_size=60;
            6:window_size=72;default:window_size=84;endcase end
    endfunction
    function [6:0] scaled;
        input [4:0] n;input [2:0] s;reg [9:0] v;
        begin
            v={5'b0,n};
            if(large_mode)case(s)
0:scaled=(v<<1)+v;
1:scaled=((v<<3)+(v<<2)+v+2)>>2;
2:scaled=((v<<3)+(v<<2)+(v<<1)+2)>>2;
3:scaled=((v<<4)-v+2)>>2;
4:scaled=v<<2;
5:scaled=((v<<4)+v+2)>>2;
6:scaled=((v<<4)+(v<<1)+2)>>2;
default:scaled=((v<<4)+(v<<1)+v+2)>>2;endcase
            else case(s)
                0:scaled=v;
                1:scaled=((v<<2)+v+2)>>2;
                2:scaled=((v<<1)+v+1)>>1;
                3:scaled=((v<<2)+(v<<1)+v+2)>>2;
                4:scaled=v<<1;
                5:scaled=((v<<2)+v+1)>>1;
                6:scaled=(v<<1)+v;
                default:scaled=((v<<2)+(v<<1)+v+1)>>1;
            endcase
        end
    endfunction
    function [8:0] offset3;
        input [6:0] v;input [1:0] n;
        begin case(n)0:offset3=0;1:offset3=v;2:offset3={v,1'b0};
            default:offset3={v,1'b0}+v;endcase end
    endfunction
    function [7:0] extent_x;input [2:0] s;input prof;begin if(large_mode)case(s)3'd0:extent_x=8'd72;3'd1:extent_x=8'd80;3'd2:extent_x=8'd86;3'd3:extent_x=8'd92;3'd4:extent_x=8'd96;3'd5:extent_x=8'd104;3'd6:extent_x=8'd110;3'd7:extent_x=8'd116;endcase else case({prof,s})
4'd0:extent_x=8'd24;
4'd1:extent_x=8'd32;
4'd2:extent_x=8'd38;
4'd3:extent_x=8'd44;
4'd4:extent_x=8'd48;
4'd5:extent_x=8'd62;
4'd6:extent_x=8'd72;
4'd7:extent_x=8'd86;
4'd8:extent_x=8'd20;
4'd9:extent_x=8'd27;
4'd10:extent_x=8'd32;
4'd11:extent_x=8'd37;
4'd12:extent_x=8'd40;
4'd13:extent_x=8'd52;
4'd14:extent_x=8'd60;
4'd15:extent_x=8'd72;
default:extent_x=0;endcase end endfunction
    function [7:0] extent_y;input [2:0] s;input prof;begin if(large_mode)case(s)3'd0:extent_y=8'd72;3'd1:extent_y=8'd80;3'd2:extent_y=8'd86;3'd3:extent_y=8'd92;3'd4:extent_y=8'd96;3'd5:extent_y=8'd104;3'd6:extent_y=8'd110;3'd7:extent_y=8'd116;endcase else case({prof,s})
4'd0:extent_y=8'd24;
4'd1:extent_y=8'd32;
4'd2:extent_y=8'd38;
4'd3:extent_y=8'd44;
4'd4:extent_y=8'd48;
4'd5:extent_y=8'd62;
4'd6:extent_y=8'd72;
4'd7:extent_y=8'd86;
4'd8:extent_y=8'd34;
4'd9:extent_y=8'd44;
4'd10:extent_y=8'd53;
4'd11:extent_y=8'd61;
4'd12:extent_y=8'd68;
4'd13:extent_y=8'd87;
4'd14:extent_y=8'd102;
4'd15:extent_y=8'd121;
default:extent_y=0;endcase end endfunction
    function [7:0] nominal_width;input [2:0] s;input prof;begin
 if(!prof)nominal_width=window_size(s,prof);else case(s)
 0:nominal_width=20;1:nominal_width=25;2:nominal_width=30;3:nominal_width=35;
 4:nominal_width=40;5:nominal_width=50;6:nominal_width=60;default:nominal_width=70;endcase
 end endfunction
 function [7:0] limit_x;input [2:0] s;input prof;reg [7:0] a,b;
 begin a=window_size(s,prof);b=((a-nominal_width(s,prof))>>1)+extent_x(s,prof);limit_x=a>b?a:b;end endfunction
 function [7:0] limit_y;input [2:0] s;input prof;reg [7:0] a,b;
 begin a=window_size(s,prof);b=extent_y(s,prof);limit_y=a>b?a:b;end endfunction
    wire [7:0] win=window_size(scale_index,profile);
    wire [7:0] xpad=(win-nominal_width(scale_index,profile))>>1;
    // Three short datapaths: per-window geometry, registered corner, ERAM address.
    wire [8:0] corner_x=flip_x?origin_x-offset3(fw,pc):origin_x+offset3(fw,pc);
    wire [8:0] corner_y=flip_y?origin_y-offset3(fh,pr):origin_y+offset3(fh,pr);
    wire [8:0] physical_y=large_mode?(address_y<=19?9'd0:(address_y>=109?9'd90:address_y-9'd19)):address_y;
    wire [13:0] yy=physical_y-1'b1;
    assign O_address=address_x==0 || physical_y==0 ? 14'd0 : (yy<<7)+(yy<<5)+address_x-1'b1;
    reg zero_corner;
    wire [21:0] corner=zero_corner?22'd0:I_integral;
    reg [21:0] top[0:3];reg [21:0] top_left,bottom_left;
    reg [18:0] cells[0:8];
    reg [2:0] bit_index;reg [7:0] lbp;
    reg [3:0] neighbor_index;
    always @(*)case(bit_index)
        0:neighbor_index=0;1:neighbor_index=1;2:neighbor_index=2;3:neighbor_index=5;
        4:neighbor_index=8;5:neighbor_index=7;6:neighbor_index=6;default:neighbor_index=3;
    endcase
    wire [31:0] subset;
    ext_face_subset_rom subset_info(I_clk,{profile,node,lbp[7:5]},subset);
    wire signed [13:0] leaf=subset[lbp[4:0]]?$signed(meta[27:14]):$signed(meta[13:0]);
    // Bounded online neighbor groups. Counts are votes, not probabilities.
    reg [7:0] cx[0:7],cy[0:7],cw[0:7],count[0:7];
    reg [2:0] ci,min_index;
    // One shared registered read of the eight small cluster slots. Keep the
    // indexed mux out of near-group/near-hint decisions and array write enables.
    reg [7:0] group_x,group_y,group_w,group_count;
    reg [7:0] min_count,candidate_x,candidate_y;
    reg [7:0] best_count,best_x,best_y,best_w;
    reg [7:0] local_count,local_x,local_y,local_w;
    reg hint_valid;reg [7:0] hint_x,hint_y,hint_w;
    wire [8:0] hint_center_x={1'b0,hint_x}+({1'b0,hint_w}>>1);
    wire [8:0] hint_center_y={1'b0,hint_y}+({1'b0,hint_w}>>1);
    // Candidate proximity uses the same center/size limits as maintenance.
    wire near_hint=hint_valid &&
        distance(group_x,hint_center_x[7:0])<=({1'b0,hint_w}>>1)+4 &&
        distance(group_y,hint_center_y[7:0])<=({1'b0,hint_w}>>1)+4 &&
        distance(group_w,hint_w)<=({1'b0,hint_w}>>1);
    wire use_local=hint_valid && local_count>=2;
    wire [7:0] observed_count=use_local?local_count:best_count;
    wire use_weak_fallback=weak_probe_active && observed_count<5;
    wire [7:0] result_count=use_weak_fallback?weak_count:observed_count;
    wire [7:0] result_x=use_weak_fallback?weak_x:(use_local?local_x:best_x);
    wire [7:0] result_y=use_weak_fallback?weak_y:(use_local?local_y:best_y);
    wire [7:0] result_w=use_weak_fallback?weak_w:(use_local?local_w:best_w);
    wire [7:0] profile_entry_min=(!hint_valid && profile_phase_active!=0)?8'd4:8'd3;
    wire publish_found=result_count>=((use_local || use_weak_fallback)?8'd2:((ENABLE_PRIORITY && profile)?profile_entry_min:8'd3));
    wire [2:0] next_model_pass=frontal_probe_first && pass_rank==0?priority_pass:ordered_pass(priority_pass,pass_rank+3'd1);
    wire [2:0] chosen_index=group_count<min_count?ci:min_index;
    wire [7:0] chosen_count=group_count<min_count?group_count:min_count;
    function [7:0] distance;
        input [7:0] a,b;
        begin distance=a>b?a-b:b-a;end
    endfunction
    function [7:0] smooth;
        input [7:0] old_value,new_value;reg [9:0] v;
        begin v=({2'b0,old_value}<<1)+old_value+new_value+2;smooth=v[9:2];end
    endfunction
    wire [8:0] combined_width={1'b0,win}+{1'b0,group_w};
    wire near_group=distance(candidate_x,group_x)<=((combined_width>>3)+2) &&
        distance(candidate_y,group_y)<=((combined_width>>3)+2) && distance(win,group_w)<=(group_w>>1);
    integer n;
    always @(posedge I_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin
            O_busy<=0;O_done<=0;O_found<=0;O_timeout<=0;O_x<=0;O_y<=0;O_size<=0;O_neighbors<=0;
            state<=IDLE;profile_phase<=0;profile_phase_active<=0;model_pass<=0;large_mode<=0;weak_probe_active<=0;weak_probe_pass<=1;weak_count<=0;weak_x<=0;weak_y<=0;weak_w<=0;pass_rank<=0;priority_pass<=0;search_priority<=1;remembered_pass<=0;frontal_probe_count<=0;frontal_probe_first<=0;rpc<=0;rpr<=0;cycles<=0;scale_index<=0;wx<=0;wy<=0;node<=0;stage<=0;stage_sum<=0;
            geom<=0;fx<=0;fy<=0;fw<=0;fh<=0;pc<=0;pr<=0;zero_corner<=1;
            request_pc<=0;request_pr<=0;point_valid<=0;issued_last<=0;zero_request<=1;
            window_pad<=0;window_ex<=0;window_ey<=0;flip_x<=0;flip_y<=0;
            origin_x<=0;origin_y<=0;address_x<=0;address_y<=0;
            top_left<=0;bottom_left<=0;bit_index<=0;lbp<=0;
            ci<=0;min_index<=0;min_count<=0;candidate_x<=0;candidate_y<=0;
            group_x<=0;group_y<=0;group_w<=0;group_count<=0;
            best_count<=0;best_x<=0;best_y<=0;best_w<=0;
            local_count<=0;local_x<=0;local_y<=0;local_w<=0;
            hint_valid<=0;hint_x<=0;hint_y<=0;hint_w<=0;
            for(n=0;n<8;n=n+1)begin cx[n]<=0;cy[n]<=0;cw[n]<=0;count[n]<=0;end
        end else begin
            O_done<=0;
            if(O_busy)cycles<=cycles+1'b1;
            if(O_busy && cycles>=MAX_CYCLES-1)begin
                O_busy<=0;O_done<=1;O_found<=0;O_timeout<=1;O_neighbors<=0;state<=IDLE;
                if(ENABLE_PRIORITY && !hint_valid && !large_mode)profile_phase<=profile_phase+1'b1;
            end else case(state)
                IDLE:if(I_start)begin
                    O_busy<=1;O_timeout<=0;weak_probe_active<=0;large_mode<=I_hint[30];model_pass<=I_hint[30]?3'd0:(frontal_first?3'd0:starting_pass);priority_pass<=starting_pass;frontal_probe_first<=frontal_first && starting_pass!=0;pass_rank<=I_hint[30]?3'd4:3'd0;cycles<=0;
                    if(I_hint[31])frontal_probe_count<=frontal_probe_count+1'b1;else frontal_probe_count<=0;
                    profile_phase_active<=profile_phase;
                    if(ENABLE_PRIORITY && !I_hint[31])search_priority<=search_priority==4?1:search_priority+1'b1;scale_index<=0;wx<=(!I_hint[30] && !frontal_first && starting_pass!=0)?{7'd0,profile_phase[0]}:8'd0;wy<=(!I_hint[30] && !frontal_first && starting_pass!=0)?{7'd0,profile_phase[1]}:8'd0;state<=WINDOW_START;
                    hint_valid<=I_hint[31];hint_x<=I_hint[29:22];hint_y<={1'b0,I_hint[21:15]};hint_w<={1'b0,I_hint[14:8]};
                    for(n=0;n<8;n=n+1)count[n]<=0;
                end
                WINDOW_START:begin
 window_pad<=xpad;window_ex<=extent_x(scale_index,profile);window_ey<=extent_y(scale_index,profile);
 flip_x<=mirror_x;flip_y<=mirror_y;
 node<=0;stage<=0;stage_sum<=0;
 if(hint_valid && (distance(wx+(win>>1),hint_center_x[7:0])>(hint_w>>1)+4 ||
 distance(wy+(win>>1),hint_center_y[7:0])>(hint_w>>1)+4 ||
 distance(win,hint_w)>(hint_w>>1)))state<=NEXT_WINDOW;
 else state<=META_WAIT;
 end
                META_WAIT:begin geom<=0;state<=GEOMETRY;end
                GEOMETRY:begin
                    case(geom)0:fx<=scaled(base_coordinate,scale_index);1:fy<=scaled(base_coordinate,scale_index);
                        2:fw<=scaled(base_coordinate,scale_index);3:fh<=scaled(base_coordinate,scale_index);endcase
                    if(geom==3)begin
                        origin_x<=flip_x?{1'b0,wx}+window_pad+window_ex-fx:{1'b0,wx}+window_pad+fx;
                        origin_y<=flip_y?{1'b0,wy}+window_ey-fy:{1'b0,wy}+fy;
                        pc<=0;pr<=0;state<=POINT_REQ;
                    end else geom<=geom+1'b1;
                end
                // Registered corners add one initial fill clock; thereafter one
                // corner request/clock. Two delayed index stages match ERAM data.
                POINT_REQ:begin
                    address_x<=corner_x;address_y<=corner_y;
                    request_pc<=pc;request_pr<=pr;zero_request<=corner_x==0 || (large_mode?corner_y<=19:corner_y==0);
                    point_valid<=2'b01;issued_last<=0;pc<=1;state<=POINT_GET;
                end
                POINT_GET:begin
                    point_valid<={point_valid[0],!issued_last};
                    rpc<=request_pc;rpr<=request_pr;zero_corner<=zero_request;
                    if(!issued_last)begin
                        address_x<=corner_x;address_y<=corner_y;
                        request_pc<=pc;request_pr<=pr;zero_request<=corner_x==0 || (large_mode?corner_y<=19:corner_y==0);
                        if(pc==3 && pr==3)issued_last<=1;
                        if(pc==3)begin pc<=0;pr<=pr+1'b1;end else pc<=pc+1'b1;
                    end
                    if(point_valid[1])begin
                        if(rpr!=0 && rpc!=0)begin
                            if(flip_x^flip_y)cells[(rpr-1)*3+rpc-1]<=top[rpc]+bottom_left-top_left-corner;
                            else cells[(rpr-1)*3+rpc-1]<=top_left+corner-top[rpc]-bottom_left;
                        end
                        top_left<=top[rpc];bottom_left<=corner;top[rpc]<=corner;
                        if(rpc==3 && rpr==3)begin bit_index<=0;lbp<=0;state<=LBP_BITS;end
                    end
                end
                LBP_BITS:begin
                    lbp[7-bit_index]<=cells[neighbor_index]>=cells[4];
                    if(bit_index==7)state<=SUB_WAIT;else bit_index<=bit_index+1'b1;
                end
                SUB_WAIT:state<=SUB_ADD;
                SUB_ADD:begin stage_sum<=stage_sum+leaf;state<=DECIDE;end
                DECIDE:begin
                    if(node==stage_end)begin
                        if(stage_sum<stage_threshold)state<=NEXT_WINDOW;
                        else if(stage==(profile?15:19))begin
                            ci<=0;min_count<=255;min_index<=0;
                            candidate_x<=wx+(win>>1);candidate_y<=wy+(win>>1);state<=GROUP_READ;
                        end else begin stage<=stage+1'b1;stage_sum<=0;node<=node+1'b1;state<=META_WAIT;end
                    end else begin node<=node+1'b1;state<=META_WAIT;end
                end
                GROUP_READ,RESULT_READ:begin
                    group_x<=cx[ci];group_y<=cy[ci];group_w<=cw[ci];group_count<=count[ci];
                    state<=state==GROUP_READ?GROUP:RESULT;
                end
                GROUP:begin
                    if(group_count==0)begin
                        cx[ci]<=candidate_x;cy[ci]<=candidate_y;cw[ci]<=win;count[ci]<=1;state<=NEXT_WINDOW;
                    end else if(near_group)begin
                        if(group_count<255)begin
                            cx[ci]<=smooth(group_x,candidate_x);cy[ci]<=smooth(group_y,candidate_y);
                            cw[ci]<=smooth(group_w,win);count[ci]<=group_count+1'b1;
                        end
                        state<=NEXT_WINDOW;
                    end else if(ci==7)begin
                        if(chosen_count<=1)begin
                            cx[chosen_index]<=candidate_x;cy[chosen_index]<=candidate_y;
                            cw[chosen_index]<=win;count[chosen_index]<=1;
                        end
                        state<=NEXT_WINDOW;
                    end else begin min_count<=chosen_count;min_index<=chosen_index;ci<=ci+1'b1;state<=GROUP_READ;end
                end
                NEXT_WINDOW:begin
                    if(wx+STRIDE+limit_x(scale_index,profile)<=WIDTH)begin wx<=wx+STRIDE;state<=WINDOW_START;end
                    else if(wy+STRIDE+limit_y(scale_index,profile)<=scan_height)begin wx<=profile?profile_x0:8'd0;wy<=wy+STRIDE;state<=WINDOW_START;end
                    else if(scale_index<7 && limit_y(scale_index+3'd1,profile)<=scan_height && limit_x(scale_index+3'd1,profile)<=WIDTH)begin
                        wx<=profile?profile_x0:8'd0;wy<=profile?profile_y0:8'd0;scale_index<=scale_index+1'b1;state<=WINDOW_START;
                    end else begin ci<=0;best_count<=0;local_count<=0;state<=RESULT_READ;end
                end
                RESULT:begin
                    if(group_count>best_count)begin best_count<=group_count;best_x<=group_x;best_y<=group_y;best_w<=group_w;end
                    if(near_hint && group_count>local_count)begin
                        local_count<=group_count;local_x<=group_x;local_y<=group_y;local_w<=group_w;
                    end
                    if(ci==7)state<=PUBLISH;else begin ci<=ci+1'b1;state<=RESULT_READ;end
                end
                PUBLISH:begin
                    if(ENABLE_PRIORITY && !large_mode && !weak_probe_active && model_pass==0 &&
                        hint_valid && use_local && result_count>=2 && result_count<5)begin
                        weak_probe_active<=1;weak_count<=result_count;weak_x<=result_x;weak_y<=result_y;weak_w<=result_w;
                        model_pass<=probe_pass;scale_index<=0;wx<=profile_x0;wy<=profile_y0;state<=WINDOW_START;
                        if(remembered_pass==0)weak_probe_pass<=weak_probe_pass==4?1:weak_probe_pass+1'b1;
                        for(n=0;n<8;n=n+1)count[n]<=0;
                    end else if(weak_probe_active || result_count>=(use_local?2:((ENABLE_PRIORITY && profile)?profile_entry_min:5)) || pass_rank==4)begin
                        O_found<=publish_found;
                        if(ENABLE_PRIORITY && !hint_valid && !large_mode && !publish_found)profile_phase<=profile_phase+1'b1;
                        // Local weak evidence maintains geometry, not a new confident pose.
                        if(!use_weak_fallback && (result_count>=5 || (ENABLE_PRIORITY && profile && result_count>=3)))remembered_pass<=model_pass;
                        O_x<=result_x<(result_w>>1)?0:(result_x+(result_w>>1)>WIDTH?WIDTH-result_w:result_x-(result_w>>1));
                        O_y<=result_y<(result_w>>1)?0:(result_y+(result_w>>1)>scan_height?scan_height-result_w:result_y-(result_w>>1));
                        // Bit7 also marks uncertain pose: weak frontal maintenance must not
                        // enable FER after a previously confident profile detection.
                        O_size<=result_w[6:0];O_neighbors<={((profile && !use_weak_fallback) || (result_count<5 && remembered_pass!=0)),(result_count>127?7'd127:result_count[6:0])};
                        O_done<=1;O_busy<=0;O_timeout<=0;state<=IDLE;
                    end else begin
                        model_pass<=next_model_pass;pass_rank<=pass_rank+1'b1;scale_index<=0;wx<=next_model_pass!=0?profile_x0:8'd0;wy<=next_model_pass!=0?profile_y0:8'd0;state<=WINDOW_START;
                        for(n=0;n<8;n=n+1)count[n]<=0;
                    end
                end
                default:state<=IDLE;
            endcase
        end
    end
endmodule
