`timescale 1ns/1ps

module matmul_inference_8x8_tb;

    `ifndef NUM_PE_VALUE
        `define NUM_PE_VALUE 8
    `endif

    localparam integer NUM_PE = `NUM_PE_VALUE;

    logic clk;
    logic rst;
    logic start;

    logic [511:0]  a_flat;
    logic [511:0]  b_flat;
    logic [2047:0] bias_flat;

    logic [2047:0] y_flat;

    logic busy;
    logic done;

    integer A [0:63];
    integer B [0:63];
    integer BIAS [0:63];
    integer EXPECTED [0:63];

    integer i;
    integer j;
    integer k;

    integer sum;
    integer cycle_count;

    matmul_inference_8x8 #(
        .NUM_PE(NUM_PE)
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .a_flat    (a_flat),
        .b_flat    (b_flat),
        .bias_flat (bias_flat),
        .y_flat    (y_flat),
        .busy      (busy),
        .done      (done)
    );

    /*
     * 100 MHz-equivalent simulation clock.
     */
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    /*
     * Construct deterministic 8x8 test matrices.
     */
    initial begin

        /*
         * A matrix.
         *
         * Values deliberately include positive and negative
         * INT8 operands.
         */
        A[0]  =  1;
        A[1]  =  2;
        A[2]  =  3;
        A[3]  =  4;
        A[4]  = -1;
        A[5]  = -2;
        A[6]  = -3;
        A[7]  = -4;

        A[8]  =  5;
        A[9]  =  6;
        A[10] =  7;
        A[11] =  8;
        A[12] = -5;
        A[13] = -6;
        A[14] = -7;
        A[15] = -8;

        A[16] =  2;
        A[17] = -1;
        A[18] =  4;
        A[19] = -3;
        A[20] =  6;
        A[21] = -5;
        A[22] =  8;
        A[23] = -7;

        A[24] = -2;
        A[25] =  3;
        A[26] = -4;
        A[27] =  5;
        A[28] = -6;
        A[29] =  7;
        A[30] = -8;
        A[31] =  1;

        A[32] =  3;
        A[33] =  1;
        A[34] = -2;
        A[35] =  4;
        A[36] = -3;
        A[37] =  5;
        A[38] = -6;
        A[39] =  2;

        A[40] = -4;
        A[41] =  2;
        A[42] =  5;
        A[43] = -1;
        A[44] =  7;
        A[45] = -3;
        A[46] =  6;
        A[47] = -2;

        A[48] =  4;
        A[49] = -5;
        A[50] =  2;
        A[51] =  6;
        A[52] = -7;
        A[53] =  3;
        A[54] = -1;
        A[55] =  8;

        A[56] = -3;
        A[57] =  7;
        A[58] = -2;
        A[59] =  5;
        A[60] = -6;
        A[61] =  4;
        A[62] = -8;
        A[63] =  1;

        /*
         * B matrix.
         */
        B[0]  =  1;
        B[1]  = -1;
        B[2]  =  2;
        B[3]  =  0;
        B[4]  =  3;
        B[5]  = -2;
        B[6]  =  1;
        B[7]  =  2;

        B[8]  =  2;
        B[9]  =  1;
        B[10] = -1;
        B[11] =  3;
        B[12] =  0;
        B[13] =  2;
        B[14] = -2;
        B[15] =  1;

        B[16] = -1;
        B[17] =  2;
        B[18] =  3;
        B[19] = -2;
        B[20] =  1;
        B[21] =  0;
        B[22] =  2;
        B[23] = -1;

        B[24] =  3;
        B[25] =  0;
        B[26] = -2;
        B[27] =  1;
        B[28] =  2;
        B[29] = -1;
        B[30] =  3;
        B[31] =  2;

        B[32] =  1;
        B[33] =  3;
        B[34] =  0;
        B[35] = -1;
        B[36] =  2;
        B[37] =  1;
        B[38] = -2;
        B[39] =  3;

        B[40] = -2;
        B[41] =  1;
        B[42] =  2;
        B[43] =  3;
        B[44] = -1;
        B[45] =  2;
        B[46] =  0;
        B[47] =  1;

        B[48] =  3;
        B[49] = -2;
        B[50] =  1;
        B[51] =  2;
        B[52] =  0;
        B[53] = -1;
        B[54] =  3;
        B[55] =  1;

        B[56] =  2;
        B[57] =  1;
        B[58] = -3;
        B[59] =  0;
        B[60] =  1;
        B[61] =  2;
        B[62] = -1;
        B[63] =  3;

        /*
         * Bias deliberately contains both positive and negative
         * values so ReLU behavior is exercised.
         */
        for (i = 0; i < 64; i = i + 1) begin
            if ((i % 4) == 0)
                BIAS[i] = 20;
            else if ((i % 4) == 1)
                BIAS[i] = -20;
            else if ((i % 4) == 2)
                BIAS[i] = 5;
            else
                BIAS[i] = -5;
        end

        /*
         * Pack A, B, and bias.
         */
        a_flat = 512'b0;
        b_flat = 512'b0;
        bias_flat = 2048'b0;

        for (i = 0; i < 64; i = i + 1) begin
            a_flat[i*8 +: 8] = A[i][7:0];
            b_flat[i*8 +: 8] = B[i][7:0];
            bias_flat[i*32 +: 32] = BIAS[i];
        end

        /*
         * Calculate expected:
         *
         * Y = ReLU(A*B + Bias)
         */
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin

                sum = 0;

                for (k = 0; k < 8; k = k + 1) begin
                    sum = sum +
                          (A[i*8+k] * B[k*8+j]);
                end

                sum = sum + BIAS[i*8+j];

                if (sum < 0)
                    EXPECTED[i*8+j] = 0;
                else
                    EXPECTED[i*8+j] = sum;
            end
        end
    end

    /*
     * Main test.
     */
    initial begin

        rst = 1'b1;
        start = 1'b0;
        cycle_count = 0;

        /*
         * Hold reset for three complete clock cycles.
         */
        repeat (3)
            @(posedge clk);

        /*
         * Release reset away from the active sampling edge.
         */
        @(negedge clk);
        rst = 1'b0;

        /*
         * Assert start on a falling edge.
         *
         * This eliminates the race between the testbench and
         * the DUT's posedge-triggered always_ff blocks.
         */
        @(negedge clk);
        start = 1'b1;

        /*
         * Keep start asserted across the next rising edge so
         * the matrix engine definitely samples it.
         */
        @(negedge clk);
        start = 1'b0;

        /*
         * Count accelerator cycles.
         */
        while (!done) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            if (cycle_count > 2000) begin
                $display("FAIL: Accelerator timeout");
                $display("DEBUG: busy=%b done=%b", busy, done);
                $finish;
            end
        end

        #1;

        /*
         * Verify every output.
         */
        for (i = 0; i < 64; i = i + 1) begin

            if ($signed(y_flat[i*32 +: 32]) !== EXPECTED[i]) begin
                $display(
                    "FAIL: output[%0d] expected=%0d actual=%0d",
                    i,
                    EXPECTED[i],
                    $signed(y_flat[i*32 +: 32])
                );

                $finish;
            end
        end

        $display("");
        $display("==============================================");
        $display("8x8 INT8 INFERENCE BENCHMARK");
        $display("PE configuration : %0d", NUM_PE);
        $display("Measured cycles  : %0d", cycle_count);
        $display("Output elements  : 64");
        $display("Operation        : Y = ReLU(A*B + Bias)");
        $display("==============================================");
        $display("PASS: All 64 inference outputs correct");
        $display("==============================================");
        $display("");

        $finish;
    end

endmodule
