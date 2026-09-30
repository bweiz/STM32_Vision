module timestamp_counter (
    input wire clk,
    input wire rst_n,
    output reg [63:0] count
    );


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 64'd0;
        end else begin
            count <= count + 64'd1;
        end
    end
endmodule
