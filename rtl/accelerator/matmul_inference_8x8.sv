/*
 * 8x8 INT8 Neural Network Inference Accelerator
 *
 * Operation:
 *
 *     Y = ReLU(A * B + Bias)
 *
 * A and B:
 *     64 x INT8
 *
 * Bias:
 *     64 x INT32
 *
 * Output:
 *     64 x INT32
 *
 * NUM_PE:
 *     1, 4, or 8
 *
 * The verified matrix engine is reused without modification.
 */

module matmul_inference_8x8 #(
    parameter integer NUM_PE = 1
) (
    input logic clk,
    input logic rst,

    input logic start,

    input logic [511:0]  a_flat,
    input logic [511:0]  b_flat,
    input logic [2047:0] bias_flat,

    output logic [2047:0] y_flat,

    output logic busy,
    output logic done
);

    /*
     * Output of the verified matrix multiplication engine.
     *
     * 64 elements x 32 bits = 2048 bits.
     */
    logic [2047:0] c_flat;

    logic matmul_busy;
    logic matmul_done;

    /*
     * Reuse the already verified 8x8 scalable matrix engine.
     */
    matmul_scalable_8x8 #(
        .NUM_PE(NUM_PE)
    ) matrix_engine (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .a_flat  (a_flat),
        .b_flat  (b_flat),
        .c_flat  (c_flat),
        .busy    (matmul_busy),
        .done    (matmul_done)
    );

    /*
     * Bias + ReLU.
     *
     * Keep this stage entirely packed.
     *
     * For every output element:
     *
     *     value = signed(C[i]) + signed(Bias[i])
     *
     *     if value < 0
     *         Y[i] = 0
     *     else
     *         Y[i] = value
     */
    integer i;

    logic signed [31:0] matrix_value;
    logic signed [31:0] bias_value;
    logic signed [32:0] bias_sum;

    always_comb begin

        y_flat = 2048'b0;

        for (i = 0; i < 64; i = i + 1) begin

            matrix_value =
                $signed(c_flat[i*32 +: 32]);

            bias_value =
                $signed(bias_flat[i*32 +: 32]);

            /*
             * Use 33 bits for the addition so the signed
             * intermediate cannot overflow during the add.
             */
            bias_sum =
                $signed(matrix_value) +
                $signed(bias_value);

            if (bias_sum < 0)
                y_flat[i*32 +: 32] = 32'b0;
            else
                y_flat[i*32 +: 32] = bias_sum[31:0];

        end
    end

    /*
     * The activation stage is combinational.
     *
     * Therefore latency remains that of the matrix engine.
     */
    assign busy = matmul_busy;
    assign done = matmul_done;

endmodule
