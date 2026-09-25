module cdc_sync(
    input  wire         clk,
    input  wire         rst_n,
    input  wire         async_event_in,
    output wire         event_sync
    )

    reg event_meta;     // First sync flop
    reg event_sync_d;  // Second sync flop

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            event_meta      <= 1'b0;
            event_sync_d    <= 1'b0;
        else begin
            event_meta      <= async_event_in;
            event_sync_d    <= event_meta;
        end
    end 
    assign event_sync       = event_sync_d;
endmodule
