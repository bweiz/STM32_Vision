 module top (
    input wire  FPGA_CLK1_50,
    input wire  rst_n,
    input wire  GPIO_EVENT,
    output wire LED0
);

    wire event_sync;
    wire [63:0] count;
    wire [63:0] timestamp;
    wire        timestamp_valid;

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

endmodule

