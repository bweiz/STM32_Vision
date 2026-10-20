module spi_slave (
    input wire              clk,
    input wire              rst_n,

    input wire              spi_sclk,
    input wire              spi_cs_n,
    input wire              spi_mosi,

    output wire             spi_miso,
    output wire             spi_active,

    output reg [7:0]        rx_byte,
    output reg              rx_valid,

    input wire [7:0]        tx_byte,
    input wire              tx_load
    );



// -------------------------------------------------------
// -------- Synchronization Registers --------------------
// ------------------------------------------------------- 

    reg sclk_meta;
    reg sclk_sync;
    reg sclk_prev;

    reg mosi_meta;
    reg mosi_sync;

    reg cs_meta;
    reg cs_sync;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_meta <= 1'b0;
            sclk_sync <= 1'b0;
            sclk_prev <= 1'b0;

            mosi_meta <= 1'b0;
            mosi_sync <= 1'b0;

            // cs inactive high
            cs_meta <= 1'b1;
            cs_sync <= 1'b1;

        end else begin
            sclk_meta <= spi_sclk;
            sclk_sync <= sclk_meta;
            sclk_prev <= sclk_sync;

            mosi_meta <= spi_mosi;
            mosi_sync <= mosi_meta;

            cs_meta <= spi_cs_n;
            cs_sync <= cs_meta;
        end
    end
// -------------------------------------------------------
// ------------ SPI Edge Detection -----------------------
// ------------------------------------------------------- 
    wire sclk_rise;
    wire sclk_fall;

    assign cs_active = ~cs_sync;
    assign spi_active = cs_active;

    // rising edge if cs is low, sclk high, and previous sclk was low
    assign sclk_rise =
        cs_active && sclk_sync && !sclk_prev; 

    assign sclk_fall =
        cs_active && !sclk_sync && sclk_prev;


    // ----------------------------------------------------
    // ------------- Receive State ------------------------
    // ----------------------------------------------------
    
    reg [7:0] rx_shift;
    reg [2:0] bit_count;

    // ----------------------------------------------------
    // ------------- Receive State ------------------------
    // ----------------------------------------------------
   
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift <= 8'h00;
            bit_count <= 3'd0;
            rx_byte <= 8'h00;
            rx_valid <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            
            if (!cs_active) begin               // edge case: partial byte received and dead, reset byte framing
                bit_count <= 3'd0;
                rx_shift <= 8'h00;
            end else if (sclk_rise) begin       // rising edge sclk 
                rx_shift <= {                   // take current bit on MOSI, push into reg
                    rx_shift[6:0],
                    mosi_sync
                };
            
                if (bit_count == 3'd7) begin    // 8th bit, complete byte
                    rx_byte <= {
                        rx_shift[6:0],
                        mosi_sync
                    };

                    rx_valid <= 1'b1;
                    bit_count <= 3'd0;

                end else begin
                    bit_count <= bit_count + 1;
                end
            end
        end
    end

    // ---------------------------------------------------
    // ------------------ TX State -----------------------
    // ---------------------------------------------------

    reg [7:0] tx_shift;

    assign spi_miso = 
        cs_active
        ? tx_shift[7]
        : 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift <= 8'h00;
        end else begin

            if (tx_load) begin
                tx_shift <= tx_byte;          
            end else if (sclk_fall && cs_active) begin
                tx_shift <= {tx_shift[6:0], 1'b0};
            end
        end
    end
endmodule
