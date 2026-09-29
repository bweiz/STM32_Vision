 module top (
    input wire  FPGA_CLK1_50,
    input wire  GPIO_EVENT,
    output wire LED0
);

    //assign LED0 = GPIO_EVENT;

    reg [25:0] counter = 26'd0;

    always @(posedge FPGA_CLK1_50) begin
        counter <= counter + 1;
    end

    assign LED0 = counter[25];

endmodule

