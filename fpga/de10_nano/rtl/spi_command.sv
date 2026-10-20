module spi_command #(
    parameter           FIFO_DEPTH 8
    ) (
    input wire                              clk,
    input wire                              rst_n,

    input wire [7:0]                        rx_byte,
    input wire                              rx_valid,
    input wire [$clog2(FIFO_DEPTH+1)-1:0]   fifo_count,

    input wire [63:0]                       fifo_read_data, 
    input wire                              fifo_empty,

    output reg [7:0]                        tx_byte,
    output reg                              tx_valid,

    output reg                              fifo_read_en
    );


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_byte <= 8'h00;
            tx_load <= 1'b0;

        if (rx_valid) begin
            if (rx_byte == 0'h00) begin              // PING
                tx_byte <= 8'hA5;
                tx_load <= 1'b0;
            end else if (rx_byte == 0'h01) begin
                tx_byte <= {0'b0000, fifo_count};
                tx_load <= 1'b0;
        end
    end
endmodule;
