module pe_array #(
    parameter integer NUM_PE = 4
) (
    input  logic                   clk,
    input  logic                   rst,

    input  logic                   enable,
    input  logic                   clear,

    input  logic signed [7:0]      a [NUM_PE],
    input  logic signed [7:0]      b [NUM_PE],

    output logic signed [31:0]     result [NUM_PE]
);

    genvar i;

    generate
        for (i = 0; i < NUM_PE; i = i + 1) begin : PE_GEN

            processing_element pe (
                .clk    (clk),
                .rst    (rst),
                .enable (enable),
                .clear  (clear),
                .a      (a[i]),
                .b      (b[i]),
                .result (result[i])
            );

        end
    endgenerate

endmodule