 module top (
    input wire  FPGA_CLK1_50,
    input wire  rst_n,
    input wire  GPIO_EVENT,
    output wire LED0
);

    wire        event_sync;
    wire [63:0] count;
    wire [63:0] timestamp;
    wire        timestamp_valid;

    //fifo
    wire        read_en;
    wire [63:0] read_data;
    wire        full;
    wire        empty;
    wire [$clog2(8+1)-1:0] fifo_count;

    assign read_en = 1'b0;      // No reader yet

    cdc_sync u_cdc_sync (
        .clk             (FPGA_CLK1_50),
        .rst_n           (rst_n),
        .async_event_in  (GPIO_EVENT),
        .event_sync      (event_sync)
    );

    event_capture u_event_capture (
        .clk             (FPGA_CLK1_50),
        .rst_n           (rst_n),
        .event_sync      (event_sync),
        .count           (count),
        .timestamp       (timestamp),
        .timestamp_valid (timestamp_valid)
    );

    timestamp_counter u_timestamp_counter (
        .clk             (FPGA_CLK1_50),
        .rst_n           (rst_n),
        .count           (count)
    );
    fifo #(
        .DEPTH(8),
        .DATA_WIDTH(64)
        ) 
    u_fifo (
        .clk            (FPGA_CLK1_50),
        .rst_n          (rst_n),
        .write_data     (timestamp),
        .write_en       (timestamp_valid),
        .read_en        (read_en),
        .read_data      (read_data),
        .full           (full),
        .empty          (empty),
        .count          (fifo_count)
    );
endmodule

