// Functional model for V2's native SP read-before-write line store only.
// No timing delay is modeled. TD physical mapping/STA must be checked separately.
module PH1P_LOGIC_ERAM #(
    parameter DATA_WIDTH_A=96,DATA_WIDTH_B=96,ADDR_WIDTH_A=9,ADDR_WIDTH_B=9,
    DATA_DEPTH_A=512,DATA_DEPTH_B=512,MODE="SP",REGMODE_A="NOREG",REGMODE_B="NOREG",
    WRITEMODE_A="READBEFOREWRITE",WRITEMODE_B="NORMAL",CLKMODE="ASYNC",IMPLEMENT="20K(FAST)",
    OREGSET_A="RESET",OREGSET_B="RESET",SSROVERCE="DISABLE",
    ASYNC_RESET_RELEASE_A="ASYNC",ASYNC_RESET_RELEASE_B="ASYNC",INIT_FILE="NONE",FORCE_KEEP="OFF"
)(input clka,cea,ocea,wea,rsta,input [ADDR_WIDTH_A-1:0] addra,
    input [DATA_WIDTH_A-1:0] dia,output reg [DATA_WIDTH_A-1:0] doa,input bea,
    input clkb,ceb,oceb,web,rstb,input [ADDR_WIDTH_B-1:0] addrb,
    input [DATA_WIDTH_B-1:0] dib,output [DATA_WIDTH_B-1:0] dob,input beb,
    input ecc_sbiterrinj,ecc_dbiterrinj,output ecc_sbiterr,ecc_dbiterr);
    reg [DATA_WIDTH_A-1:0] memory[0:DATA_DEPTH_A-1];
    initial if(INIT_FILE!="NONE")$readmemh(INIT_FILE,memory);
    initial if(MODE!="SP" || WRITEMODE_A!="READBEFOREWRITE" || REGMODE_A!="NOREG")
        $fatal(1,"functional model supports only the V2 single-port configuration");
    always @(posedge clka)if(cea)begin doa<=memory[addra];if(wea)memory[addra]<=dia;end
    assign dob=0;assign ecc_sbiterr=0;assign ecc_dbiterr=0;
endmodule
