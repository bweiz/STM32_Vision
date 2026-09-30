module event_capture(
    input wire          clk,
    input wire          rst_n,
    input wire          event_sync,
    input wire [63:0]   count,
    output reg [63:0]   timestamp,
    output reg          timestamp_valid
);

    reg                 event_prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            event_prev      <= 1'b0;
            timestamp       <= 64'd0;
            timestamp_valid <= 1'b0;
        end else begin
            event_prev      <= event_sync;
            timestamp_valid <= 1'b0;

            if (event_sync && !event_prev) begin
                timestamp       <= count;
                timestamp_valid <= 1'b1;
        end

        
        end
    end
endmodule
