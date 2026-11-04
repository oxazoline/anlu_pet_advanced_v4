// Shared capture/detection integral image, 160x90 active entries, unsigned 22 bits.
module ext_face_integral_ram(input wire I_clk,input wire I_write,
    input wire [13:0] I_address,input wire [21:0] I_data,
    output wire [21:0] O_previous);
    PH1P_LOGIC_ERAM #(
        .DATA_WIDTH_A(22),.DATA_WIDTH_B(22),
        .ADDR_WIDTH_A(14),.ADDR_WIDTH_B(14),
        .DATA_DEPTH_A(16384),.DATA_DEPTH_B(16384),
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
        .addrb(14'd0),.dib(22'd0),.dob(),.beb(1'b0),
        .ecc_sbiterrinj(1'b0),.ecc_dbiterrinj(1'b0),.ecc_sbiterr(),.ecc_dbiterr()
    );
endmodule
