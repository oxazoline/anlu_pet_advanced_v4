// Q12 stages; profile input appended for source compatibility.
module ext_face_stage_rom(input wire [4:0] I_stage,output reg [7:0] O_end,output reg signed [17:0] O_threshold,input wire I_profile);
    always @(*)begin
    O_end=0;O_threshold=0;
    if(I_profile)case(I_stage)
        5'd0:begin O_end=8'd3;O_threshold=18'sh3f67c;end
        5'd1:begin O_end=8'd9;O_threshold=18'sh3f738;end
        5'd2:begin O_end=8'd13;O_threshold=18'sh3f8fa;end
        5'd3:begin O_end=8'd19;O_threshold=18'sh3f88a;end
        5'd4:begin O_end=8'd27;O_threshold=18'sh3f640;end
        5'd5:begin O_end=8'd35;O_threshold=18'sh3f74c;end
        5'd6:begin O_end=8'd43;O_threshold=18'sh3f5e3;end
        5'd7:begin O_end=8'd51;O_threshold=18'sh3f66c;end
        5'd8:begin O_end=8'd60;O_threshold=18'sh3f746;end
        5'd9:begin O_end=8'd69;O_threshold=18'sh3f53b;end
        5'd10:begin O_end=8'd78;O_threshold=18'sh3f497;end
        5'd11:begin O_end=8'd88;O_threshold=18'sh3ed12;end
        5'd12:begin O_end=8'd98;O_threshold=18'sh3f5af;end
        5'd13:begin O_end=8'd108;O_threshold=18'sh3f65c;end
        5'd14:begin O_end=8'd119;O_threshold=18'sh3ecf0;end
        5'd15:begin O_end=8'd129;O_threshold=18'sh3f39d;end
        default:begin end
    endcase else case(I_stage)
        5'd0:begin O_end=8'd2;O_threshold=18'sh3f3f7;end
        5'd1:begin O_end=8'd6;O_threshold=18'sh3f834;end
        5'd2:begin O_end=8'd10;O_threshold=18'sh3ed74;end
        5'd3:begin O_end=8'd15;O_threshold=18'sh3f3e6;end
        5'd4:begin O_end=8'd20;O_threshold=18'sh3f310;end
        5'd5:begin O_end=8'd25;O_threshold=18'sh3f71f;end
        5'd6:begin O_end=8'd30;O_threshold=18'sh3f1f5;end
        5'd7:begin O_end=8'd36;O_threshold=18'sh3ee2d;end
        5'd8:begin O_end=8'd43;O_threshold=18'sh3f2cf;end
        5'd9:begin O_end=8'd50;O_threshold=18'sh3ec6c;end
        5'd10:begin O_end=8'd57;O_threshold=18'sh3f721;end
        5'd11:begin O_end=8'd64;O_threshold=18'sh3f48b;end
        5'd12:begin O_end=8'd72;O_threshold=18'sh3f536;end
        5'd13:begin O_end=8'd81;O_threshold=18'sh3ecbb;end
        5'd14:begin O_end=8'd91;O_threshold=18'sh3f28e;end
        5'd15:begin O_end=8'd100;O_threshold=18'sh3ecd7;end
        5'd16:begin O_end=8'd109;O_threshold=18'sh3f6d4;end
        5'd17:begin O_end=8'd118;O_threshold=18'sh3f82c;end
        5'd18:begin O_end=8'd128;O_threshold=18'sh3f68a;end
        5'd19:begin O_end=8'd138;O_threshold=18'sh3f3d2;end
        default:begin end
    endcase
    end
endmodule
