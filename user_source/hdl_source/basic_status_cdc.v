// Latest-value bundled-data handshake. Source bus remains held until ack.
// Intermediate updates may coalesce; the final stable status always arrives.
module basic_status_cdc(
    input wire I_src_clk,I_dst_clk,I_rst_n,
    input wire [7:0] I_status,
    output reg [7:0] O_status
);
    reg [7:0] held;
    reg request,seen;
    (* ASYNC_REG="TRUE" *) reg [1:0] ack_sync,request_sync;
    (* ASYNC_REG="TRUE" *) reg [7:0] data_meta,data_sync;
    always @(posedge I_src_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin held<=0;request<=0;ack_sync<=0;end
        else begin
            ack_sync<={ack_sync[0],seen};
            if(request==ack_sync[1] && held!=I_status)begin held<=I_status;request<=~request;end
        end
    end
    always @(posedge I_dst_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin
            request_sync<=0;data_meta<=0;data_sync<=0;seen<=0;O_status<=0;
        end else begin
            request_sync<={request_sync[0],request};
            data_meta<=held;data_sync<=data_meta;
            if(request_sync[1]!=seen)begin O_status<=data_sync;seen<=request_sync[1];end
        end
    end
endmodule
