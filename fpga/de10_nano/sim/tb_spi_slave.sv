`timescale 1ns/1ps

module tb_spi_slave;

    // ------------------------------------------------
    // FPGA-side signals
    // ------------------------------------------------

    reg clk;
    reg rst_n;

    reg spi_sclk;
    reg spi_cs_n;
    reg spi_mosi;

    wire spi_miso;

    wire [7:0] rx_byte;
    wire       rx_valid;

    // TX side is not implemented yet
    reg  [7:0] tx_byte;
    reg        tx_load;

    reg  [7:0] miso_received;

    // ------------------------------------------------
    // Testbench tracking
    // ------------------------------------------------

    integer receive_count;

    reg [7:0] received [0:7];

    // 1 MHz SPI clock:
    //
    // full period = 1000 ns
    // half period = 500 ns
    //
    // FPGA clk is 50 MHz = 20 ns period
    //
    localparam integer SPI_HALF_PERIOD = 500;


    // ============================================================
    // 50 MHz FPGA clock
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #10 clk = ~clk;
    end


    // ============================================================
    // DUT
    // ============================================================

    spi_slave u_spi_slave (
        .clk       (clk),
        .rst_n     (rst_n),

        .spi_sclk  (spi_sclk),
        .spi_cs_n  (spi_cs_n),
        .spi_mosi  (spi_mosi),
        .spi_miso  (spi_miso),

        .rx_byte   (rx_byte),
        .rx_valid  (rx_valid),

        .tx_byte   (tx_byte),
        .tx_load   (tx_load)
    );


    // ============================================================
    // Watch for completed received bytes
    // ============================================================

    always @(posedge rx_valid) begin

        received[receive_count] = rx_byte;

        $display(
            "RX BYTE %0d: 0x%02h",
            receive_count + 1,
            rx_byte
        );

        receive_count = receive_count + 1;

    end


    // ============================================================
    // Reset
    // ============================================================

    task automatic reset_dut;
        begin

            rst_n     = 1'b0;

            spi_sclk  = 1'b0;
            spi_cs_n  = 1'b1;
            spi_mosi  = 1'b0;

            tx_byte   = 8'h00;
            tx_load   = 1'b0;

            receive_count = 0;

            repeat (5)
                @(posedge clk);

            @(negedge clk);

            rst_n = 1'b1;

            repeat (5)
                @(posedge clk);

        end
    endtask


    // ============================================================
    // Select SPI slave
    //
    // CS is active LOW.
    //
    // We wait several FPGA clocks because CS passes through
    // the synchronizer before the SPI logic sees it.
    // ============================================================

    task automatic spi_select;
        begin

            spi_cs_n = 1'b0;

            repeat (5)
                @(posedge clk);

        end
    endtask


    // ============================================================
    // Deselect SPI slave
    // ============================================================

    task automatic spi_deselect;
        begin

            spi_cs_n = 1'b1;
            spi_sclk = 1'b0;
            spi_mosi = 1'b0;

            repeat (5)
                @(posedge clk);

        end
    endtask


    // ============================================================
    // Send one SPI byte
    //
    // SPI Mode 0:
    //
    // SCLK idle LOW
    //
    // MOSI is set BEFORE rising edge.
    //
    // Slave samples MOSI on rising edge.
    //
    // MSB first:
    //
    // bit 7
    // bit 6
    // ...
    // bit 0
    // ============================================================

    task automatic spi_clock_byte (
        input [7:0] data
    );

        integer bit_index;

        begin

            for (
                bit_index = 7;
                bit_index >= 0;
                bit_index = bit_index - 1
            ) begin

                // Put next data bit on MOSI
                // while SCLK is LOW.
                spi_mosi = data[bit_index];

                #(SPI_HALF_PERIOD);

                // Rising edge:
                //
                // slave should sample MOSI.
                spi_sclk = 1'b1;

                #(SPI_HALF_PERIOD);

                // Falling edge
                spi_sclk = 1'b0;

            end

            spi_mosi = 1'b0;

        end
    endtask

    // ============================================================
    // SPI Transfer Byte 
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

                // Master places MOSI bit while SCLK is low
                spi_mosi = tx_data[bit_index];

                #(SPI_HALF_PERIOD);

                // Rising edge:
                // FPGA samples MOSI
                // Master samples MISO
                spi_sclk = 1'b1;

                #50;

                rx_data[bit_index] = spi_miso;

                #(SPI_HALF_PERIOD - 50);

                // Falling edge:
                // FPGA advances to next MISO bit
                spi_sclk = 1'b0;

            end

            spi_mosi = 1'b0;
        end

    endtask
    // ============================================================
    // Simulation timeout
    // ============================================================

    initial begin

        #100000;

        $fatal(
            1,
            "FAIL: simulation timeout"
        );

    end


    // ============================================================
    // Main test
    // ============================================================

    initial begin

        $dumpfile("sim/spi_slave.vcd");
        $dumpvars(0, tb_spi_slave);


        reset_dut();


        // --------------------------------------------------------
        // TEST 1
        //
        // Clock SPI while CS is HIGH.
        //
        // Slave should ignore everything.
        // --------------------------------------------------------

        $display("");
        $display("==============================");
        $display("TEST 1: CS HIGH - IGNORE DATA");
        $display("==============================");

        spi_clock_byte(8'hDE);

        #200;


        if (receive_count != 0) begin

            $fatal(
                1,
                "FAIL: received byte while CS was inactive"
            );

        end


        $display(
            "PASS: SPI clocks ignored while CS high"
        );


        // --------------------------------------------------------
        // TEST 2
        //
        // Receive one byte: A6
        //
        // A6 = 1010 0110
        // --------------------------------------------------------

        $display("");
        $display("==============================");
        $display("TEST 2: RECEIVE 0xA6");
        $display("==============================");


        spi_select();

        spi_clock_byte(8'hA6);

        spi_deselect();


        if (receive_count != 1) begin

            $fatal(
                1,
                "FAIL: expected 1 received byte, got %0d",
                receive_count
            );

        end


        if (received[0] !== 8'hA6) begin

            $fatal(
                1,
                "FAIL: expected 0xA6, got 0x%02h",
                received[0]
            );

        end


        $display(
            "PASS: correctly received 0xA6"
        );


        // --------------------------------------------------------
        // TEST 3
        //
        // Send multiple bytes during one CS transaction.
        //
        // Tests that bit_count resets correctly after each byte.
        // --------------------------------------------------------

        $display("");
        $display("==============================");
        $display("TEST 3: CONSECUTIVE BYTES");
        $display("==============================");


        spi_select();

        spi_clock_byte(8'h3C);
        spi_clock_byte(8'h5A);

        spi_deselect();


        if (receive_count != 3) begin

            $fatal(
                1,
                "FAIL: expected 3 total received bytes, got %0d",
                receive_count
            );

        end


        if (received[1] !== 8'h3C) begin

            $fatal(
                1,
                "FAIL: expected 0x3C, got 0x%02h",
                received[1]
            );

        end


        if (received[2] !== 8'h5A) begin

            $fatal(
                1,
                "FAIL: expected 0x5A, got 0x%02h",
                received[2]
            );

        end


        $display(
            "PASS: consecutive bytes received correctly"
        );
        // --------------------------------------------------------
        // TEST 4
        //
        // Abort a transaction halfway through a byte.
        //
        // Send 4 bits, raise CS, then start a new
        // transaction and send a full byte.
        //
        // The slave must discard the partial byte.
        // --------------------------------------------------------

        $display("");
        $display("==============================");
        $display("TEST 4: ABORT PARTIAL BYTE");
        $display("==============================");


        // Start transaction
        spi_select();


        // Send only upper 4 bits of 0xF0:
        //
        // 1 1 1 1
        //
        spi_mosi = 1'b1;

        #(SPI_HALF_PERIOD);
        spi_sclk = 1'b1;

        #(SPI_HALF_PERIOD);
        spi_sclk = 1'b0;


        spi_mosi = 1'b1;

        #(SPI_HALF_PERIOD);
        spi_sclk = 1'b1;

        #(SPI_HALF_PERIOD);
        spi_sclk = 1'b0;


        spi_mosi = 1'b1;

        #(SPI_HALF_PERIOD);
        spi_sclk = 1'b1;

        #(SPI_HALF_PERIOD);
        spi_sclk = 1'b0;


        spi_mosi = 1'b1;

        #(SPI_HALF_PERIOD);
        spi_sclk = 1'b1;

        #(SPI_HALF_PERIOD);
        spi_sclk = 1'b0;


        // Abort transaction before byte is complete.
        spi_deselect();


        // No new byte should have been produced.
        if (receive_count != 3) begin

            $fatal(
                1,
                "FAIL: partial byte incorrectly generated rx_valid"
            );

        end


        // --------------------------------------------------------
        // Start a brand-new transaction.
        //
        // If bit_count was properly reset when CS went high,
        // this byte should be received normally.
        // --------------------------------------------------------

        spi_select();

        spi_clock_byte(8'hC3);

        spi_deselect();


        if (receive_count != 4) begin

            $fatal(
                1,
                "FAIL: expected 4 total received bytes, got %0d",
                receive_count
            );

        end


        if (received[3] !== 8'hC3) begin

            $fatal(
                1,
                "FAIL: expected 0xC3 after aborted transaction, got 0x%02h",
                received[3]
            );

        end


        $display(
            "PASS: partial byte discarded when CS deasserted"
        );
        // --------------------------------------------------------
        // TEST 5
        // FPGA transmit / MISO
        //
        // Load 0xA5 into the FPGA TX shift register
        // and verify that the master receives 0xA5.
        // --------------------------------------------------------

        $display("");
        $display("==============================");
        $display("TEST 5: TRANSMIT 0xA5");
        $display("==============================");


        // Load FPGA transmit register while idle
        tx_byte = 8'hA5;
        tx_load = 1'b1;

        @(posedge clk);
        #1;

        tx_load = 1'b0;


        // Start SPI transaction
        spi_select();


        // MOSI value doesn't matter for this test.
        // 0x00 is just a dummy byte that generates clocks.
        spi_transfer_byte(
            8'h00,
            miso_received
        );


        spi_deselect();


        $display(
            "MISO received: 0x%02h",
            miso_received
        );


        if (miso_received !== 8'hA5) begin

            $fatal(
                1,
                "FAIL: expected MISO 0xA5, got 0x%02h",
                miso_received
            );

        end


        $display(
            "PASS: FPGA transmitted 0xA5 correctly"
        );

        // --------------------------------------------------------
        // DONE
        // --------------------------------------------------------

        $display("");
        $display("================================");
        $display("ALL SPI RX TESTS PASSED");
        $display("================================");
        $display("");

        $display(
            "received[0] = 0x%02h",
            received[0]
        );

        $display(
            "received[1] = 0x%02h",
            received[1]
        );

        $display(
            "received[2] = 0x%02h",
            received[2]
        );

        $finish;

    end

endmodule
