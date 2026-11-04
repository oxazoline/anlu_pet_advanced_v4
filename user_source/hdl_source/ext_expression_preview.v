// Request has one extra settling stage relative to the sampled data bus.
// Double-buffered expression patch preview. Only complete accepted captures
// publish; frame-boundary acknowledgement prevents writes to the display bank.
// A busy preview drops an entire patch; inference/video never stall.
module ext_expression_preview(
 input wire I_src_clk,I_dst_clk,I_rst_n,
 input wire I_write,input wire [9:0] I_write_address,input wire [7:0] I_pixel,
 input wire I_commit,input wire [7:0] I_patch_id,input wire I_vs,
 input wire [9:0] I_read_address,output wire [7:0] O_gray,
 output reg O_valid,output reg [7:0] O_patch_id);
 (* ram_style="block" *) reg [7:0] memory[0:2047];
 reg write_bank,display_bank,held_bank,request,seen,capture_accept;
 reg [10:0] write_count;reg [7:0] held_id;
 (* ASYNC_REG="TRUE" *) reg [1:0] ack_sync;
 (* ASYNC_REG="TRUE" *) reg [2:0] request_sync;
 (* ASYNC_REG="TRUE" *) reg [8:0] data_meta,data_sync;
 reg vs_d;reg [7:0] q;
 wire ready=request==ack_sync[1];
 wire allow_write=I_write && (I_write_address==0?ready:capture_accept);
 always @(posedge I_src_clk)if(I_rst_n && allow_write)memory[{write_bank,I_write_address}]<=I_pixel;
 always @(posedge I_dst_clk)q<=memory[{display_bank,I_read_address}];
 assign O_gray=O_valid?q:8'd0;
 always @(posedge I_src_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin
   write_bank<=0;held_bank<=0;held_id<=0;request<=0;ack_sync<=0;capture_accept<=0;write_count<=0;
  end else begin
   ack_sync<={ack_sync[0],seen};
   if(I_write)begin
    if(I_write_address==0)begin capture_accept<=ready;write_count<=ready?11'd1:11'd0;end
    else if(capture_accept)begin
     if(write_count[9:0]!=I_write_address || write_count==1024)capture_accept<=0;
     else write_count<=write_count+1'b1;
    end
   end
   if(I_commit)begin
    if(capture_accept && write_count==1024 && ready)begin
     held_bank<=write_bank;held_id<=I_patch_id;request<=~request;write_bank<=~write_bank;
    end
    capture_accept<=0;write_count<=0;
   end
  end
 end
 always @(posedge I_dst_clk or negedge I_rst_n)begin
  if(!I_rst_n)begin
   display_bank<=1;request_sync<=0;data_meta<=0;data_sync<=0;seen<=0;vs_d<=0;O_valid<=0;O_patch_id<=0;
  end else begin
   request_sync<={request_sync[1:0],request};data_meta<={held_bank,held_id};data_sync<=data_meta;vs_d<=I_vs;
   if(I_vs && !vs_d && request_sync[2]!=seen)begin
    display_bank<=data_sync[8];O_patch_id<=data_sync[7:0];O_valid<=1;seen<=request_sync[2];
   end
  end
 end
endmodule
