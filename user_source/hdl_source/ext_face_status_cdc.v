// Request has one extra settling stage relative to the sampled data bus.
// Latest-value bundled-data handshake. Source bus remains held until ack.
// V19: publish the latest snapshot whenever idle; duplicate values are legal.
// Removing the WIDTH-wide held!=input feedback keeps the CE path short.
// Intermediate updates may coalesce; the final stable status always arrives.
module ext_face_status_cdc #(parameter integer WIDTH=32)(
    input wire I_src_clk,I_dst_clk,I_rst_n,
    input wire [WIDTH-1:0] I_status,
    output reg [WIDTH-1:0] O_status
);
    reg [WIDTH-1:0] held;
    reg request,seen;
    (* ASYNC_REG="TRUE" *) reg [1:0] ack_sync;
 (* ASYNC_REG="TRUE" *) reg [2:0] request_sync;
    (* ASYNC_REG="TRUE" *) reg [WIDTH-1:0] data_meta,data_sync;
    always @(posedge I_src_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin held<=0;request<=0;ack_sync<=0;end
        else begin
            ack_sync<={ack_sync[0],seen};
            if(request==ack_sync[1])begin held<=I_status;request<=~request;end
        end
    end
    always @(posedge I_dst_clk or negedge I_rst_n)begin
        if(!I_rst_n)begin
            request_sync<=0;data_meta<=0;data_sync<=0;seen<=0;O_status<=0;
        end else begin
            request_sync<={request_sync[1:0],request};
            data_meta<=held;data_sync<=data_meta;
            if(request_sync[2]!=seen)begin O_status<=data_sync;seen<=request_sync[2];end
        end
    end
endmodule
