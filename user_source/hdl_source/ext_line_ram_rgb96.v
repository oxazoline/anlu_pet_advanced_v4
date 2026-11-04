// Native synchronous read-before-write line store. Exactly one read cycle.
// 96-bit pixels x 512 words; implementation can split across 20K blocks.
// No reset of RAM contents. The caller masks history on the first row.
module ext_line_ram_rgb96(input wire I_clk,input wire I_write,
    input wire [8:0] I_address,input wire [95:0] I_data,
    output wire [95:0] O_previous);
    PH1P_LOGIC_ERAM #(
        .DATA_WIDTH_A(96),.DATA_WIDTH_B(96),
        .ADDR_WIDTH_A(9),.ADDR_WIDTH_B(9),
        .DATA_DEPTH_A(512),.DATA_DEPTH_B(512),
        .MODE("SP"),.REGMODE_A("NOREG"),.REGMODE_B("NOREG"),
        .WRITEMODE_A("READBEFOREWRITE"),.WRITEMODE_B("NORMAL"),
        .CLKMODE("ASYNC"),.IMPLEMENT("20K(FAST)"),
        .OREGSET_A("RESET"),.OREGSET_B("RESET"),
        .SSROVERCE("DISABLE"),.ASYNC_RESET_RELEASE_A("ASYNC"),
        .ASYNC_RESET_RELEASE_B("ASYNC")
    ) line_store(
        .clka(I_clk),.cea(1'b1),.ocea(1'b0),.wea(I_write),.rsta(1'b0),
        .addra(I_address),.dia(I_data),.doa(O_previous),.bea(1'b0),
        .clkb(I_clk),.ceb(1'b0),.oceb(1'b0),.web(1'b0),.rstb(1'b0),
        .addrb(9'd0),.dib(96'd0),.dob(),.beb(1'b0),
        .ecc_sbiterrinj(1'b0),.ecc_dbiterrinj(1'b0),.ecc_sbiterr(),.ecc_dbiterr()
    );
endmodule
