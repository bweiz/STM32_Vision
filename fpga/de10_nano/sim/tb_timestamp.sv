`timescale 1ns/1ps

module tb_timestamp;

    reg clk;
    reg rst_n;
    reg async_event_in;

    wire event_sync;
    wire [63:0] count;
    wire [63:0] timestamp;
    wire timestamp_valid;

    integer valid_count;
    reg [63:0] timestamp_1;
    reg [63:0] timestamp_2;

    // 50 MHz clock = 20 ns period
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    cdc_sync u_cdc_sync (
        .clk            (clk),
        .rst_n          (rst_n),
        .async_event_in (async_event_in),
        .event_sync     (event_sync)
    );

    timestamp_counter u_timestamp_counter (
        .clk   (clk),
        .rst_n (rst_n),
        .count (count)
    );

    event_capture u_event_capture (
        .clk             (clk),
        .rst_n           (rst_n),
        .event_sync      (event_sync),
        .count           (count),
        .timestamp       (timestamp),
        .timestamp_valid (timestamp_valid)
    );

    // Count every timestamp capture
    always @(posedge timestamp_valid) begin
        valid_count = valid_count + 1;

        if (valid_count == 1)
            timestamp_1 = timestamp;

        if (valid_count == 2)
            timestamp_2 = timestamp;

        $display(
            "CAPTURE %0d: sim_time=%0t ns timestamp=%0d",
            valid_count,
            $time,
            timestamp
        );
    end

    initial begin

        $dumpfile("sim/timestamp.vcd");
        $dumpvars(0, tb_timestamp);

        valid_count   = 0;
        timestamp_1   = 0;
        timestamp_2   = 0;

        rst_n          = 0;
        async_event_in = 0;

        // Hold reset for several clocks
        #100;
        rst_n = 1;

        // Don't align this event perfectly with the FPGA clock.
        // It is supposed to be asynchronous.
        #137;

        // Event #1
        async_event_in = 1;

        // Keep HIGH a long time.
        // This should STILL cause only one timestamp.
        #500;
        async_event_in = 0;

        #300;

        // After first complete event, exactly one capture should exist
        if (valid_count != 1) begin
            $fatal(1,
                "FAIL: expected 1 capture after first event, got %0d",
                valid_count
            );
        end

        // Event #2
        #73;
        async_event_in = 1;
        #400;
        async_event_in = 0;

        #300;

        if (valid_count != 2) begin
            $fatal(1,
                "FAIL: expected 2 total captures, got %0d",
                valid_count
            );
        end

        if (timestamp_2 <= timestamp_1) begin
            $fatal(1,
                "FAIL: second timestamp (%0d) is not later than first (%0d)",
                timestamp_2,
                timestamp_1
            );
        end

        $display("");
        $display("PASS");
        $display("timestamp 1 = %0d", timestamp_1);
        $display("timestamp 2 = %0d", timestamp_2);
        $display("delta       = %0d FPGA clocks",
                 timestamp_2 - timestamp_1);
        $display("delta       = %0d ns",
                 (timestamp_2 - timestamp_1) * 20);

        $finish;
    end

endmodule
