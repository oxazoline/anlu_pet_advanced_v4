`timescale 1ns/1ps
module tb_i2c_diagnostics;
    reg clk=0,disp=0,rst=0,error_in=0,running=0;
    always #5 clk=~clk;always #7 disp=~disp;
    wire history,event_out;wire [15:0] boot_count,run_count;
    wire [15:0] first_address,last_address;
    tri1 sda;
    uicfgcs520 #(.CLK_DIV(5)) config_dut(.I_clk(clk),.I_rst_n(rst),
        .I_ae_req(1'b0),.I_ae(16'd1996),.I_ag(16'd80),.IO_cam_sda(sda),
        .O_iic_error(history),.O_iic_error_event(event_out),
        .O_first_error_addr(first_address),.O_last_error_addr(last_address));
    basic_fault_counter counter(clk,disp,rst,event_out,running,boot_count,run_count);
    initial begin
        force config_dut.iic_bus_error=error_in;
        force config_dut.wr_data=32'h0012386c;
        repeat(5)@(negedge clk);rst=1;
        repeat(6)@(negedge clk);error_in=1;
        repeat(20)@(negedge clk);error_in=0;
        repeat(15)@(negedge disp);
        if(boot_count!==1||run_count!==0||!history)$fatal(1,"BOOT bus fault count/history");
        if(first_address!==16'h3812||last_address!==16'h3812)$fatal(1,"first transaction address");
        force config_dut.wr_data=32'h0f093e6c;
        running=1;repeat(6)@(negedge clk);error_in=1;
        repeat(20)@(negedge clk);error_in=0;
        repeat(15)@(negedge disp);
        if(boot_count!==1||run_count!==1||!history)$fatal(1,"repeated RUN bus error hidden by sticky history");
        if(first_address!==16'h3812||last_address!==16'h3e09)$fatal(1,"history address overwritten or last address missing");
        error_in=1;repeat(20)@(negedge clk);error_in=0;
        repeat(15)@(negedge disp);
        if(run_count!==2)$fatal(1,"held bus error must count once per assertion");
        $display("PASS I2C DIAG: BOOT error retained, repeated RUN errors counted despite sticky history, held-level qualification");$finish;
    end
    initial begin #20000;$fatal(1,"timeout");end
endmodule
