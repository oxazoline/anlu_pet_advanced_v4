// V3 adaptive contrast template of the exact printed reference; not general OCR.
module adv_ref_rows(input wire [4:0] I_row,output reg [31:0] O_exact,O_support,O_exact1,O_support1,O_exact2,O_support2);
always @(*)case(I_row)
5'd0:begin O_exact=32'h08080040;O_support=32'h1e1c00e0;O_exact1=32'h10100040;O_support1=32'h3c3800e0;O_exact2=32'h10080020;O_support2=32'h3c1c00f0;end
5'd1:begin O_exact=32'h04080040;O_support=32'h1f3e00e0;O_exact1=32'h08000040;O_support1=32'h3c3c00e0;O_exact2=32'h08080060;O_support2=32'h3c1e00f0;end
5'd2:begin O_exact=32'h02140040;O_support=32'h0fff0ee7;O_exact1=32'h08180040;O_support1=32'h1ffe1ce7;O_exact2=32'h080c0020;O_support2=32'h1e3e00f0;end
5'd3:begin O_exact=32'h03220442;O_support=32'h07ff0eef;O_exact1=32'h06640842;O_support1=32'h1fff1fef;O_exact2=32'h04140020;O_support2=32'h1f7f0e73;end
5'd4:begin O_exact=32'h01080044;O_support=32'h07ff8fff;O_exact1=32'h03120644;O_support1=32'h0fff1fff;O_exact2=32'h06220421;O_support2=32'h0fff8f77;end
5'd5:begin O_exact=32'h00b10248;O_support=32'hf3ffc7fe;O_exact1=32'h017a0248;O_support1=32'he7ff0ffe;O_exact2=32'h03090222;O_support2=32'h0fff8fff;end
5'd6:begin O_exact=32'h60e48150;O_support=32'hfdffffff;O_exact1=32'hc1c80050;O_support1=32'hfbff07ff;O_exact2=32'h01310324;O_support2=32'hc7ff87ff;end
5'd7:begin O_exact=32'h38ac1dbf;O_support=32'hffffffff;O_exact1=32'h3158000f;O_support1=32'hfbfc00ff;O_exact2=32'h81a601ac;O_support2=32'hffff87ff;end
5'd8:begin O_exact=32'h26b40040;O_support=32'h7ffe3fff;O_exact1=32'h40180000;O_support1=32'hfbfc0f3f;O_exact2=32'hd92c0021;O_support2=32'hffff03ff;end
5'd9:begin O_exact=32'h18040250;O_support=32'h7ffe0ffc;O_exact1=32'h31280610;O_support1=32'hfbfc1f3c;O_exact2=32'h411c0170;O_support2=32'hfffe07ff;end
5'd10:begin O_exact=32'h10840448;O_support=32'h3dfe0ffc;O_exact1=32'h71680808;O_support1=32'hfbfc3ffe;O_exact2=32'h71040368;O_support2=32'hfbfe07fe;end
5'd11:begin O_exact=32'h18a40040;O_support=32'hfffe1efe;O_exact1=32'h91c81044;O_support1=32'hfffc7cff;O_exact2=32'h21240264;O_support2=32'hfbfe1fff;end
5'd12:begin O_exact=32'h6ca40844;O_support=32'hfffe3cee;O_exact1=32'h09082042;O_support1=32'hfffcf8ef;O_exact2=32'h71240c22;O_support2=32'hfbfe1fff;end
5'd13:begin O_exact=32'h848c1040;O_support=32'hfffefcee;O_exact1=32'h04884041;O_support1=32'h1fdcf0e7;O_exact2=32'h91f40822;O_support2=32'hfffe7e77;end
5'd14:begin O_exact=32'h02444040;O_support=32'hcffef8e0;O_exact1=32'h00800000;O_support1=32'h0fdce0e3;O_exact2=32'h088c3021;O_support2=32'hfffefc77;end
5'd15:begin O_exact=32'h00400040;O_support=32'h07eee0e0;O_exact1=32'h00800000;O_support1=32'h01c00000;O_exact2=32'h04846020;O_support2=32'h1fdef873;end
default:begin O_exact=0;O_support=0;O_exact1=0;O_support1=0;O_exact2=0;O_support2=0;end endcase
endmodule
