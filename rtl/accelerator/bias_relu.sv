module bias_relu #(
    parameter integer NUM_ELEMENTS = 64
) (
    input  logic signed [31:0] input_data [NUM_ELEMENTS],
    input  logic signed [31:0] bias       [NUM_ELEMENTS],

    output logic signed [31:0] output_data [NUM_ELEMENTS]
);

    integer i;

    always_comb begin
        for (i = 0; i < NUM_ELEMENTS; i = i + 1) begin

            if ((input_data[i] + bias[i]) < 32'sd0)
                output_data[i] = 32'sd0;
            else
                output_data[i] = input_data[i] + bias[i];

        end
    end

endmodule
