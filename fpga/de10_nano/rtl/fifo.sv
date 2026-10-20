module fifo #(
    parameter                   DEPTH = 8,
    parameter                   DATA_WIDTH = 64
) (
    input wire                  clk,
    input wire                  rst_n,
    input wire [DATA_WIDTH-1:0] write_data,
    input wire                  write_en,
    input wire                  read_en,

    output wire [DATA_WIDTH-1:0] read_data,
    output wire                 full,
    output wire                 empty,
    output reg [$clog2(DEPTH+1)-1:0] count
);

    localparam PTR_WIDTH   =    $clog2(DEPTH);
    localparam COUNT_WIDTH =    $clog2(DEPTH + 1);

    reg [PTR_WIDTH-1:0]         w_ptr;
    reg [PTR_WIDTH-1:0]         r_ptr;

    reg [DATA_WIDTH-1:0]        fifo[0:DEPTH-1];

    // ---------------------------------------------
    // ------------ Status -------------------------
    // ---------------------------------------------

    assign empty =              (count == 0);
    assign full  =              (count == DEPTH);

    // ---------------------------------------------
    // ------- Peak at oldest FIFO Entry -----------
    //
    // read_data always shows the current front item
    // read_end means "consume this item"
    //
    // ---------------------------------------------
    assign read_data = 
        empty
        ? {DATA_WIDTH{1'b0}
        : fifo[r_ptr]

    // -------------------------------------------
    // ---------- FIFO State ---------------------
    // -------------------------------------------
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr <=        0;
            r_ptr <=        0;
            count <=        0;

        end else begin

            // ---------------------------
            //  Write
            //  --------------------------

            if (write_en && !full) begin
                fifo[w_ptr] <=  write_data;
                
                if (w_ptr == DEPTH-1)
                    w_ptr <= 0;
                else
                    w_ptr <= w_ptr + 1;
            end 

            // ----------------------------
            //  Read/consume
            //
            //  Data already visible on
            //  read_data, we only
            //  advance the read pointer 
            //  here.
            //  ---------------------------

            if (read_en && !empty) begin
                read_data <= fifo[r_ptr];
                
                if (r_ptr == DEPTH-1)
                    r_ptr <= 0;
                else
                    r_ptr <= r_ptr + 1;
            end

            case ({
                (write_en && !full),
                (read_en && !empty)
            })
                2'b10: count <=   count + 1'b1;
                2'b01: count <=   count - 1'b1;
                default: count <= count;
            endcase
        end
    end
endmodule
