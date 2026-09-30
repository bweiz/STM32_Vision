module fifo #(
    parameter                   DEPTH = 8,
    parameter                   DATA_WIDTH = 64
) (
    input wire                  clk,
    input wire                  rst_n,
    input wire [DATA_WIDTH-1:0] write_data,
    input wire                  write_en,
    input wire                  read_en,
    output reg [DATA_WIDTH-1:0] read_data,
    output wire                 full,
    output wire                 empty,
    output reg [$clog2(DEPTH+1)-1:0] count
);

    localparam PTR_WIDTH   =    $clog2(DEPTH);
    localparam COUNT_WIDTH =    $clog2(DEPTH + 1);

    reg [PTR_WIDTH-1:0]         w_ptr;
    reg [PTR_WIDTH-1:0]         r_ptr;

    reg [DATA_WIDTH-1:0]        fifo[0:DEPTH-1];

    assign empty =              (count == 0);
    assign full  =              (count == DEPTH);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr <=        0;
            r_ptr <=        0;
            count <=        0;
            read_data <=    0;

        end else begin
            if (write_en && !full) begin
                fifo[w_ptr] <=  write_data;
                
                if (count == DEPTH-1)
                    w_ptr <= 0;
                else
                    w_ptr <= w_ptr + 1;
            end 

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
