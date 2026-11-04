// Functional PH1P ODDR model for serializer reset/bit-equivalence regression.
// Not a timing model. Actual timing is checked by the TD routed report.
module PH1P_LOGIC_ODDR(input clk,rst,d0,d1,output reg q);
 always @(posedge clk or posedge rst)if(rst)q<=0;else q<=d0;
 always @(negedge clk or posedge rst)if(rst)q<=0;else q<=d1;
endmodule
