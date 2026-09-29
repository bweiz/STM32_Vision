 module top (
    input wire  FPGA_CLK1_50,
    input wire  rst_n,
    input wire  GPIO_EVENT,
    output wire LED0
);

    assign LED0 = GPIO_EVENT;
    wire event_sync;

    cdc_sync u_cdc_sync (
        .clk            (FPGA_CLK1_50),
        .rst_n          (rst_n),
        .async_event_in (GPIO_EVENT),
        .event_sync     (event_sync)
    );

endmodule

