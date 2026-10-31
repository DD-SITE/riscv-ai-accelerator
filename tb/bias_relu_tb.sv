`timescale 1ns/1ps

module bias_relu_tb;

    localparam integer NUM_ELEMENTS = 8;

    logic signed [31:0] input_data [NUM_ELEMENTS];
    logic signed [31:0] bias       [NUM_ELEMENTS];
    logic signed [31:0] output_data [NUM_ELEMENTS];

    bias_relu #(
        .NUM_ELEMENTS(NUM_ELEMENTS)
    ) dut (
        .input_data(input_data),
        .bias(bias),
        .output_data(output_data)
    );

    initial begin

        input_data[0] = 32'sd10;
        input_data[1] = -32'sd5;
        input_data[2] = 32'sd20;
        input_data[3] = -32'sd20;
        input_data[4] = 32'sd0;
        input_data[5] = 32'sd100;
        input_data[6] = -32'sd30;
        input_data[7] = 32'sd7;

        bias[0] = 32'sd2;
        bias[1] = 32'sd2;
        bias[2] = -32'sd10;
        bias[3] = 32'sd5;
        bias[4] = 32'sd0;
        bias[5] = -32'sd50;
        bias[6] = 32'sd100;
        bias[7] = -32'sd20;

        #1;

        if (output_data[0] !== 32'sd12) begin
            $display("FAIL: element 0");
            $finish;
        end

        if (output_data[1] !== 32'sd0) begin
            $display("FAIL: element 1");
            $finish;
        end

        if (output_data[2] !== 32'sd10) begin
            $display("FAIL: element 2");
            $finish;
        end

        if (output_data[3] !== 32'sd0) begin
            $display("FAIL: element 3");
            $finish;
        end

        if (output_data[4] !== 32'sd0) begin
            $display("FAIL: element 4");
            $finish;
        end

        if (output_data[5] !== 32'sd50) begin
            $display("FAIL: element 5");
            $finish;
        end

        if (output_data[6] !== 32'sd70) begin
            $display("FAIL: element 6");
            $finish;
        end

        if (output_data[7] !== 32'sd0) begin
            $display("FAIL: element 7");
            $finish;
        end

        $display("==============================================");
        $display("BIAS + RELU TEST PASSED");
        $display("==============================================");

        $finish;
    end

endmodule
