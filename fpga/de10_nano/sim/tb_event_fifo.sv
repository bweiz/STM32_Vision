`timescale 1ns/1ps

module tb_event_fifo;

    localparam DEPTH      = 8;
    localparam DATA_WIDTH = 64;
    localparam COUNT_WIDTH = $clog2(DEPTH + 1);

    reg clk;
    reg rst_n;
    reg async_event_in;
    reg read_en;

    wire                  event_sync;
    wire [63:0]           timestamp_count;
    wire [63:0]           timestamp;
    wire                  timestamp_valid;

    wire [DATA_WIDTH-1:0] read_data;
    wire                  full;
    wire                  empty;
    wire [COUNT_WIDTH-1:0] fifo_count;

    integer capture_count;
    integer i;

    // Store timestamps produced by event_capture so that
    // we can later verify FIFO output against them.
    reg [63:0] captured [0:31];

    reg [63:0] read_data_before;


    // ============================================================
    // 50 MHz FPGA clock
    //
    // Period = 20 ns
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #10 clk = ~clk;
    end


    // ============================================================
    // DUT
    // ============================================================

    cdc_sync u_cdc_sync (
        .clk            (clk),
        .rst_n          (rst_n),
        .async_event_in (async_event_in),
        .event_sync     (event_sync)
    );


    timestamp_counter u_timestamp_counter (
        .clk   (clk),
        .rst_n (rst_n),
        .count (timestamp_count)
    );


    event_capture u_event_capture (
        .clk             (clk),
        .rst_n           (rst_n),
        .event_sync      (event_sync),
        .count           (timestamp_count),
        .timestamp       (timestamp),
        .timestamp_valid (timestamp_valid)
    );


    fifo #(
        .DEPTH      (DEPTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_fifo (
        .clk        (clk),
        .rst_n      (rst_n),

        .write_data (timestamp),
        .write_en   (timestamp_valid),

        .read_en    (read_en),
        .read_data  (read_data),

        .full       (full),
        .empty      (empty),
        .count      (fifo_count)
    );


    // ============================================================
    // Capture every timestamp produced by event_capture.
    //
    // This gives the testbench a reference sequence:
    //
    // captured[0]
    // captured[1]
    // captured[2]
    // ...
    // ============================================================

    always @(posedge timestamp_valid) begin

        captured[capture_count] = timestamp;
        capture_count = capture_count + 1;

        $display(
            "CAPTURE %0d: timestamp=%0d",
            capture_count,
            timestamp
        );
    end


    // ============================================================
    // Reset DUT
    // ============================================================

    task automatic reset_dut;
        begin

            rst_n          = 1'b0;
            async_event_in = 1'b0;
            read_en        = 1'b0;
            capture_count  = 0;

            repeat (4)
                @(posedge clk);

            // Release reset away from active clock edge
            @(negedge clk);
            rst_n = 1'b1;

            // Let everything settle
            repeat (2)
                @(posedge clk);

            #1;

            if (!empty) begin
                $fatal(1,
                    "FAIL: FIFO should be empty after reset"
                );
            end

            if (full) begin
                $fatal(1,
                    "FAIL: FIFO should not be full after reset"
                );
            end

            if (fifo_count != 0) begin
                $fatal(1,
                    "FAIL: FIFO count should be 0 after reset, got %0d",
                    fifo_count
                );
            end

        end
    endtask


    // ============================================================
    // Generate one asynchronous event.
    //
    // Timing deliberately does not line up with the 20 ns
    // FPGA clock period.
    // ============================================================

    task automatic generate_event;
        begin

            #7;
            async_event_in = 1'b1;

            // Long enough to pass safely through CDC chain.
            #137;
            async_event_in = 1'b0;

            #83;

        end
    endtask


    // ============================================================
    // Read one FIFO item and compare against expected value.
    // ============================================================

    task automatic read_and_check (
        input [DATA_WIDTH-1:0] expected
    );
        begin

            if (empty) begin
                $fatal(1,
                    "FAIL: attempted valid FIFO read while empty"
                );
            end

            @(negedge clk);
            read_en = 1'b1;

            // FIFO performs the read here.
            @(posedge clk);

            // Allow nonblocking assignments to settle.
            #1;

            read_en = 1'b0;

            $display(
                "FIFO READ: expected=%0d actual=%0d count=%0d",
                expected,
                read_data,
                fifo_count
            );

            if (read_data !== expected) begin
                $fatal(1,
                    "FAIL: expected %0d, got %0d",
                    expected,
                    read_data
                );
            end

        end
    endtask


    // ============================================================
    // Attempt a read while FIFO is empty.
    //
    // Nothing should change.
    // ============================================================

    task automatic attempt_empty_read;
        begin

            if (!empty) begin
                $fatal(1,
                    "FAIL: underflow test requires an empty FIFO"
                );
            end

            read_data_before = read_data;

            @(negedge clk);
            read_en = 1'b1;

            @(posedge clk);
            #1;

            read_en = 1'b0;

            if (!empty) begin
                $fatal(1,
                    "FAIL: empty deasserted after invalid read"
                );
            end

            if (fifo_count != 0) begin
                $fatal(1,
                    "FAIL: empty read changed FIFO count to %0d",
                    fifo_count
                );
            end

            if (read_data !== read_data_before) begin
                $fatal(1,
                    "FAIL: empty read changed read_data"
                );
            end

            $display(
                "PASS: read while empty was ignored"
            );

        end
    endtask


    // ============================================================
    // Simulation timeout
    //
    // Prevents a bad wait() from hanging simulation forever.
    // ============================================================

    initial begin
        #100000;

        $fatal(1,
            "FAIL: simulation timeout"
        );
    end


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        $dumpfile("sim/event_fifo.vcd");
        $dumpvars(0, tb_event_fifo);

        rst_n          = 1'b0;
        async_event_in = 1'b0;
        read_en        = 1'b0;
        capture_count  = 0;


        // ========================================================
        // TEST 1
        // Basic event pipeline + FIFO ordering
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 1: BASIC EVENT PIPELINE");
        $display("========================================");

        reset_dut();


        generate_event();
        generate_event();
        generate_event();


        wait (capture_count >= 3);

        // Give FIFO time to consume last timestamp_valid.
        @(posedge clk);
        #1;


        if (fifo_count != 3) begin
            $fatal(1,
                "FAIL: expected FIFO count 3, got %0d",
                fifo_count
            );
        end


        if (!(captured[0] < captured[1] &&
              captured[1] < captured[2])) begin

            $fatal(1,
                "FAIL: timestamps are not monotonically increasing"
            );
        end


        read_and_check(captured[0]);
        read_and_check(captured[1]);
        read_and_check(captured[2]);


        if (!empty) begin
            $fatal(1,
                "FAIL: FIFO should be empty after basic reads"
            );
        end

        if (fifo_count != 0) begin
            $fatal(1,
                "FAIL: expected count 0 after basic reads, got %0d",
                fifo_count
            );
        end


        $display("");
        $display("PASS: basic pipeline");
        $display(
            "timestamps: %0d, %0d, %0d",
            captured[0],
            captured[1],
            captured[2]
        );


        // ========================================================
        // TEST 2
        // Fill FIFO completely and reject overflow
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 2: FULL + OVERFLOW");
        $display("========================================");

        reset_dut();


        // Generate exactly DEPTH events.
        for (i = 0; i < DEPTH; i = i + 1) begin
            generate_event();
        end


        wait (capture_count >= DEPTH);

        // Last timestamp_valid must still be consumed by FIFO.
        @(posedge clk);
        #1;


        if (!full) begin
            $fatal(1,
                "FAIL: FIFO should be full after %0d events",
                DEPTH
            );
        end


        if (empty) begin
            $fatal(1,
                "FAIL: FIFO reports empty while full"
            );
        end


        if (fifo_count != DEPTH) begin
            $fatal(1,
                "FAIL: expected FIFO count %0d, got %0d",
                DEPTH,
                fifo_count
            );
        end


        $display(
            "PASS: FIFO reached full state with count=%0d",
            fifo_count
        );


        // --------------------------------------------------------
        // Ninth event.
        //
        // event_capture must see it,
        // but FIFO must reject it.
        // --------------------------------------------------------

        generate_event();

        wait (capture_count >= DEPTH + 1);

        @(posedge clk);
        #1;


        if (!full) begin
            $fatal(1,
                "FAIL: FIFO stopped being full after overflow attempt"
            );
        end


        if (fifo_count != DEPTH) begin
            $fatal(1,
                "FAIL: overflow changed FIFO count to %0d",
                fifo_count
            );
        end


        $display(
            "PASS: overflow event captured but FIFO remained at %0d entries",
            fifo_count
        );


        // --------------------------------------------------------
        // Drain FIFO.
        //
        // This is the important overflow proof:
        // entries 0..7 must be unchanged.
        //
        // captured[8] must NOT have overwritten anything.
        // --------------------------------------------------------

        for (i = 0; i < DEPTH; i = i + 1) begin
            read_and_check(captured[i]);
        end


        if (!empty) begin
            $fatal(1,
                "FAIL: FIFO should be empty after draining full FIFO"
            );
        end


        if (fifo_count != 0) begin
            $fatal(1,
                "FAIL: expected FIFO count 0 after drain, got %0d",
                fifo_count
            );
        end


        $display(
            "PASS: rejected overflow did not corrupt stored entries"
        );


        // ========================================================
        // TEST 3
        // Underflow / read while empty
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 3: EMPTY READ / UNDERFLOW");
        $display("========================================");


        // FIFO is already empty from previous test.
        attempt_empty_read();


        // ========================================================
        // TEST 4
        // Pointer wraparound
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 4: POINTER WRAPAROUND");
        $display("========================================");

        reset_dut();


        // --------------------------------------------------------
        // Write six entries:
        //
        // addresses:
        // 0 1 2 3 4 5
        // --------------------------------------------------------

        for (i = 0; i < 6; i = i + 1) begin
            generate_event();
        end


        wait (capture_count >= 6);

        @(posedge clk);
        #1;


        if (fifo_count != 6) begin
            $fatal(1,
                "FAIL: expected 6 entries before wrap test, got %0d",
                fifo_count
            );
        end


        // --------------------------------------------------------
        // Read four.
        //
        // Leaves captured[4], captured[5].
        //
        // r_ptr should now have advanced to index 4.
        // --------------------------------------------------------

        for (i = 0; i < 4; i = i + 1) begin
            read_and_check(captured[i]);
        end


        if (fifo_count != 2) begin
            $fatal(1,
                "FAIL: expected 2 entries after partial drain, got %0d",
                fifo_count
            );
        end


        // --------------------------------------------------------
        // Add six more.
        //
        // write pointer must go:
        //
        // 6 -> 7 -> 0 -> 1 -> 2 -> 3
        //
        // This forces physical memory wraparound.
        // --------------------------------------------------------

        for (i = 0; i < 6; i = i + 1) begin
            generate_event();
        end


        wait (capture_count >= 12);

        @(posedge clk);
        #1;


        if (!full) begin
            $fatal(1,
                "FAIL: FIFO should be full after wraparound writes"
            );
        end


        if (fifo_count != DEPTH) begin
            $fatal(1,
                "FAIL: expected count %0d after wraparound, got %0d",
                DEPTH,
                fifo_count
            );
        end


        // --------------------------------------------------------
        // Logical FIFO order should now be:
        //
        // captured[4]
        // captured[5]
        // captured[6]
        // ...
        // captured[11]
        //
        // even though physical RAM wrapped around.
        // --------------------------------------------------------

        for (i = 4; i < 12; i = i + 1) begin
            read_and_check(captured[i]);
        end


        if (!empty) begin
            $fatal(1,
                "FAIL: FIFO not empty after wraparound drain"
            );
        end


        if (fifo_count != 0) begin
            $fatal(1,
                "FAIL: count should be 0 after wraparound drain, got %0d",
                fifo_count
            );
        end


        $display(
            "PASS: pointer wraparound preserved FIFO ordering"
        );


        // ========================================================
        // TEST 5
        // Simultaneous read + write
        // ========================================================

        $display("");
        $display("========================================");
        $display("TEST 5: SIMULTANEOUS READ + WRITE");
        $display("========================================");

        reset_dut();


        // Put two entries in FIFO.
        generate_event();
        generate_event();

        wait (capture_count >= 2);

        @(posedge clk);
        #1;


        if (fifo_count != 2) begin
            $fatal(1,
                "FAIL: expected 2 entries before simultaneous operation, got %0d",
                fifo_count
            );
        end


        // --------------------------------------------------------
        // Generate event #3.
        //
        // When timestamp_valid rises, assert read_en so that
        // on the following FPGA clock:
        //
        //     one FIFO entry is written
        //     one FIFO entry is read
        //
        // occupancy should therefore remain 2.
        // --------------------------------------------------------

        fork

            begin
                generate_event();
            end


            begin

                @(posedge timestamp_valid);

                // timestamp_valid will be consumed by FIFO
                // on the next rising FPGA clock.

                #1;
                read_en = 1'b1;

                @(posedge clk);
                #1;

                read_en = 1'b0;


                if (read_data !== captured[0]) begin
                    $fatal(1,
                        "FAIL: simultaneous read expected %0d, got %0d",
                        captured[0],
                        read_data
                    );
                end

            end

        join


        wait (capture_count >= 3);

        #1;


        // One entered, one left.
        //
        // FIFO occupancy should be unchanged.
        if (fifo_count != 2) begin
            $fatal(1,
                "FAIL: simultaneous read/write changed FIFO count to %0d",
                fifo_count
            );
        end


        $display(
            "PASS: simultaneous read/write kept count at %0d",
            fifo_count
        );


        // Remaining logical order must be:
        //
        // captured[1]
        // captured[2]

        read_and_check(captured[1]);
        read_and_check(captured[2]);


        if (!empty) begin
            $fatal(1,
                "FAIL: FIFO should be empty after simultaneous-operation test"
            );
        end


        if (fifo_count != 0) begin
            $fatal(1,
                "FAIL: expected count 0 at end, got %0d",
                fifo_count
            );
        end


        // ========================================================
        // ALL TESTS PASSED
        // ========================================================

        $display("");
        $display("========================================");
        $display("ALL FIFO TESTS PASSED");
        $display("========================================");
        $display("");
        $display("Verified:");
        $display("  - reset / empty state");
        $display("  - event timestamp ordering");
        $display("  - normal FIFO writes and reads");
        $display("  - full detection");
        $display("  - overflow rejection");
        $display("  - underflow protection");
        $display("  - circular pointer wraparound");
        $display("  - simultaneous read/write");
        $display("");

        $finish;

    end

endmodule
