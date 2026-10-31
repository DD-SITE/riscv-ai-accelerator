module mac_unit (
    input  logic               clk,
    input  logic               rst,
    input  logic               enable,
    input  logic               clear,

    input  logic signed [7:0]  a,
    input  logic signed [7:0]  b,

    output logic signed [31:0] acc
);

    logic signed [15:0] product;

    assign product = a * b;

    always_ff @(posedge clk) begin
        if (rst || clear) begin
            acc <= 32'sd0;
        end
        else if (enable) begin
            acc <= acc + {{16{product[15]}}, product};
        end
    end

endmodule