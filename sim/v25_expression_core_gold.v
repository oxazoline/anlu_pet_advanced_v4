// Native48/native32 grayscale uniform-LBP/gradient MLP. One serial signed multiplier.
// Dual 0/180-degree histograms; no camera backpressure. Scores are expression cues.
module v25_expression_core_gold #(parameter integer ENABLE_AU=1, ENABLE_CUE=0, ENABLE_MOUTH=0, BALANCED_POLICY=0, FULL_SCORE_DEBUG=1, V22_POLICY=0, ENABLE_CBROW=0)(input wire I_clk,I_rst_n,I_start,
 input wire I_write,input wire [11:0] I_address,input wire [7:0] I_pixel,I_contrast,
 output reg O_busy,O_done,output reg [1:0] O_label,output reg [167:0] O_diagnostic,input wire I_lowres);
 // GENERATED_CONSTANTS
function [5:0] uniform_bin;input [7:0] n;begin case(n)
8'd0:uniform_bin=6'h0;
8'd1:uniform_bin=6'h1;
8'd2:uniform_bin=6'h2;
8'd3:uniform_bin=6'h3;
8'd4:uniform_bin=6'h4;
8'd5:uniform_bin=6'h3a;
8'd6:uniform_bin=6'h5;
8'd7:uniform_bin=6'h6;
8'd8:uniform_bin=6'h7;
8'd9:uniform_bin=6'h3a;
8'd10:uniform_bin=6'h3a;
8'd11:uniform_bin=6'h3a;
8'd12:uniform_bin=6'h8;
8'd13:uniform_bin=6'h3a;
8'd14:uniform_bin=6'h9;
8'd15:uniform_bin=6'ha;
8'd16:uniform_bin=6'hb;
8'd17:uniform_bin=6'h3a;
8'd18:uniform_bin=6'h3a;
8'd19:uniform_bin=6'h3a;
8'd20:uniform_bin=6'h3a;
8'd21:uniform_bin=6'h3a;
8'd22:uniform_bin=6'h3a;
8'd23:uniform_bin=6'h3a;
8'd24:uniform_bin=6'hc;
8'd25:uniform_bin=6'h3a;
8'd26:uniform_bin=6'h3a;
8'd27:uniform_bin=6'h3a;
8'd28:uniform_bin=6'hd;
8'd29:uniform_bin=6'h3a;
8'd30:uniform_bin=6'he;
8'd31:uniform_bin=6'hf;
8'd32:uniform_bin=6'h10;
8'd33:uniform_bin=6'h3a;
8'd34:uniform_bin=6'h3a;
8'd35:uniform_bin=6'h3a;
8'd36:uniform_bin=6'h3a;
8'd37:uniform_bin=6'h3a;
8'd38:uniform_bin=6'h3a;
8'd39:uniform_bin=6'h3a;
8'd40:uniform_bin=6'h3a;
8'd41:uniform_bin=6'h3a;
8'd42:uniform_bin=6'h3a;
8'd43:uniform_bin=6'h3a;
8'd44:uniform_bin=6'h3a;
8'd45:uniform_bin=6'h3a;
8'd46:uniform_bin=6'h3a;
8'd47:uniform_bin=6'h3a;
8'd48:uniform_bin=6'h11;
8'd49:uniform_bin=6'h3a;
8'd50:uniform_bin=6'h3a;
8'd51:uniform_bin=6'h3a;
8'd52:uniform_bin=6'h3a;
8'd53:uniform_bin=6'h3a;
8'd54:uniform_bin=6'h3a;
8'd55:uniform_bin=6'h3a;
8'd56:uniform_bin=6'h12;
8'd57:uniform_bin=6'h3a;
8'd58:uniform_bin=6'h3a;
8'd59:uniform_bin=6'h3a;
8'd60:uniform_bin=6'h13;
8'd61:uniform_bin=6'h3a;
8'd62:uniform_bin=6'h14;
8'd63:uniform_bin=6'h15;
8'd64:uniform_bin=6'h16;
8'd65:uniform_bin=6'h3a;
8'd66:uniform_bin=6'h3a;
8'd67:uniform_bin=6'h3a;
8'd68:uniform_bin=6'h3a;
8'd69:uniform_bin=6'h3a;
8'd70:uniform_bin=6'h3a;
8'd71:uniform_bin=6'h3a;
8'd72:uniform_bin=6'h3a;
8'd73:uniform_bin=6'h3a;
8'd74:uniform_bin=6'h3a;
8'd75:uniform_bin=6'h3a;
8'd76:uniform_bin=6'h3a;
8'd77:uniform_bin=6'h3a;
8'd78:uniform_bin=6'h3a;
8'd79:uniform_bin=6'h3a;
8'd80:uniform_bin=6'h3a;
8'd81:uniform_bin=6'h3a;
8'd82:uniform_bin=6'h3a;
8'd83:uniform_bin=6'h3a;
8'd84:uniform_bin=6'h3a;
8'd85:uniform_bin=6'h3a;
8'd86:uniform_bin=6'h3a;
8'd87:uniform_bin=6'h3a;
8'd88:uniform_bin=6'h3a;
8'd89:uniform_bin=6'h3a;
8'd90:uniform_bin=6'h3a;
8'd91:uniform_bin=6'h3a;
8'd92:uniform_bin=6'h3a;
8'd93:uniform_bin=6'h3a;
8'd94:uniform_bin=6'h3a;
8'd95:uniform_bin=6'h3a;
8'd96:uniform_bin=6'h17;
8'd97:uniform_bin=6'h3a;
8'd98:uniform_bin=6'h3a;
8'd99:uniform_bin=6'h3a;
8'd100:uniform_bin=6'h3a;
8'd101:uniform_bin=6'h3a;
8'd102:uniform_bin=6'h3a;
8'd103:uniform_bin=6'h3a;
8'd104:uniform_bin=6'h3a;
8'd105:uniform_bin=6'h3a;
8'd106:uniform_bin=6'h3a;
8'd107:uniform_bin=6'h3a;
8'd108:uniform_bin=6'h3a;
8'd109:uniform_bin=6'h3a;
8'd110:uniform_bin=6'h3a;
8'd111:uniform_bin=6'h3a;
8'd112:uniform_bin=6'h18;
8'd113:uniform_bin=6'h3a;
8'd114:uniform_bin=6'h3a;
8'd115:uniform_bin=6'h3a;
8'd116:uniform_bin=6'h3a;
8'd117:uniform_bin=6'h3a;
8'd118:uniform_bin=6'h3a;
8'd119:uniform_bin=6'h3a;
8'd120:uniform_bin=6'h19;
8'd121:uniform_bin=6'h3a;
8'd122:uniform_bin=6'h3a;
8'd123:uniform_bin=6'h3a;
8'd124:uniform_bin=6'h1a;
8'd125:uniform_bin=6'h3a;
8'd126:uniform_bin=6'h1b;
8'd127:uniform_bin=6'h1c;
8'd128:uniform_bin=6'h1d;
8'd129:uniform_bin=6'h1e;
8'd130:uniform_bin=6'h3a;
8'd131:uniform_bin=6'h1f;
8'd132:uniform_bin=6'h3a;
8'd133:uniform_bin=6'h3a;
8'd134:uniform_bin=6'h3a;
8'd135:uniform_bin=6'h20;
8'd136:uniform_bin=6'h3a;
8'd137:uniform_bin=6'h3a;
8'd138:uniform_bin=6'h3a;
8'd139:uniform_bin=6'h3a;
8'd140:uniform_bin=6'h3a;
8'd141:uniform_bin=6'h3a;
8'd142:uniform_bin=6'h3a;
8'd143:uniform_bin=6'h21;
8'd144:uniform_bin=6'h3a;
8'd145:uniform_bin=6'h3a;
8'd146:uniform_bin=6'h3a;
8'd147:uniform_bin=6'h3a;
8'd148:uniform_bin=6'h3a;
8'd149:uniform_bin=6'h3a;
8'd150:uniform_bin=6'h3a;
8'd151:uniform_bin=6'h3a;
8'd152:uniform_bin=6'h3a;
8'd153:uniform_bin=6'h3a;
8'd154:uniform_bin=6'h3a;
8'd155:uniform_bin=6'h3a;
8'd156:uniform_bin=6'h3a;
8'd157:uniform_bin=6'h3a;
8'd158:uniform_bin=6'h3a;
8'd159:uniform_bin=6'h22;
8'd160:uniform_bin=6'h3a;
8'd161:uniform_bin=6'h3a;
8'd162:uniform_bin=6'h3a;
8'd163:uniform_bin=6'h3a;
8'd164:uniform_bin=6'h3a;
8'd165:uniform_bin=6'h3a;
8'd166:uniform_bin=6'h3a;
8'd167:uniform_bin=6'h3a;
8'd168:uniform_bin=6'h3a;
8'd169:uniform_bin=6'h3a;
8'd170:uniform_bin=6'h3a;
8'd171:uniform_bin=6'h3a;
8'd172:uniform_bin=6'h3a;
8'd173:uniform_bin=6'h3a;
8'd174:uniform_bin=6'h3a;
8'd175:uniform_bin=6'h3a;
8'd176:uniform_bin=6'h3a;
8'd177:uniform_bin=6'h3a;
8'd178:uniform_bin=6'h3a;
8'd179:uniform_bin=6'h3a;
8'd180:uniform_bin=6'h3a;
8'd181:uniform_bin=6'h3a;
8'd182:uniform_bin=6'h3a;
8'd183:uniform_bin=6'h3a;
8'd184:uniform_bin=6'h3a;
8'd185:uniform_bin=6'h3a;
8'd186:uniform_bin=6'h3a;
8'd187:uniform_bin=6'h3a;
8'd188:uniform_bin=6'h3a;
8'd189:uniform_bin=6'h3a;
8'd190:uniform_bin=6'h3a;
8'd191:uniform_bin=6'h23;
8'd192:uniform_bin=6'h24;
8'd193:uniform_bin=6'h25;
8'd194:uniform_bin=6'h3a;
8'd195:uniform_bin=6'h26;
8'd196:uniform_bin=6'h3a;
8'd197:uniform_bin=6'h3a;
8'd198:uniform_bin=6'h3a;
8'd199:uniform_bin=6'h27;
8'd200:uniform_bin=6'h3a;
8'd201:uniform_bin=6'h3a;
8'd202:uniform_bin=6'h3a;
8'd203:uniform_bin=6'h3a;
8'd204:uniform_bin=6'h3a;
8'd205:uniform_bin=6'h3a;
8'd206:uniform_bin=6'h3a;
8'd207:uniform_bin=6'h28;
8'd208:uniform_bin=6'h3a;
8'd209:uniform_bin=6'h3a;
8'd210:uniform_bin=6'h3a;
8'd211:uniform_bin=6'h3a;
8'd212:uniform_bin=6'h3a;
8'd213:uniform_bin=6'h3a;
8'd214:uniform_bin=6'h3a;
8'd215:uniform_bin=6'h3a;
8'd216:uniform_bin=6'h3a;
8'd217:uniform_bin=6'h3a;
8'd218:uniform_bin=6'h3a;
8'd219:uniform_bin=6'h3a;
8'd220:uniform_bin=6'h3a;
8'd221:uniform_bin=6'h3a;
8'd222:uniform_bin=6'h3a;
8'd223:uniform_bin=6'h29;
8'd224:uniform_bin=6'h2a;
8'd225:uniform_bin=6'h2b;
8'd226:uniform_bin=6'h3a;
8'd227:uniform_bin=6'h2c;
8'd228:uniform_bin=6'h3a;
8'd229:uniform_bin=6'h3a;
8'd230:uniform_bin=6'h3a;
8'd231:uniform_bin=6'h2d;
8'd232:uniform_bin=6'h3a;
8'd233:uniform_bin=6'h3a;
8'd234:uniform_bin=6'h3a;
8'd235:uniform_bin=6'h3a;
8'd236:uniform_bin=6'h3a;
8'd237:uniform_bin=6'h3a;
8'd238:uniform_bin=6'h3a;
8'd239:uniform_bin=6'h2e;
8'd240:uniform_bin=6'h2f;
8'd241:uniform_bin=6'h30;
8'd242:uniform_bin=6'h3a;
8'd243:uniform_bin=6'h31;
8'd244:uniform_bin=6'h3a;
8'd245:uniform_bin=6'h3a;
8'd246:uniform_bin=6'h3a;
8'd247:uniform_bin=6'h32;
8'd248:uniform_bin=6'h33;
8'd249:uniform_bin=6'h34;
8'd250:uniform_bin=6'h3a;
8'd251:uniform_bin=6'h35;
8'd252:uniform_bin=6'h36;
8'd253:uniform_bin=6'h37;
8'd254:uniform_bin=6'h38;
8'd255:uniform_bin=6'h39;
default:uniform_bin=0;endcase end endfunction
function signed [31:0] bias1;input [4:0] n;begin case(n)
5'd0:bias1=32'hffffffa7;
5'd1:bias1=32'h3d;
5'd2:bias1=32'h2c;
5'd3:bias1=32'h6f;
5'd4:bias1=32'h5b;
5'd5:bias1=32'hffffffeb;
5'd6:bias1=32'hffffffa4;
5'd7:bias1=32'h53;
5'd8:bias1=32'hffffffc4;
5'd9:bias1=32'hffffffd4;
5'd10:bias1=32'hffffff88;
5'd11:bias1=32'hffffff8d;
5'd12:bias1=32'h4f;
5'd13:bias1=32'h5d;
5'd14:bias1=32'h9a;
5'd15:bias1=32'hffffff63;
5'd16:bias1=32'h8d;
5'd17:bias1=32'hffffffec;
5'd18:bias1=32'h51;
5'd19:bias1=32'h54;
5'd20:bias1=32'hfffffffa;
5'd21:bias1=32'h19;
5'd22:bias1=32'ha;
5'd23:bias1=32'hffffffd4;
5'd24:bias1=32'hffffff8c;
5'd25:bias1=32'hffffff9c;
5'd26:bias1=32'hbb;
5'd27:bias1=32'hffffffcc;
5'd28:bias1=32'h1f;
5'd29:bias1=32'hffffffbf;
5'd30:bias1=32'hffffffdd;
5'd31:bias1=32'hffffffff;
default:bias1=0;endcase end endfunction
function signed [31:0] bias2;input [1:0] n;begin case(n)
2'd0:bias2=32'h43;
2'd1:bias2=32'h8;
2'd2:bias2=32'hffffffda;
2'd3:bias2=32'hffffffb8;
default:bias2=0;endcase end endfunction
function signed [31:0] native_bias2;input [1:0] n;begin case(n)
2'd0:native_bias2=32'h43;
2'd1:native_bias2=32'h8;
2'd2:native_bias2=32'hffffffda;
2'd3:native_bias2=32'hffffffb8;
default:native_bias2=0;endcase end endfunction
function signed [7:0] head_weight;input [6:0] n;begin case(n)
7'd0:head_weight=8'h9c;
7'd1:head_weight=8'he6;
7'd2:head_weight=8'hb9;
7'd3:head_weight=8'h6b;
7'd4:head_weight=8'h3a;
7'd5:head_weight=8'ha1;
7'd6:head_weight=8'hac;
7'd7:head_weight=8'h29;
7'd8:head_weight=8'h0;
7'd9:head_weight=8'h8f;
7'd10:head_weight=8'ha2;
7'd11:head_weight=8'hb2;
7'd12:head_weight=8'h23;
7'd13:head_weight=8'hfb;
7'd14:head_weight=8'h1b;
7'd15:head_weight=8'hb1;
7'd16:head_weight=8'h25;
7'd17:head_weight=8'h27;
7'd18:head_weight=8'h3a;
7'd19:head_weight=8'h46;
7'd20:head_weight=8'hbe;
7'd21:head_weight=8'hc9;
7'd22:head_weight=8'h85;
7'd23:head_weight=8'h31;
7'd24:head_weight=8'h3e;
7'd25:head_weight=8'ha;
7'd26:head_weight=8'h41;
7'd27:head_weight=8'h69;
7'd28:head_weight=8'hdc;
7'd29:head_weight=8'h0;
7'd30:head_weight=8'h95;
7'd31:head_weight=8'h92;
7'd32:head_weight=8'h0;
7'd33:head_weight=8'h44;
7'd34:head_weight=8'hb;
7'd35:head_weight=8'he0;
7'd36:head_weight=8'hf6;
7'd37:head_weight=8'hf;
7'd38:head_weight=8'h1d;
7'd39:head_weight=8'h0;
7'd40:head_weight=8'h0;
7'd41:head_weight=8'h24;
7'd42:head_weight=8'h9;
7'd43:head_weight=8'h26;
7'd44:head_weight=8'hd8;
7'd45:head_weight=8'h4a;
7'd46:head_weight=8'he7;
7'd47:head_weight=8'hea;
7'd48:head_weight=8'h20;
7'd49:head_weight=8'h23;
7'd50:head_weight=8'h20;
7'd51:head_weight=8'hf9;
7'd52:head_weight=8'h9;
7'd53:head_weight=8'hd2;
7'd54:head_weight=8'h6a;
7'd55:head_weight=8'h9d;
7'd56:head_weight=8'h92;
7'd57:head_weight=8'hd7;
7'd58:head_weight=8'h17;
7'd59:head_weight=8'ha6;
7'd60:head_weight=8'h3d;
7'd61:head_weight=8'h0;
7'd62:head_weight=8'h2;
7'd63:head_weight=8'h53;
7'd64:head_weight=8'h24;
7'd65:head_weight=8'hf;
7'd66:head_weight=8'h45;
7'd67:head_weight=8'hd9;
7'd68:head_weight=8'h4;
7'd69:head_weight=8'h2f;
7'd70:head_weight=8'h5b;
7'd71:head_weight=8'hbb;
7'd72:head_weight=8'h0;
7'd73:head_weight=8'h3f;
7'd74:head_weight=8'hff;
7'd75:head_weight=8'h43;
7'd76:head_weight=8'hf7;
7'd77:head_weight=8'he1;
7'd78:head_weight=8'h11;
7'd79:head_weight=8'h2d;
7'd80:head_weight=8'hb3;
7'd81:head_weight=8'ha0;
7'd82:head_weight=8'hdb;
7'd83:head_weight=8'he4;
7'd84:head_weight=8'h56;
7'd85:head_weight=8'hf9;
7'd86:head_weight=8'h3;
7'd87:head_weight=8'hfd;
7'd88:head_weight=8'h4;
7'd89:head_weight=8'hf6;
7'd90:head_weight=8'hb8;
7'd91:head_weight=8'hfe;
7'd92:head_weight=8'h20;
7'd93:head_weight=8'h0;
7'd94:head_weight=8'hd8;
7'd95:head_weight=8'hcb;
7'd96:head_weight=8'h32;
7'd97:head_weight=8'hb3;
7'd98:head_weight=8'hee;
7'd99:head_weight=8'hbc;
7'd100:head_weight=8'hba;
7'd101:head_weight=8'h1f;
7'd102:head_weight=8'hc5;
7'd103:head_weight=8'h21;
7'd104:head_weight=8'h0;
7'd105:head_weight=8'hb;
7'd106:head_weight=8'h41;
7'd107:head_weight=8'he5;
7'd108:head_weight=8'he;
7'd109:head_weight=8'hcb;
7'd110:head_weight=8'hea;
7'd111:head_weight=8'h3f;
7'd112:head_weight=8'hfa;
7'd113:head_weight=8'h1c;
7'd114:head_weight=8'hb0;
7'd115:head_weight=8'hca;
7'd116:head_weight=8'hcd;
7'd117:head_weight=8'h68;
7'd118:head_weight=8'h4;
7'd119:head_weight=8'h2a;
7'd120:head_weight=8'h10;
7'd121:head_weight=8'h29;
7'd122:head_weight=8'hcb;
7'd123:head_weight=8'hbf;
7'd124:head_weight=8'hcf;
7'd125:head_weight=8'h0;
7'd126:head_weight=8'h7f;
7'd127:head_weight=8'h3c;
default:head_weight=0;endcase end endfunction
function signed [31:0] class_margin;input [1:0] n;begin case(n)
2'd0:class_margin=32'h15;
2'd1:class_margin=32'hd1;
2'd2:class_margin=32'h70f;
2'd3:class_margin=32'h7fffffff;
default:class_margin=0;endcase end endfunction
function signed [7:0] low_head_weight;input [6:0] n;begin case(n)
7'd0:low_head_weight=8'h9e;
7'd1:low_head_weight=8'he5;
7'd2:low_head_weight=8'hb9;
7'd3:low_head_weight=8'h69;
7'd4:low_head_weight=8'h36;
7'd5:low_head_weight=8'ha3;
7'd6:low_head_weight=8'hae;
7'd7:low_head_weight=8'h27;
7'd8:low_head_weight=8'h0;
7'd9:low_head_weight=8'h8f;
7'd10:low_head_weight=8'ha1;
7'd11:low_head_weight=8'hb5;
7'd12:low_head_weight=8'h23;
7'd13:low_head_weight=8'hfe;
7'd14:low_head_weight=8'h1a;
7'd15:low_head_weight=8'hb5;
7'd16:low_head_weight=8'h29;
7'd17:low_head_weight=8'h25;
7'd18:low_head_weight=8'h3c;
7'd19:low_head_weight=8'h48;
7'd20:low_head_weight=8'hbf;
7'd21:low_head_weight=8'hcb;
7'd22:low_head_weight=8'h86;
7'd23:low_head_weight=8'h29;
7'd24:low_head_weight=8'h38;
7'd25:low_head_weight=8'hd;
7'd26:low_head_weight=8'h42;
7'd27:low_head_weight=8'h68;
7'd28:low_head_weight=8'hde;
7'd29:low_head_weight=8'h0;
7'd30:low_head_weight=8'h94;
7'd31:low_head_weight=8'h93;
7'd32:low_head_weight=8'h0;
7'd33:low_head_weight=8'h45;
7'd34:low_head_weight=8'h11;
7'd35:low_head_weight=8'hdf;
7'd36:low_head_weight=8'hfa;
7'd37:low_head_weight=8'hf;
7'd38:low_head_weight=8'h1c;
7'd39:low_head_weight=8'h1;
7'd40:low_head_weight=8'h0;
7'd41:low_head_weight=8'h1f;
7'd42:low_head_weight=8'he;
7'd43:low_head_weight=8'h24;
7'd44:low_head_weight=8'hd8;
7'd45:low_head_weight=8'h47;
7'd46:low_head_weight=8'he6;
7'd47:low_head_weight=8'hee;
7'd48:low_head_weight=8'h1b;
7'd49:low_head_weight=8'h1e;
7'd50:low_head_weight=8'h20;
7'd51:low_head_weight=8'hf6;
7'd52:low_head_weight=8'h7;
7'd53:low_head_weight=8'hd2;
7'd54:low_head_weight=8'h68;
7'd55:low_head_weight=8'ha1;
7'd56:low_head_weight=8'h95;
7'd57:low_head_weight=8'hd5;
7'd58:low_head_weight=8'h11;
7'd59:low_head_weight=8'ha9;
7'd60:low_head_weight=8'h3c;
7'd61:low_head_weight=8'h0;
7'd62:low_head_weight=8'hfd;
7'd63:low_head_weight=8'h50;
7'd64:low_head_weight=8'h22;
7'd65:low_head_weight=8'hb;
7'd66:low_head_weight=8'h41;
7'd67:low_head_weight=8'hdd;
7'd68:low_head_weight=8'h2;
7'd69:low_head_weight=8'h2b;
7'd70:low_head_weight=8'h59;
7'd71:low_head_weight=8'hbf;
7'd72:low_head_weight=8'h0;
7'd73:low_head_weight=8'h42;
7'd74:low_head_weight=8'hfe;
7'd75:low_head_weight=8'h3e;
7'd76:low_head_weight=8'hf7;
7'd77:low_head_weight=8'he6;
7'd78:low_head_weight=8'h12;
7'd79:low_head_weight=8'h2e;
7'd80:low_head_weight=8'hb7;
7'd81:low_head_weight=8'ha1;
7'd82:low_head_weight=8'hd7;
7'd83:low_head_weight=8'he8;
7'd84:low_head_weight=8'h53;
7'd85:low_head_weight=8'hfd;
7'd86:low_head_weight=8'h9;
7'd87:low_head_weight=8'h3;
7'd88:low_head_weight=8'h9;
7'd89:low_head_weight=8'hf9;
7'd90:low_head_weight=8'hbd;
7'd91:low_head_weight=8'hff;
7'd92:low_head_weight=8'h1b;
7'd93:low_head_weight=8'h0;
7'd94:low_head_weight=8'hde;
7'd95:low_head_weight=8'hd1;
7'd96:low_head_weight=8'h2c;
7'd97:low_head_weight=8'hb7;
7'd98:low_head_weight=8'hf4;
7'd99:low_head_weight=8'hc1;
7'd100:low_head_weight=8'hbe;
7'd101:low_head_weight=8'h1d;
7'd102:low_head_weight=8'hc8;
7'd103:low_head_weight=8'h1a;
7'd104:low_head_weight=8'h0;
7'd105:low_head_weight=8'hd;
7'd106:low_head_weight=8'h3f;
7'd107:low_head_weight=8'hed;
7'd108:low_head_weight=8'he;
7'd109:low_head_weight=8'hd1;
7'd110:low_head_weight=8'hec;
7'd111:low_head_weight=8'h38;
7'd112:low_head_weight=8'hf6;
7'd113:low_head_weight=8'h22;
7'd114:low_head_weight=8'hb1;
7'd115:low_head_weight=8'hca;
7'd116:low_head_weight=8'hd4;
7'd117:low_head_weight=8'h66;
7'd118:low_head_weight=8'ha;
7'd119:low_head_weight=8'h25;
7'd120:low_head_weight=8'h13;
7'd121:low_head_weight=8'h23;
7'd122:low_head_weight=8'hcd;
7'd123:low_head_weight=8'hc4;
7'd124:low_head_weight=8'hd6;
7'd125:low_head_weight=8'h0;
7'd126:low_head_weight=8'h7f;
7'd127:low_head_weight=8'h39;
default:low_head_weight=0;endcase end endfunction
function signed [31:0] low_bias2;input [1:0] n;begin case(n)
2'd0:low_bias2=32'h66;
2'd1:low_bias2=32'h23;
2'd2:low_bias2=32'hffffff4e;
2'd3:low_bias2=32'h14;
default:low_bias2=0;endcase end endfunction
function signed [31:0] low_class_margin;input [1:0] n;begin case(n)
2'd0:low_class_margin=32'h23e;
2'd1:low_class_margin=32'h28d;
2'd2:low_class_margin=32'h500;
2'd3:low_class_margin=32'h7fffffff;
default:low_class_margin=0;endcase end endfunction
localparam integer HIDDEN_SHIFT=6,SCORE_THRESHOLD=21,HAPPY_TENSE_GAP=27,LOW_HAPPY_TENSE_GAP=1412;
 localparam IDLE=0,CLEAR=1,P_REQ=2,P_GET=3,FEATURE=4,H_REQ=5,H_WRITE=6,
 M_REQ=7,M_PRODUCT=8,M_ADD=9,HEAD_REQ=10,HEAD_PRODUCT=11,HEAD_ADD=12,
 RANK=13,CHOOSE=14,FINISH=15;
 reg [4:0] state;
 (* ram_style="block" *) reg [7:0] patch[0:2303];reg [7:0] pq;
 (* ram_style="block" *) reg [8:0] histogram[0:4095];reg [8:0] hq;
 (* ram_style="dram" *) reg remainder[0:4095];reg remainder_q,low_mode;
 reg [11:0] ha,clear_address;
 reg [5:0] x,y;reg radius,update_rotation,orientation;reg [1:0] feature_kind;
 reg [3:0] point;reg [7:0] pixels[0:8];reg [7:0] contrast;
 reg signed [6:0] rx,ry;
 always @(*)begin
   rx=$signed({1'b0,x});ry=$signed({1'b0,y});
   case(point)
    1:begin rx=rx-(radius?2:1);ry=ry-(radius?2:1);end
    2:ry=ry-(radius?2:1);
    3:begin rx=rx+(radius?2:1);ry=ry-(radius?2:1);end
    4:rx=rx+(radius?2:1);
    5:begin rx=rx+(radius?2:1);ry=ry+(radius?2:1);end
    6:ry=ry+(radius?2:1);
    7:begin rx=rx-(radius?2:1);ry=ry+(radius?2:1);end
    8:rx=rx-(radius?2:1);
   endcase
 end
 wire [11:0] pa=low_mode?{2'd0,ry[4:0],rx[4:0]}:(({5'd0,ry}<<5)+({5'd0,ry}<<4)+{5'd0,rx});
 wire [7:0] code={pixels[1]>=pixels[0],pixels[2]>=pixels[0],
 pixels[3]>=pixels[0],pixels[4]>=pixels[0],pixels[5]>=pixels[0],
 pixels[6]>=pixels[0],pixels[7]>=pixels[0],pixels[8]>=pixels[0]};
 wire [1:0] cell_x=x<12?0:(x<24?1:(x<36?2:3));
 wire [1:0] cell_y=y<12?0:(y<24?1:(y<36?2:3));
 wire [3:0] cell_id=low_mode?{y[4:3],x[4:3]}:{cell_y,cell_x};
 wire [5:0] last_center=low_mode?6'd29:6'd45;
 wire [10:0] normal_lbp=(radius?11'd944:11'd0)+cell_id*11'd59+uniform_bin(code);
 wire [10:0] rotated_lbp=(radius?11'd944:11'd0)+(4'd15-cell_id)*11'd59+uniform_bin({code[3:0],code[7:4]});
 wire signed [8:0] dx=$signed({1'b0,pixels[4]})-$signed({1'b0,pixels[8]});
 wire signed [8:0] dy=$signed({1'b0,pixels[6]})-$signed({1'b0,pixels[2]});
 wire [8:0] ax=dx<0?-dx:dx,ay=dy<0?-dy:dy;
 wire [9:0] magnitude={1'b0,ax}+ay;
 wire [2:0] direction={1'b0,ax}>={ay,1'b0}?(dx>=0?3'd0:3'd4):
                      {1'b0,ay}>={ax,1'b0}?(dy>=0?3'd2:3'd6):
                      (dy>=0?(dx>=0?3'd1:3'd3):(dx>=0?3'd7:3'd5));
 wire [7:0] high_threshold=low_mode?(contrast[7:2]<24?8'd24:{2'd0,contrast[7:2]}):(contrast[7:3]<16?8'd16:{3'd0,contrast[7:3]});
 wire [7:0] mid_threshold=low_mode?(contrast[7:3]<12?8'd12:{3'd0,contrast[7:3]}):(contrast[7:4]<8?8'd8:{4'd0,contrast[7:4]});
 wire [7:0] low_threshold=low_mode?(contrast[7:4]<6?8'd6:{4'd0,contrast[7:4]}):(contrast[7:5]<4?8'd4:{5'd0,contrast[7:5]});
 wire [2:0] vote=magnitude>=high_threshold?4:(magnitude>=mid_threshold?2:(magnitude>=low_threshold?1:0));
 reg [3:0] increment;
 wire [9:0] histogram_total={hq,remainder_q}+{6'd0,increment};
 reg [10:0] feature_index;reg [4:0] hidden_index,head_index;
 reg [1:0] output_index;reg signed [31:0] accumulator,product;
 reg [6:0] hidden[0:31];reg signed [31:0] scores[0:7];
 
 reg [14:0] weight_word;reg [1:0] weight_slot;reg [1:0] winner[0:1];reg selected;wire [3:0] rejection;
 // V17: reuse the single MAC and histogram; selected-orientation AU inference.
 localparam AU_REQ=16,AU_PRODUCT=17,AU_ADD=18,AU_HEAD_REQ=19,AU_HEAD_PRODUCT=20,AU_HEAD_ADD=21,AU_INIT=22;

 // V18 learned physical orientation head. It does not replace the base
 // classifier's two-view ensemble: AU anatomy alone needs upright features.
 localparam ORI_REQ=23,ORI_PRODUCT=24,ORI_ADD=25;
 reg signed [19:0] orientation_scores[0:1];
 wire signed [20:0] orientation_delta=$signed({orientation_scores[1][19],orientation_scores[1]})-$signed({orientation_scores[0][19],orientation_scores[0]});
 reg au_orientation,orientation_confident;
 wire ori_head=state>=ORI_REQ && state<=ORI_ADD;
 function signed [7:0] orientation_weight;input [4:0] n;begin case(n)
 5'd0:orientation_weight=8'h06;
5'd1:orientation_weight=8'he8;
5'd2:orientation_weight=8'he5;
5'd3:orientation_weight=8'h24;
5'd4:orientation_weight=8'hf5;
5'd5:orientation_weight=8'hdf;
5'd6:orientation_weight=8'h0d;
5'd7:orientation_weight=8'hfd;
5'd8:orientation_weight=8'h00;
5'd9:orientation_weight=8'he7;
5'd10:orientation_weight=8'hf7;
5'd11:orientation_weight=8'h1b;
5'd12:orientation_weight=8'h24;
5'd13:orientation_weight=8'h08;
5'd14:orientation_weight=8'hfa;
5'd15:orientation_weight=8'hec;
5'd16:orientation_weight=8'hf6;
5'd17:orientation_weight=8'he0;
5'd18:orientation_weight=8'hfd;
5'd19:orientation_weight=8'h07;
5'd20:orientation_weight=8'hf9;
5'd21:orientation_weight=8'he8;
5'd22:orientation_weight=8'h45;
5'd23:orientation_weight=8'h11;
5'd24:orientation_weight=8'h34;
5'd25:orientation_weight=8'h09;
5'd26:orientation_weight=8'h12;
5'd27:orientation_weight=8'h97;
5'd28:orientation_weight=8'h1b;
5'd29:orientation_weight=8'h00;
5'd30:orientation_weight=8'h22;
5'd31:orientation_weight=8'haa;
 default:orientation_weight=0;endcase end endfunction
 function signed [31:0] cue_bias1;input [2:0] n;begin case(n)
 3'd0:cue_bias1=32'h00000178;
 3'd1:cue_bias1=32'h000001c7;
 3'd2:cue_bias1=32'h0000014e;
 3'd3:cue_bias1=32'h000001d5;
 3'd4:cue_bias1=32'h000001ca;
 3'd5:cue_bias1=32'h000001cb;
 3'd6:cue_bias1=32'h000001dd;
 3'd7:cue_bias1=32'h00000187;
 default:cue_bias1=0;endcase end endfunction
 function signed [31:0] cue_bias2;input [2:0] n;begin case(n)
 3'd0:cue_bias2=32'hfffffd39;
 3'd1:cue_bias2=32'h000002cd;
 default:cue_bias2=0;endcase end endfunction
 localparam MOUTH_HEAD_REQ=26,MOUTH_HEAD_PRODUCT=27,MOUTH_HEAD_ADD=28,
 MOUTH_REQ=29,MOUTH_PRODUCT=30,MOUTH_ADD=31;
 reg signed [31:0] mouth_partial[0:1];reg signed [15:0] mouth_score;
 wire mouth_head=state>=MOUTH_HEAD_REQ && state<=MOUTH_HEAD_ADD;
 wire mouth_features=state>=MOUTH_REQ && state<=MOUTH_ADD;
 function signed [31:0] mouth_bias;input low;begin
  mouth_bias=low?32'h00000129:32'h000000fb;
 end endfunction
 reg [1:0] cue_phase;reg signed [15:0] cbrow_scores[0:1];reg signed [15:0] cue_scores[0:1];
 reg [3:0] au_slot;reg [2:0] au_output;
 reg signed [15:0] au_scores[0:5];
 wire au_features=state>=AU_REQ && state<=AU_ADD;
 wire au_head=state>=AU_HEAD_REQ && state<=AU_HEAD_ADD;
 reg [10:0] au_feature_address;
 wire [35:0] au_weight,old_au_weight,cue_weight;
 wire [35:0] cbrow_weight;wire signed [31:0] cbrow_bias1,cbrow_bias2;
 assign au_weight=cue_phase==2?cbrow_weight:(cue_phase==1?cue_weight:old_au_weight);
 generate if(ENABLE_AU)begin:g_au_weights
 ext_expression_au_weights au_weights(I_clk,weight_word[9:0],old_au_weight);
 end else begin assign old_au_weight=36'd0;end
 if(ENABLE_AU && ENABLE_CUE)begin:g_cue_weights
 ext_expression_cue_weights cue_weights(I_clk,weight_word[9:0],cue_weight);
 end else begin assign cue_weight=36'd0;end endgenerate
 generate if(ENABLE_CBROW && ENABLE_AU && ENABLE_CUE && ENABLE_MOUTH)begin:g_cbrow_weights
 ext_expression_cbrow_weights cbrow_weights(I_clk,weight_word[9:0],((state==MOUTH_ADD && feature_index==503)?3'd0:(state==AU_ADD && feature_index==1071 && hidden_index!=7)?hidden_index[2:0]+3'd1:hidden_index[2:0]),((state==AU_ADD && feature_index==1071 && hidden_index==7)?3'd0:(state==AU_HEAD_ADD && head_index==7)?au_output+3'd1:au_output),cbrow_weight,cbrow_bias1,cbrow_bias2);
 end else begin assign cbrow_weight=0;assign cbrow_bias1=0;assign cbrow_bias2=0;end endgenerate
 wire signed [3:0] au_wq=au_weight[{au_slot,2'd0}+:4];
 wire signed [7:0] au_head_wq=au_weight[{au_slot[1:0],3'd0}+:8];
 wire signed [7:0] mouth_head_wq=cue_weight[{au_slot[1:0],3'd0}+:8];
 wire signed [3:0] mouth_local_wq=cue_weight[{au_slot,2'd0}+:4];
 function signed [31:0] au_bias1;input [2:0] n;begin case(n)
3'd0:au_bias1=32'h00000196;
3'd1:au_bias1=32'h0000017b;
3'd2:au_bias1=32'h00000145;
3'd3:au_bias1=32'h000001b7;
3'd4:au_bias1=32'h0000020e;
3'd5:au_bias1=32'h00000218;
3'd6:au_bias1=32'h000001c2;
3'd7:au_bias1=32'h000001c5;
 default:au_bias1=0;endcase end endfunction
 function signed [31:0] au_bias2;input [2:0] n;begin case(n)
3'd0:au_bias2=32'hfffffff2;
3'd1:au_bias2=32'hfffffdb3;
3'd2:au_bias2=32'h000000ac;
3'd3:au_bias2=32'h00000375;
3'd4:au_bias2=32'h000002fa;
3'd5:au_bias2=32'hffffffc7;
 default:au_bias2=0;endcase end endfunction
 function [14:0] au_start_word;input [2:0] n;begin case(n)
 3'd0:au_start_word=15'd0;
3'd1:au_start_word=15'd119;
3'd2:au_start_word=15'd238;
3'd3:au_start_word=15'd357;
3'd4:au_start_word=15'd476;
3'd5:au_start_word=15'd595;
3'd6:au_start_word=15'd714;
3'd7:au_start_word=15'd833;
 default:au_start_word=0;endcase end endfunction
 function [3:0] au_start_slot;input [2:0] n;begin case(n)
 3'd0:au_start_slot=4'd0;
3'd1:au_start_slot=4'd1;
3'd2:au_start_slot=4'd2;
3'd3:au_start_slot=4'd3;
3'd4:au_start_slot=4'd4;
3'd5:au_start_slot=4'd5;
3'd6:au_start_slot=4'd6;
3'd7:au_start_slot=4'd7;
 default:au_start_slot=0;endcase end endfunction
 function signed [15:0] au_saturate;input signed [31:0] a;begin au_saturate=a>32767?16'sh7fff:(a< -32768?16'sh8000:a[15:0]);end endfunction
 function [7:0] au_display;input signed [15:0] a;reg signed [15:0] t;begin t=a>>>5;au_display=t>127?8'h7f:(t< -128?8'h80:t[7:0]);end endfunction
 // Seven signed diagnostic bits plus one strong-R bit retain mouth
 // observability without restoring the unused96-bit class-score payload.
 function [6:0] mouth_display;input signed [15:0] a;reg signed [15:0] t;begin
  t=a>>>5;mouth_display=t>16'sd63 ? 7'h3f:(t< -16'sd64 ? 7'h40:t[6:0]);
 end endfunction
 // V20: retain all V19 positives; lower the weak brow witness to128.
 // Independent brow/down/press paths no longer depend on total tension logit.
 // max(a,b)>=k iff a>=k || b>=k; avoid a signed16 max/mux in the decision path.
 wire au_gate=ENABLE_AU && contrast>=24 && winner[selected]!=3 && orientation_confident;
 wire au_support=au_scores[1]>=16'sd128 || au_scores[3]>=16'sd0 || au_scores[4]>=16'sd0 || au_scores[5]>=16'sd0;
 wire au_total_path=au_scores[0]>=16'sd1198 || (au_scores[0]>=16'sd64 && au_support);
 wire au_brow_path=au_scores[1]>=16'sd640;
 wire au_down_path=au_scores[3]>=16'sd512;
 wire au_press_path=au_scores[4]>=16'sd512 || au_scores[5]>=16'sd512;
 wire au_new_smile_block=au_scores[2]>= -16'sd1536;
 wire au_old_path=au_scores[0]>=16'sd1198 && au_scores[2]< -16'sd1024;
 wire au_new_path=((au_scores[0]>=16'sd64 && au_support) || au_brow_path || au_down_path || au_press_path) && !au_new_smile_block;
 wire cue_gate=ENABLE_CUE && au_gate && (winner[selected]==1 || winner[selected]==2);
 wire cue_brow=V22_POLICY?(cue_scores[0]>=16'sd480):(cue_scores[0]>=16'sd1152);
 wire cue_down=V22_POLICY?(cue_scores[1]>= -16'sd144):(cue_scores[1]>=16'sd128);
 // New action heads may not overwrite any raw HAPPY. The old policy stays intact.
 wire cue_tense=cue_gate && (cue_brow || cue_down);
 wire au_tense=(au_gate && (au_old_path || au_new_path)) || cue_tense;
 wire [1:0] final_winner=au_tense?2'd2:winner[selected];
 wire [3:0] final_rejection=au_tense?4'd0:rejection;
 // The V21 base label/rejection remains unchanged. C has its own quality
 // gate: an open-mouth OTHER is not an input-quality failure.
 wire mouth_open=BALANCED_POLICY?(mouth_score>=16'sd64):(mouth_score>=16'sd256);
 wire confused_brow=ENABLE_CBROW?(cbrow_scores[0]>=16'sd0):(BALANCED_POLICY?(cue_scores[0]>=16'sd512 || au_scores[1]>=16'sd384):(cue_scores[0]>=16'sd896 || au_scores[1]>=16'sd640));
 wire confused_quality=contrast>=24 && orientation_confident && winner[selected]!=0;
 wire confused=ENABLE_AU && ENABLE_CUE && ENABLE_MOUTH && confused_brow && mouth_open && (!ENABLE_CBROW || cbrow_scores[1]>=16'sd384) &&
  (BALANCED_POLICY?confused_quality:(au_gate && (winner[selected]==1 || winner[selected]==2) && final_winner==2 && final_rejection==0));
 // Strength remains diagnostic metadata; never changes the numerical base class.
 wire strong_r=final_winner==2 && final_rejection==0 &&
  ((winner[selected]==2 && rejection==0) ||
   (cue_gate && (cue_scores[0]>=16'sd1536 || cue_scores[1]>=16'sd512)) ||
   (au_gate && au_scores[0]>=16'sd1792 && au_scores[2]< -16'sd1024));
 // A bytes: total, brow4, down15, six action/gate flags + physical orientation.
 wire [31:0] au_debug={(ENABLE_CBROW?{7'd0,(cbrow_scores[1]>=16'sd384)}:(BALANCED_POLICY?{mouth_display(mouth_score),strong_r}:au_display(ENABLE_MOUTH?mouth_score:au_scores[0]))),au_display(ENABLE_CBROW?cbrow_scores[0]:(ENABLE_CUE?cue_scores[0]:au_scores[1])),au_display(ENABLE_CBROW?cbrow_scores[1]:(ENABLE_CUE?cue_scores[1]:au_scores[3])),
  (ENABLE_MOUTH?confused:au_total_path),(ENABLE_CBROW?confused_brow:(au_brow_path || (ENABLE_CUE && cue_brow))),(au_down_path || (ENABLE_CUE && cue_down)),(ENABLE_MOUTH?mouth_open:au_press_path),(ENABLE_CUE?(winner[selected]==0):au_new_smile_block),au_gate,orientation_confident,au_orientation};

 wire [11:0] read_ha=(au_features || mouth_features)?{au_orientation,au_feature_address}:((state>=M_REQ && state<=M_ADD)?{orientation,feature_index}:ha);
 // Isolated lossless weight-stream interface. Coefficients remain signed6.
 reg main_stream_seen,main_stream_orientation;reg [4:0] main_stream_neuron;
 wire main_weight_valid,main_weight_done;wire [5:0] main_weight_value;
 wire main_weight_start=state==M_REQ && feature_index==0 &&
   (!main_stream_seen || main_stream_neuron!=hidden_index || main_stream_orientation!=orientation);
 wire main_weight_take=state==M_PRODUCT && main_weight_valid;
 wire signed [5:0] wq=$signed(main_weight_value);
 ext_expression_weights weights(I_clk,I_rst_n,main_weight_start,hidden_index,main_weight_take,main_weight_valid,main_weight_value,main_weight_done);
 always @(posedge I_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin main_stream_seen<=0;main_stream_neuron<=0;main_stream_orientation<=0;end
  else if(state==IDLE && I_start)main_stream_seen<=0;
  else if(main_weight_start)begin main_stream_seen<=1;main_stream_neuron<=hidden_index;main_stream_orientation<=orientation;end
 end
 wire head_mode=state>=HEAD_REQ && state<=HEAD_ADD;
 wire signed [9:0] operand_a=(head_mode || au_head || ori_head || mouth_head)?$signed({3'b0,hidden[head_index]}):$signed({1'b0,hq});
 wire signed [7:0] operand_b=mouth_head?mouth_head_wq:mouth_features?{{4{mouth_local_wq[3]}},mouth_local_wq}:ori_head?orientation_weight(head_index):au_head?au_head_wq:(au_features?{{4{au_wq[3]}},au_wq}:head_mode?(low_mode?low_head_weight({output_index,head_index}):head_weight({output_index,head_index})):{{2{wq[5]}},wq});
 wire signed [31:0] next_acc=accumulator+product;
 function [6:0] activation;input signed [31:0] value;reg signed [31:0] shifted;
 begin shifted=value>>>HIDDEN_SHIFT;activation=shifted<0?0:(shifted>127?127:shifted[6:0]);end endfunction
 always @(posedge I_clk)begin
   if(I_write && !O_busy)patch[I_address]<=I_pixel;
   pq<=patch[pa];
   if(state==CLEAR)begin histogram[clear_address]<=0;remainder[clear_address]<=0;end
   else if(state==H_WRITE)begin histogram[ha]<=histogram_total[9:1];remainder[ha]<=histogram_total[0];end
   else begin hq<=histogram[read_ha];remainder_q<=remainder[read_ha];end
 end
 reg [2:0] rank_index;reg signed [31:0] best[0:1],second[0:1];
 reg signed [31:0] margin0,margin1,happy_gap0,happy_gap1;
 wire signed [31:0] chosen_margin=selected?margin1:margin0;
 wire signed [31:0] accepted_margin=(V22_POLICY && winner[selected]==0)?(low_mode?32'sd546:32'sd20):(low_mode?low_class_margin(winner[selected]):class_margin(winner[selected]));
 wire signed [31:0] chosen_happy_gap=selected?happy_gap1:happy_gap0;
 wire signed [31:0] happy_gap_limit=V22_POLICY?(low_mode?32'sd1344:32'sd26):(low_mode?LOW_HAPPY_TENSE_GAP:HAPPY_TENSE_GAP);
 wire happy_conflict=winner[selected]==0 && chosen_happy_gap<happy_gap_limit;
 assign rejection=contrast<24?1:(winner[selected]==3?2:(chosen_margin<accepted_margin?3:(happy_conflict?4:0)));
 integer i;
 always @(posedge I_clk or negedge I_rst_n)begin
 if(!I_rst_n)begin
  state<=IDLE;O_busy<=0;O_done<=0;O_label<=0;O_diagnostic<=0;contrast<=0;low_mode<=0;
  ha<=0;clear_address<=0;x<=2;y<=2;radius<=0;point<=0;feature_kind<=0;
  update_rotation<=0;orientation<=0;increment<=0;feature_index<=0;hidden_index<=0;
  head_index<=0;output_index<=0;accumulator<=0;product<=0;rank_index<=0;weight_word<=0;weight_slot<=0;
  mouth_partial[0]<=0;mouth_partial[1]<=0;mouth_score<=0;cue_phase<=0;cue_scores[0]<=0;cue_scores[1]<=0;cbrow_scores[0]<=0;cbrow_scores[1]<=0;au_feature_address<=59;au_slot<=0;au_output<=0;au_orientation<=0;orientation_confident<=0;orientation_scores[0]<=0;orientation_scores[1]<=0;for(i=0;i<6;i=i+1)au_scores[i]<=0;
  selected<=0;margin0<=0;margin1<=0;happy_gap0<=0;happy_gap1<=0;
  for(i=0;i<9;i=i+1)pixels[i]<=0;
  for(i=0;i<32;i=i+1)hidden[i]<=0;
  for(i=0;i<8;i=i+1)scores[i]<=0;
  for(i=0;i<2;i=i+1)begin best[i]<=32'sh80000000;second[i]<=32'sh80000000;winner[i]<=0;end
 end else begin
 O_done<=0;
 case(state)
 IDLE:if(I_start)begin O_busy<=1;contrast<=I_contrast;low_mode<=I_lowres;clear_address<=0;state<=CLEAR;end
 CLEAR:if(clear_address==4095)begin x<=2;y<=2;radius<=0;point<=0;state<=P_REQ;end
       else clear_address<=clear_address+1'b1;
 P_REQ:state<=P_GET;
 P_GET:begin pixels[point]<=pq;
   if(point==8)state<=FEATURE;else begin point<=point+1'b1;state<=P_REQ;end
 end
 FEATURE:begin
   ha<={1'b0,normal_lbp};increment<=low_mode?2:1;update_rotation<=0;
   feature_kind<=radius?2:0;state<=H_REQ;
 end
 H_REQ:state<=H_WRITE;
 H_WRITE:begin
   if(!update_rotation)begin
     update_rotation<=1;
     if(feature_kind==1)ha<=12'd2048+11'd1888+{(4'd15-cell_id),3'b0}+((direction+3'd4)&3'd7);
     else ha<=12'd2048+rotated_lbp;
     state<=H_REQ;
   end else if(feature_kind==0)begin
     ha<=11'd1888+{cell_id,3'b0}+direction;increment<=low_mode?{vote,1'b0}:{1'b0,vote};
     feature_kind<=1;update_rotation<=0;state<=H_REQ;
   end else if(feature_kind==1)begin radius<=1;point<=0;state<=P_REQ;end
   else if(x==last_center && y==last_center)begin
     orientation<=0;hidden_index<=0;feature_index<=0;weight_word<=0;weight_slot<=0;accumulator<=bias1(0);state<=M_REQ;
   end else begin
     if(x==last_center)begin x<=2;y<=y+1'b1;end else x<=x+1'b1;
     radius<=0;point<=0;state<=P_REQ;
   end
 end
 M_REQ:if(main_weight_valid && !main_weight_start)state<=M_PRODUCT;
 M_PRODUCT:if(main_weight_valid)begin product<=operand_a*operand_b;state<=M_ADD;end
 M_ADD:begin
   if(feature_index==2015)begin
     hidden[hidden_index]<=activation(next_acc);feature_index<=0;
     if(hidden_index==31)begin head_index<=0;output_index<=0;accumulator<=low_mode?low_bias2(0):native_bias2(0);state<=HEAD_REQ;end
     else begin hidden_index<=hidden_index+1'b1;accumulator<=bias1(hidden_index+5'd1);state<=M_REQ;end
   end else begin accumulator<=next_acc;feature_index<=feature_index+1'b1;state<=M_REQ;end
 end
 HEAD_REQ:state<=HEAD_PRODUCT;
 HEAD_PRODUCT:begin product<=operand_a*operand_b;state<=HEAD_ADD;end
 HEAD_ADD:begin
   if(head_index==31)begin
     scores[{orientation,output_index}]<=next_acc;head_index<=0;
     if(output_index==3)begin
       if(ENABLE_AU)begin head_index<=0;accumulator<=0;state<=ORI_REQ;end
       else if(!orientation)begin orientation<=1;hidden_index<=0;feature_index<=0;weight_word<=0;weight_slot<=0;accumulator<=bias1(0);state<=M_REQ;end
       else begin
         for(i=0;i<2;i=i+1)begin best[i]<=32'sh80000000;second[i]<=32'sh80000000;winner[i]<=0;end
         rank_index<=0;state<=RANK;
       end
     end else begin output_index<=output_index+1'b1;accumulator<=low_mode?low_bias2(output_index+2'd1):bias2(output_index+2'd1);state<=HEAD_REQ;end
   end else begin accumulator<=next_acc;head_index<=head_index+1'b1;state<=HEAD_REQ;end
 end
 RANK:begin
   if(scores[rank_index]>best[rank_index[2]])begin
     second[rank_index[2]]<=best[rank_index[2]];best[rank_index[2]]<=scores[rank_index];winner[rank_index[2]]<=rank_index[1:0];
   end else if(scores[rank_index]>second[rank_index[2]])second[rank_index[2]]<=scores[rank_index];
   if(rank_index==7)state<=CHOOSE;else rank_index<=rank_index+1'b1;
 end
 CHOOSE:begin
   margin0<=best[0]-second[0];margin1<=best[1]-second[1];
   happy_gap0<=scores[0]-scores[2];happy_gap1<=scores[4]-scores[6];
   selected<=(best[1]-second[1])>(best[0]-second[0]);
   au_orientation<=orientation_delta>0;
   orientation_confident<=orientation_delta>=21'sd128 || orientation_delta<= -21'sd128;
   state<=ENABLE_AU?AU_INIT:FINISH;
 end

 ORI_REQ:state<=ORI_PRODUCT;
 ORI_PRODUCT:begin product<=operand_a*operand_b;state<=ORI_ADD;end
 ORI_ADD:begin
  if(head_index==31)begin
   orientation_scores[orientation]<=next_acc[19:0];head_index<=0;
   if(ENABLE_MOUTH && ENABLE_CUE)begin head_index<=0;weight_word<=1014;au_slot<=0;accumulator<=0;state<=MOUTH_HEAD_REQ;end
   else begin
    if(!orientation)begin orientation<=1;hidden_index<=0;feature_index<=0;weight_word<=0;weight_slot<=0;accumulator<=bias1(0);state<=M_REQ;end
   else begin
    for(i=0;i<2;i=i+1)begin best[i]<=32'sh80000000;second[i]<=32'sh80000000;winner[i]<=0;end
    rank_index<=0;state<=RANK;
   end
   end
  end else begin accumulator<=next_acc;head_index<=head_index+1'b1;state<=ORI_REQ;end
 end

 AU_INIT:begin cue_phase<=0;cue_scores[0]<=0;cue_scores[1]<=0;cbrow_scores[0]<=0;cbrow_scores[1]<=0;au_feature_address<=59;hidden_index<=0;feature_index<=0;weight_word<=0;au_slot<=0;accumulator<=au_bias1(0);state<=AU_REQ;end
 AU_REQ:state<=AU_PRODUCT;
 AU_PRODUCT:begin product<=operand_a*operand_b;state<=AU_ADD;end
 AU_ADD:begin
  if(feature_index==1071)begin
   hidden[hidden_index]<=activation(next_acc);feature_index<=0;au_feature_address<=59;
   if(hidden_index==7)begin head_index<=0;au_output<=0;accumulator<=cue_phase==2?cbrow_bias2:(cue_phase==1?cue_bias2(0):au_bias2(0));weight_word<=954;au_slot<=0;state<=AU_HEAD_REQ;end
   else begin hidden_index<=hidden_index+1'b1;weight_word<=au_start_word(hidden_index+3'd1);au_slot<=au_start_slot(hidden_index+3'd1);accumulator<=cue_phase==2?cbrow_bias1:(cue_phase==1?cue_bias1(hidden_index+3'd1):au_bias1(hidden_index+3'd1));state<=AU_REQ;end
  end else begin
   accumulator<=next_acc;feature_index<=feature_index+1'b1;
   case(feature_index)
    117:au_feature_address<=295;235:au_feature_address<=531;
    353:au_feature_address<=767;471:au_feature_address<=1003;
    589:au_feature_address<=1239;707:au_feature_address<=1475;
    825:au_feature_address<=1711;943:au_feature_address<=1888;
    default:au_feature_address<=au_feature_address+1'b1;
   endcase
   if(au_slot==8)begin weight_word<=weight_word+1'b1;au_slot<=0;end else au_slot<=au_slot+1'b1;
   state<=AU_REQ;
  end
 end
 AU_HEAD_REQ:state<=AU_HEAD_PRODUCT;
 AU_HEAD_PRODUCT:begin product<=operand_a*operand_b;state<=AU_HEAD_ADD;end
 AU_HEAD_ADD:begin
  if(head_index==7)begin
   if(cue_phase==2)cbrow_scores[au_output[0]]<=au_saturate(next_acc);
   else if(cue_phase==1)cue_scores[au_output[0]]<=au_saturate(next_acc);
   else au_scores[au_output]<=au_saturate(next_acc);
   head_index<=0;
   if(cue_phase==2 && au_output==1)state<=FINISH;
   else if(cue_phase==1 && au_output==1)begin
    if(ENABLE_MOUTH)begin au_feature_address<=531;feature_index<=0;weight_word<=958;au_slot<=0;accumulator<=mouth_partial[au_orientation]+mouth_bias(low_mode);state<=MOUTH_REQ;end
    else state<=FINISH;
   end
   else if(cue_phase==0 && au_output==5)begin
    if(ENABLE_CUE)begin
     cue_phase<=1;au_feature_address<=59;hidden_index<=0;feature_index<=0;weight_word<=0;au_slot<=0;accumulator<=cue_bias1(0);state<=AU_REQ;
    end else state<=FINISH;
   end
   else begin au_output<=au_output+1'b1;accumulator<=cue_phase==2?cbrow_bias2:(cue_phase==1?cue_bias2(au_output+3'd1):au_bias2(au_output+3'd1));weight_word<=weight_word+1'b1;au_slot<=0;state<=AU_HEAD_REQ;end
  end else begin
   accumulator<=next_acc;head_index<=head_index+1'b1;
   if(au_slot[1:0]==3)begin weight_word<=weight_word+1'b1;au_slot<=0;end else au_slot<=au_slot+1'b1;
   state<=AU_HEAD_REQ;
  end
 end

 MOUTH_HEAD_REQ:state<=MOUTH_HEAD_PRODUCT;
 MOUTH_HEAD_PRODUCT:begin product<=operand_a*operand_b;state<=MOUTH_HEAD_ADD;end
 MOUTH_HEAD_ADD:begin
  if(head_index==31)begin
   mouth_partial[orientation]<=next_acc;head_index<=0;
   if(!orientation)begin orientation<=1;hidden_index<=0;feature_index<=0;weight_word<=0;weight_slot<=0;accumulator<=bias1(0);state<=M_REQ;end
   else begin
    for(i=0;i<2;i=i+1)begin best[i]<=32'sh80000000;second[i]<=32'sh80000000;winner[i]<=0;end
    rank_index<=0;state<=RANK;
   end
  end else begin
   accumulator<=next_acc;head_index<=head_index+1'b1;
   if(au_slot[1:0]==3)begin weight_word<=weight_word+1'b1;au_slot<=0;end else au_slot<=au_slot+1'b1;
   state<=MOUTH_HEAD_REQ;
  end
 end
 MOUTH_REQ:state<=MOUTH_PRODUCT;
 MOUTH_PRODUCT:begin product<=operand_a*operand_b;state<=MOUTH_ADD;end
 MOUTH_ADD:begin
  if(feature_index==503)begin
   mouth_score<=au_saturate(next_acc);
   if(ENABLE_CBROW)begin cue_phase<=2;au_feature_address<=59;hidden_index<=0;feature_index<=0;weight_word<=0;au_slot<=0;accumulator<=cbrow_bias1;state<=AU_REQ;end
   else state<=FINISH;
  end
  else begin
   accumulator<=next_acc;feature_index<=feature_index+1'b1;
   case(feature_index)
    117:au_feature_address<=767;235:au_feature_address<=1475;353:au_feature_address<=1711;
    471:au_feature_address<=1960;487:au_feature_address<=1992;
    default:au_feature_address<=au_feature_address+1'b1;
   endcase
   if(au_slot==8)begin weight_word<=weight_word+1'b1;au_slot<=0;end else au_slot<=au_slot+1'b1;
   state<=MOUTH_REQ;
  end
 end

 FINISH:begin
   O_diagnostic<={1'b1,selected,final_winner,final_rejection,(ENABLE_AU?au_debug:scores[{selected,2'd3}]),(FULL_SCORE_DEBUG?scores[{selected,2'd2}]:32'd0),(FULL_SCORE_DEBUG?scores[{selected,2'd1}]:32'd0),(FULL_SCORE_DEBUG?scores[{selected,2'd0}]:32'd0),(ENABLE_CBROW?(chosen_margin>32'sd65535 ? 32'd65535:chosen_margin):chosen_margin)};
   O_label<=final_rejection==0?final_winner+2'd1:2'd0;
   O_busy<=0;O_done<=1;state<=IDLE;
 end
 default:state<=IDLE;
 endcase
 end end
endmodule
