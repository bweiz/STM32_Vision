`timescale 1ns/1ps

module tb_spi_protocol;

    localparam FIFO_DEPTH      = 8;
    localparam SPI_HALF_PERIOD = 500; // 1 MHz SPI

    // ------------------------------------------------
    // FPGA clock / reset
    // ------------------------------------------------

    reg clk;
    reg rst_n;


    // ------------------------------------------------
    // Physical SPI pins
    // ------------------------------------------------

    reg  spi_sclk;
    reg  spi_cs_n;
    reg  spi_mosi;
    wire spi_miso;


    // ------------------------------------------------
    // spi_slave <-> spi_command
    // ------------------------------------------------

    wire       spi_active;

    wire [7:0] spi_rx_byte;
    wire       spi_rx_valid;

    wire [7:0] spi_tx_byte;
    wire       spi_tx_load;


    // ------------------------------------------------
    // FIFO
    // ------------------------------------------------

    reg  [63:0] fifo_write_data;
    reg         fifo_write_en;

    wire [63:0] fifo_read_data;
    wire        fifo_read_en;

    wire        fifo_full;
    wire        fifo_empty;

    wire [$clog2(FIFO_DEPTH+1)-1:0] fifo_count;


    // ------------------------------------------------
    // Test variables
    // ------------------------------------------------

    reg [7:0]  rx_tmp;
    reg [63:0] event_rx;

    integer i;

    localparam [63:0] EVENT_1 =
        64'h1122334455667788;

    localparam [63:0] EVENT_2 =
        64'h99AABBCCDDEEFF00;


    // ============================================================
    // 50 MHz FPGA clock
    // ============================================================

    initial begin

        clk = 1'b0;

        forever #10 clk = ~clk;

    end


    // ============================================================
    // SPI slave
    // ============================================================

    spi_slave u_spi_slave (
        .clk        (clk),
        .rst_n      (rst_n),

        .spi_sclk   (spi_sclk),
        .spi_cs_n   (spi_cs_n),
        .spi_mosi   (spi_mosi),
        .spi_miso   (spi_miso),

        .spi_active (spi_active),

        .rx_byte    (spi_rx_byte),
        .rx_valid   (spi_rx_valid),

        .tx_byte    (spi_tx_byte),
        .tx_load    (spi_tx_load)
    );


    // ============================================================
    // SPI command layer
    // ============================================================

    spi_command #(
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_spi_command (
        .clk            (clk),
        .rst_n          (rst_n),

        .spi_active     (spi_active),

        .rx_byte        (spi_rx_byte),
        .rx_valid       (spi_rx_valid),

        .tx_byte        (spi_tx_byte),
        .tx_load        (spi_tx_load),

        .fifo_read_data (fifo_read_data),
        .fifo_empty     (fifo_empty),
        .fifo_count     (fifo_count),

        .fifo_read_en   (fifo_read_en)
    );


    // ============================================================
    // FIFO
    // ============================================================

    fifo #(
        .DEPTH      (FIFO_DEPTH),
        .DATA_WIDTH (64)
    ) u_fifo (
        .clk        (clk),
        .rst_n      (rst_n),

        .write_data (fifo_write_data),
        .write_en   (fifo_write_en),

        .read_en    (fifo_read_en),
        .read_data  (fifo_read_data),

        .full       (fifo_full),
        .empty      (fifo_empty),

        .count      (fifo_count)
    );


    // ============================================================
    // Reset
    // ============================================================

    task automatic reset_dut;

        begin

            rst_n          = 1'b0;

            spi_sclk       = 1'b0;
            spi_cs_n       = 1'b1;
            spi_mosi       = 1'b0;

            fifo_write_data = 64'h0;
            fifo_write_en   = 1'b0;

            repeat (5)
                @(posedge clk);

            @(negedge clk);

            rst_n = 1'b1;

            repeat (5)
                @(posedge clk);

            #1;

        end

    endtask


    // ============================================================
    // Push one value directly into FIFO
    //
    // We're intentionally bypassing event_capture here.
    // That subsystem already has its own tests.
    // ============================================================

    task automatic fifo_write (
        input [63:0] data
    );

        begin

            @(negedge clk);

            fifo_write_data = data;
            fifo_write_en   = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);

            fifo_write_en = 1'b0;

        end

    endtask


    // ============================================================
    // SPI select
    // ============================================================

    task automatic spi_select;

        begin

            spi_sclk = 1'b0;
            spi_cs_n = 1'b0;

            // Allow synchronized CS to propagate.
            repeat (5)
                @(posedge clk);

        end

    endtask


    // ============================================================
    // SPI deselect
    // ============================================================

    task automatic spi_deselect;

        begin

            spi_sclk = 1'b0;
            spi_cs_n = 1'b1;
            spi_mosi = 1'b0;

            repeat (5)
                @(posedge clk);

        end

    endtask


    // ============================================================
    // Transfer one full-duplex SPI byte
    //
    // Mode 0:
    //
    // MOSI set while SCLK low
    // sample MISO on rising edge
    // FPGA advances MISO on falling edge
    // ============================================================

    task automatic spi_transfer_byte (
        input  [7:0] tx_data,
        output [7:0] rx_data
    );

        integer bit_index;

        begin

            rx_data = 8'h00;

            for (
                bit_index = 7;
                bit_index >= 0;
                bit_index = bit_index - 1
            ) begin

                // Master prepares MOSI.
                spi_mosi = tx_data[bit_index];

                #(SPI_HALF_PERIOD);

                // Rising edge.
                spi_sclk = 1'b1;

                // Give FPGA model time to settle.
                #50;

                // Master samples MISO.
                rx_data[bit_index] = spi_miso;

                #(SPI_HALF_PERIOD - 50);

                // Falling edge.
                spi_sclk = 1'b0;

            end

            spi_mosi = 1'b0;

        end

    endtask


    // ============================================================
    // Read full 64-bit event through protocol
    //
    // command:
    //
    // MOSI:
    // 10 00 00 00 00 00 00 00 00
    //
    // MISO:
    // xx T7 T6 T5 T4 T3 T2 T1 T0
    // ============================================================

    task automatic spi_read_event (
        output [63:0] result
    );

        reg [7:0] byte_rx;
        integer byte_index;

        begin

            result = 64'h0;

            // Send READ_EVENT command.
            spi_transfer_byte(
                8'h10,
                byte_rx
            );

            // Clock out 8 response bytes.
            for (
                byte_index = 0;
                byte_index < 8;
                byte_index = byte_index + 1
            ) begin

                spi_transfer_byte(
                    8'h00,
                    byte_rx
                );

                // Build big-endian 64-bit result.
                result = {
                    result[55:0],
                    byte_rx
                };

            end

        end

    endtask


    // ============================================================
    // Timeout
    // ============================================================

    initial begin

        #1000000;

        $fatal(
            1,
            "FAIL: protocol simulation timeout"
        );

    end


    // ============================================================
    // Main
    // ============================================================

    initial begin

        $dumpfile("sim/spi_protocol.vcd");
        $dumpvars(0, tb_spi_protocol);

        reset_dut();


        // ========================================================
        // TEST 1
        // PING
        //
        // TX: 00 00
        // RX: xx A5
        // ========================================================

        $display("");
        $display("================================");
        $display("TEST 1: PING");
        $display("================================");

        spi_select();

        spi_transfer_byte(
            8'h00,
            rx_tmp
        );

        spi_transfer_byte(
            8'h00,
            rx_tmp
        );

        spi_deselect();


        if (rx_tmp !== 8'hA5) begin

            $fatal(
                1,
                "FAIL: PING expected 0xA5, got 0x%02h",
                rx_tmp
            );

        end


        $display(
            "PASS: PING returned 0xA5"
        );


        // ========================================================
        // TEST 2
        // STATUS while FIFO empty
        //
        // TX: 01 00
        // RX: xx 00
        // ========================================================

        $display("");
        $display("================================");
        $display("TEST 2: STATUS EMPTY");
        $display("================================");

        spi_select();

        spi_transfer_byte(
            8'h01,
            rx_tmp
        );

        spi_transfer_byte(
            8'h00,
            rx_tmp
        );

        spi_deselect();


        if (rx_tmp !== 8'h00) begin

            $fatal(
                1,
                "FAIL: empty STATUS expected 0, got %0d",
                rx_tmp
            );

        end


        $display(
            "PASS: STATUS returned count 0"
        );


        // ========================================================
        // Put two timestamps in FIFO
        // ========================================================

        fifo_write(EVENT_1);
        fifo_write(EVENT_2);

        #1;


        if (fifo_count != 2) begin

            $fatal(
                1,
                "FAIL: expected FIFO count 2, got %0d",
                fifo_count
            );

        end


        if (fifo_read_data !== EVENT_1) begin

            $fatal(
                1,
                "FAIL: FIFO peek expected EVENT_1"
            );

        end


        $display("");
        $display(
            "FIFO loaded with two test timestamps"
        );


        // ========================================================
        // TEST 3
        // STATUS should now return 2
        // ========================================================

        $display("");
        $display("================================");
        $display("TEST 3: STATUS COUNT = 2");
        $display("================================");

        spi_select();

        spi_transfer_byte(
            8'h01,
            rx_tmp
        );

        spi_transfer_byte(
            8'h00,
            rx_tmp
        );

        spi_deselect();


        if (rx_tmp !== 8'h02) begin

            $fatal(
                1,
                "FAIL: STATUS expected 2, got %0d",
                rx_tmp
            );

        end


        $display(
            "PASS: STATUS returned count 2"
        );


        // ========================================================
        // TEST 4
        // READ_EVENT #1
        // ========================================================

        $display("");
        $display("================================");
        $display("TEST 4: READ EVENT #1");
        $display("================================");

        spi_select();

        spi_read_event(event_rx);

        spi_deselect();

        // Allow FIFO consume pulse to settle.
        repeat (3)
            @(posedge clk);

        #1;


        $display(
            "READ_EVENT returned 0x%016h",
            event_rx
        );


        if (event_rx !== EVENT_1) begin

            $fatal(
                1,
                "FAIL: expected 0x%016h, got 0x%016h",
                EVENT_1,
                event_rx
            );

        end


        if (fifo_count != 1) begin

            $fatal(
                1,
                "FAIL: expected FIFO count 1, got %0d",
                fifo_count
            );

        end


        if (fifo_read_data !== EVENT_2) begin

            $fatal(
                1,
                "FAIL: FIFO did not advance to EVENT_2"
            );

        end


        $display(
            "PASS: EVENT_1 returned and consumed"
        );


        // ========================================================
        // TEST 5
        // Abort READ_EVENT halfway through.
        //
        // EVENT_2 MUST remain in FIFO.
        // ========================================================

        $display("");
        $display("================================");
        $display("TEST 5: ABORT READ_EVENT");
        $display("================================");

        spi_select();


        // Send READ_EVENT command.
        spi_transfer_byte(
            8'h10,
            rx_tmp
        );


        // Read only first three response bytes.
        for (i = 0; i < 3; i = i + 1) begin

            spi_transfer_byte(
                8'h00,
                rx_tmp
            );

        end


        // Abort transaction.
        spi_deselect();

        repeat (3)
            @(posedge clk);

        #1;


        if (fifo_count != 1) begin

            $fatal(
                1,
                "FAIL: aborted READ_EVENT changed FIFO count to %0d",
                fifo_count
            );

        end


        if (fifo_read_data !== EVENT_2) begin

            $fatal(
                1,
                "FAIL: aborted READ_EVENT consumed/corrupted EVENT_2"
            );

        end


        $display(
            "PASS: aborted transfer did not consume EVENT_2"
        );


        // ========================================================
        // TEST 6
        // Retry READ_EVENT.
        //
        // We should receive EVENT_2 from the beginning.
        // ========================================================

        $display("");
        $display("================================");
        $display("TEST 6: RETRY READ_EVENT");
        $display("================================");

        spi_select();

        spi_read_event(event_rx);

        spi_deselect();

        repeat (3)
            @(posedge clk);

        #1;


        if (event_rx !== EVENT_2) begin

            $fatal(
                1,
                "FAIL: retry expected 0x%016h, got 0x%016h",
                EVENT_2,
                event_rx
            );

        end


        if (fifo_count != 0) begin

            $fatal(
                1,
                "FAIL: expected empty FIFO after EVENT_2, count=%0d",
                fifo_count
            );

        end


        if (!fifo_empty) begin

            $fatal(
                1,
                "FAIL: FIFO should be empty"
            );

        end


        $display(
            "PASS: EVENT_2 returned after aborted first attempt"
        );


        // ========================================================
        // TEST 7
        // READ_EVENT while empty
        //
        // Response should be zero and FIFO remains empty.
        // ========================================================

        $display("");
        $display("================================");
        $display("TEST 7: READ EMPTY FIFO");
        $display("================================");

        spi_select();

        spi_read_event(event_rx);

        spi_deselect();

        repeat (3)
            @(posedge clk);

        #1;


        if (event_rx !== 64'h0) begin

            $fatal(
                1,
                "FAIL: empty READ_EVENT expected zero, got 0x%016h",
                event_rx
            );

        end


        if (fifo_count != 0) begin

            $fatal(
                1,
                "FAIL: empty READ_EVENT changed FIFO count"
            );

        end


        $display(
            "PASS: empty READ_EVENT returned zero"
        );


        // ========================================================
        // DONE
        // ========================================================

        $display("");
        $display("========================================");
        $display("ALL SPI PROTOCOL TESTS PASSED");
        $display("========================================");
        $display("");
        $display("Verified:");
        $display("  - PING -> 0xA5");
        $display("  - STATUS reports FIFO count");
        $display("  - FIFO peek behavior");
        $display("  - READ_EVENT returns 64-bit data");
        $display("  - completed READ_EVENT consumes FIFO");
        $display("  - aborted READ_EVENT preserves FIFO");
        $display("  - retry returns same event");
        $display("  - empty READ_EVENT returns zero");
        $display("");

        $finish;

    end

endmodule
