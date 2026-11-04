`timescale 1ns/1ps
// Pin-driven open-drain sensor model: no force of DUT state, ACK or read data.
module sc520_i2c_model #(parameter integer DROP_FIRST_GROUP=0)(input rst_n,input scl,inout sda,input reject_exposure);
    reg drive_low=0,active=0,reading=0,read_requested=0,device_ok=0;
    integer bits=0,bytes_in=0;
    reg [7:0] shift=0,tx=0;
    reg [15:0] pointer=0;
    reg [7:0] memory[0:65535];
    reg nack_byte=0;
    integer i;reg dropping_group=0,dropped_group=0;integer grouped_writes=0;
    assign sda=drive_low?1'b0:1'bz;
    always @(negedge rst_n)begin
        drive_low=0;active=0;reading=0;read_requested=0;device_ok=0;
        bits=0;bytes_in=0;pointer=0;nack_byte=0;dropping_group=0;dropped_group=0;grouped_writes=0;
        for(i=0;i<65536;i=i+1)memory[i]=0;
        memory[16'h3107]=8'hee;memory[16'h3108]=8'h4b;
    end
    always @(negedge sda)if(rst_n && scl===1'b1)begin
        active=1;reading=0;read_requested=0;bits=0;bytes_in=0;shift=0;nack_byte=0;
    end
    always @(posedge sda)if(rst_n && scl===1'b1)begin active=0;drive_low=0;end
    always @(posedge scl)if(rst_n && active)begin
        if(reading)begin
            if(bits<8)bits=bits+1;
            else begin
                bits=0;pointer=pointer+1;
                if(sda===1'b1)begin active=0;reading=0;drive_low=0;end
                else tx=memory[pointer];
            end
        end else if(bits<8)begin
            shift={shift[6:0],sda};bits=bits+1;
            if(bits==8)begin
                if($test$plusargs("bus_trace"))$display("BUS byte %0d=%h ptr=%h time=%t",bytes_in,shift,pointer,$time);
                nack_byte=0;
                case(bytes_in)
                    0:begin device_ok=shift[7:1]==7'h36;read_requested=shift[0];nack_byte=!device_ok;end
                    1:pointer[15:8]=shift;
                    2:pointer[7:0]=shift;
                    default:begin
                        nack_byte=reject_exposure && pointer==16'h3e02;
                        if(pointer==16'h3812 && shift==0)begin
                            grouped_writes=grouped_writes+1;
                            dropping_group=DROP_FIRST_GROUP && !dropped_group;
                        end
                        if(!nack_byte && !(dropping_group && pointer>=16'h3e00 && pointer<=16'h3e02))memory[pointer]=shift;
                        if(pointer==16'h3812 && shift==8'h30 && dropping_group)begin dropping_group=0;dropped_group=1;end
                        pointer=pointer+1;
                    end
                endcase
            end
        end else begin
            bits=0;bytes_in=bytes_in+1;
            if(bytes_in==1 && read_requested && device_ok)begin
                reading=1;tx=memory[pointer];
                if($test$plusargs("bus_trace"))$display("BUS READ %h=%h time=%t",pointer,tx,$time);
            end
        end
    end
    always @(negedge scl)begin
        if(!rst_n || !active)drive_low=0;
        else if(reading)drive_low=bits<8 ? !tx[7-bits] : 0;
        else drive_low=(bits==8 && !nack_byte && device_ok);
    end
endmodule

module tb_sensor_readback;
    reg clk=0,rst=0,req=0,reject=0;
    always #5 clk=~clk;
    tri1 sda;wire scl,configured,done,history,event_out,verified;
    wire [15:0] sensor_id,first_addr,last_addr;
    wire [47:0] readback;wire [5:0] mask;
    integer errors=0,test_case;
    uicfgcs520 #(.CLK_DIV(19),.RESET_WAIT_CYCLES(20),.VERIFY_WAIT_CYCLES(50)) dut(
        .I_clk(clk),.I_rst_n(rst),.I_ae_req(req),.I_ae(16'd3991),.I_ag(16'd144),
        .O_cam_scl(scl),.IO_cam_sda(sda),.O_cfg_done(configured),.O_ae_cfg_done(done),
        .O_sensor_id(sensor_id),.O_iic_error(history),.O_iic_error_event(event_out),
        .O_first_error_addr(first_addr),.O_last_error_addr(last_addr),
        .O_readback(readback),.O_verify_mask(mask),.O_verify_valid(verified));
    sc520_i2c_model sensor(rst,scl,sda,reject);
    always @(posedge clk)if(!rst)errors<=0;else if(event_out)errors<=errors+1;
    task update_ae;
        begin
            @(negedge clk);req=1;@(negedge clk);req=0;
            wait(!done);wait(verified && done);repeat(5)@(negedge clk);
        end
    endtask
    initial begin
        rst=1;#1;rst=0;
        for(test_case=0;test_case<2;test_case=test_case+1)begin
            reject=test_case==1;repeat(10)@(negedge clk);rst=1;
            wait(configured && done);
            if(sensor_id!==16'hee4b)$fatal(1,"sensor ID read over physical pins failed");
            update_ae;
            if(test_case==0)begin
                if(history||errors!=0||mask!==0||readback!==48'h00f9700f0080)
                    $fatal(1,"all-ACK readback failed: history=%b errors=%0d mask=%h readback=%h",history,errors,mask,readback);
            end else begin
                if(!history||errors==0||mask!==6'b000100||first_addr!==16'h3e02||last_addr!==16'h3e02)
                    $fatal(1,"3e02 NACK/mismatch not detected: errors=%0d mask=%h first=%h last=%h",errors,mask,first_addr,last_addr);
                reject=0;update_ae;
                if(mask!==0||readback!==48'h00f9700f0080||!history)
                    $fatal(1,"successful rewrite must clear current mismatch but retain history");
            end
            rst=0;repeat(5)@(negedge clk);
        end
        $display("PASS SENSOR READBACK: physical SCL/SDA, chip ID, init + grouped AE, six register reads, 3e02 NACK/mismatch, rewrite recovery/history");$finish;
    end
    initial begin #10000000;$fatal(1,"sensor protocol timeout state=%0d sensorID=%h bits=%0d bytes=%0d",dut.state,sensor_id,sensor.bits,sensor.bytes_in);end
endmodule
