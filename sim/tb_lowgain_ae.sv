`timescale 1ns/1ps
module tb_lowgain_ae;
    reg clk=0,rst=1,done=1,configured=0;
    reg [3:0] buttons=15;
    wire req;wire [15:0] exposure,gain;
    wire [23:0] gain_regs,table_data;
    reg [8:0] index=0;wire [8:0] size;
    integer writes=0,i;reg [15:0] held;
    always #5 clk=~clk;
    ae_set #(.CLK_HZ(1000),.DEBOUNCE_CYCLES(3),.REPEAT_CYCLES(12))
        dut(clk,rst,buttons,done,configured,req,exposure,gain);
    SC520GainTbl gain_table(gain,gain_regs);
    uics520regAE exposure_table(index,table_data,size,exposure,gain_regs);
    // Slow eight-register bus transaction; buttons may change while busy.
    always begin
        @(posedge clk);#1;
        if(req) begin
            writes=writes+1;held=exposure;done=0;
            for(i=0;i<8;i=i+1) begin
                @(negedge clk);index=i;#1;
                if(exposure!==held||gain_regs!==24'h0f0080)$fatal(1,"I2C transaction changed mid-write");
                case(i)
                    0:if(table_data!==24'h381200)$fatal(1,"group hold missing");
                    1:if(table_data!=={16'h3e00,4'h0,held[15:12]})$fatal(1,"exposure high");
                    2:if(table_data!=={16'h3e01,held[11:4]})$fatal(1,"exposure middle");
                    3:if(table_data!=={16'h3e02,held[3:0],4'h0})$fatal(1,"exposure low");
                    4:if(table_data!==24'h3e090f)$fatal(1,"16x analog register");
                    5:if(table_data!==24'h3e0600)$fatal(1,"digital coarse register");
                    6:if(table_data!==24'h3e0780)$fatal(1,"unity digital fine register");
                    7:if(table_data!==24'h381230)$fatal(1,"group release missing");
                endcase
            end
            @(negedge clk);done=1;
        end
    end
    initial begin
        repeat(4)@(negedge clk);rst=0;
        repeat(5)@(negedge clk);
        if(req||writes!=0)$fatal(1,"write before camera configured");
        configured=1;repeat(30)@(negedge clk);
        if(exposure!==3991||gain!==144||writes!=1||size!=8)$fatal(1,"low-gain defaults");
        buttons=14;repeat(400)@(negedge clk);buttons=15;repeat(30)@(negedge clk);
        if(exposure!==4)$fatal(1,"K1 minimum clamp");
        buttons=13;repeat(700)@(negedge clk);buttons=15;repeat(30)@(negedge clk);
        if(exposure!==3991)$fatal(1,"K2 maximum clamp");
        held=exposure;buttons=12;repeat(60)@(negedge clk);buttons=15;repeat(20)@(negedge clk);
        if(exposure!==3991)$fatal(1,"both buttons should not adjust");
        buttons=14;@(negedge clk);buttons=15;repeat(20)@(negedge clk);
        if(exposure!==3991)$fatal(1,"button bounce accepted");
        $display("PASS AE: 16x analog/unity digital, grouped eight-register writes, defaults/buttons/debounce/clamps; writes=%0d",writes);$finish;
    end
    initial begin #100000;$fatal(1,"timeout");end
endmodule
