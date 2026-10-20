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


    // -----------------------------------------------------
    // Commands
    // -----------------------------------------------------

    localparam CMD_PING       = 8'h00;
    localparam CMD_STATS      = 8'h01;
    localparam CMD_READ_EVENT = 8'h10;
    
    // -----------------------------------------------------
    // States 
    // -----------------------------------------------------

    localparam STATE_IDLE           = 2'd0;
    localparam STATE_SINGLE_REPLY   = 2'd1;
    localparam STATE_SEND_EVENT     = 2'd2;

    reg [1:0] state;

    reg [63:0] event_buffer;
    reg [2:0]  event_byte_index;
    reg        event_pending;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin

            state            <= IDLE;

            tx_byte          <= 8'h00;
            tx_load          <= 1'b0;

            fifo_read_en     <= 1'b0;

            event_buffer     <= 64'h0;
            event_byte_index <= 3'd0;
            event_pending    <= 1'b0;

        end else begin

            // One-clock pulses by default
            tx_load      <= 1'b0;
            fifo_read_en <= 1'b0;


            // CS high = transaction aborted / finished
            if (!spi_active) begin

                state            <= IDLE;
                event_byte_index <= 3'd0;
                event_pending    <= 1'b0;

            end else begin

                case (state)

                    // --------------------------------
                    // Waiting for command
                    // --------------------------------

                    IDLE: begin

                        if (rx_valid) begin

                            case (rx_byte)

                                CMD_PING: begin

                                    tx_byte <= 8'hA5;
                                    tx_load <= 1'b1;

                                    state <= SINGLE_REPLY;

                                end


                                CMD_STATUS: begin

                                    tx_byte <= fifo_count;
                                    tx_load <= 1'b1;

                                    state <= SINGLE_REPLY;

                                end


                                CMD_READ_EVENT: begin

                                    event_byte_index <= 3'd0;

                                    if (!fifo_empty) begin

                                        event_buffer  <= fifo_read_data;
                                        event_pending <= 1'b1;

                                        // First timestamp byte
                                        tx_byte <= fifo_read_data[63:56];

                                    end else begin

                                        event_buffer  <= 64'h0;
                                        event_pending <= 1'b0;

                                        tx_byte <= 8'h00;

                                    end

                                    tx_load <= 1'b1;
                                    state   <= SEND_EVENT;

                                end


                                default: begin

                                    tx_byte <= 8'h00;
                                    tx_load <= 1'b1;

                                    state <= SINGLE_REPLY;

                                end

                            endcase
                        end
                    end


                    // --------------------------------
                    // PING / STATUS response finished
                    // --------------------------------

                    SINGLE_REPLY: begin

                        if (rx_valid)
                            state <= IDLE;

                    end


                    // --------------------------------
                    // Send remaining timestamp bytes
                    // --------------------------------

                    SEND_EVENT: begin

                        if (rx_valid) begin

                            // Last byte just finished
                            if (event_byte_index == 3'd7) begin

                                if (event_pending)
                                    fifo_read_en <= 1'b1;

                                event_pending    <= 1'b0;
                                event_byte_index <= 3'd0;

                                state <= IDLE;

                            end else begin

                                // Load next timestamp byte
                                tx_byte <= event_buffer[
                                    55 - (event_byte_index * 8) -: 8
                                ];

                                tx_load <= 1'b1;

                                event_byte_index <=
                                    event_byte_index + 1'b1;

                            end
                        end
                    end


                    default:
                        state <= IDLE;

                endcase
            end
        end
    end

endmodule
