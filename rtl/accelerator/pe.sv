module processing_element (
    input  logic               clk,
    input  logic               rst,

    input  logic               enable,
    input  logic               clear,

    input  logic signed [7:0]  a,
    input  logic signed [7:0]  b,

    output logic signed [31:0] result
);

    mac_unit mac (
        .clk    (clk),
        .rst    (rst),
        .enable (enable),
        .clear  (clear),
        .a      (a),
        .b      (b),
        .acc    (result)
    );

endmodule