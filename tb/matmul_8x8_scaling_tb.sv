`timescale 1ns/1ps

module matmul_8x8_scaling_tb;

    localparam integer NUM_PE = `ifdef NUM_PE_VALUE `NUM_PE_VALUE `else 1 `endif;

    logic clk;
    logic rst;
    logic start;

    logic [511:0]  a_flat;
    logic [511:0]  b_flat;
    logic [2047:0] c_flat;

    logic busy;
    logic done;

    integer i;
    integer j;
    integer k;

    integer cycle_count;
    integer start_cycle;
    integer done_cycle;
    integer measured_cycles;

    integer signed a_matrix [0:7][0:7];
    integer signed b_matrix [0:7][0:7];
    integer signed expected_matrix [0:7][0:7];

    integer signed actual_value;
    integer signed expected_value;

    /*
     * DUT
     */
    matmul_scalable_8x8 #(
        .NUM_PE(NUM_PE)
    ) dut (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .a_flat  (a_flat),
        .b_flat  (b_flat),
        .c_flat  (c_flat),
        .busy    (busy),
        .done    (done)
    );


    /*
     * Clock: 10 ns period.
     */
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    /*
     * Global cycle counter.
     */
    always @(posedge clk) begin
        if (rst)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end


    /*
     * Helper task to place an INT8 value into A.
     */
    task automatic set_a;
        input integer r;
        input integer c;
        input integer signed value;

        reg signed [7:0] value8;

        begin
            value8 = value;

            a_flat[((r * 8 + c) * 8) +: 8] = value8;
        end
    endtask


    /*
     * Helper task to place an INT8 value into B.
     */
    task automatic set_b;
        input integer r;
        input integer c;
        input integer signed value;

        reg signed [7:0] value8;

        begin
            value8 = value;

            b_flat[((r * 8 + c) * 8) +: 8] = value8;
        end
    endtask


    /*
     * Read a 32-bit signed result from C.
     */
    task automatic get_c;
        input integer r;
        input integer c;

        reg signed [31:0] value32;

        begin
            value32 =
                c_flat[((r * 8 + c) * 32) +: 32];

            actual_value = value32;
        end
    endtask


    /*
     * Build expected C = A x B using integer arithmetic.
     */
    task automatic calculate_expected;

        integer rr;
        integer cc;
        integer kk;
        integer signed sum;

        begin

            for (rr = 0; rr < 8; rr = rr + 1) begin

                for (cc = 0; cc < 8; cc = cc + 1) begin

                    sum = 0;

                    for (kk = 0; kk < 8; kk = kk + 1) begin

                        sum =
                            sum +
                            (a_matrix[rr][kk] *
                             b_matrix[kk][cc]);

                    end

                    expected_matrix[rr][cc] = sum;

                end

            end

        end

    endtask


    /*
     * Load the matrices.
     *
     * We intentionally use a mixture of positive and negative
     * INT8 values so signed arithmetic is exercised.
     */
    task automatic load_test_matrices;

        integer rr;
        integer cc;

        begin

            /*
             * Matrix A:
             *
             *   1  2  3  4  5  6  7  8
             *   2 -1  4 -2  6 -3  8 -4
             *   1 -2  3 -4  5 -6  7 -8
             *  -1  2 -3  4 -5  6 -7  8
             *   2  3 -1 -2  4  5 -3 -4
             *  -2  4 -6  8  1 -3  5 -7
             *   3 -3  2 -2  1 -1  4 -4
             *  -4 -3 -2 -1  1  2  3  4
             */

            a_matrix[0][0] =  1;
            a_matrix[0][1] =  2;
            a_matrix[0][2] =  3;
            a_matrix[0][3] =  4;
            a_matrix[0][4] =  5;
            a_matrix[0][5] =  6;
            a_matrix[0][6] =  7;
            a_matrix[0][7] =  8;

            a_matrix[1][0] =  2;
            a_matrix[1][1] = -1;
            a_matrix[1][2] =  4;
            a_matrix[1][3] = -2;
            a_matrix[1][4] =  6;
            a_matrix[1][5] = -3;
            a_matrix[1][6] =  8;
            a_matrix[1][7] = -4;

            a_matrix[2][0] =  1;
            a_matrix[2][1] = -2;
            a_matrix[2][2] =  3;
            a_matrix[2][3] = -4;
            a_matrix[2][4] =  5;
            a_matrix[2][5] = -6;
            a_matrix[2][6] =  7;
            a_matrix[2][7] = -8;

            a_matrix[3][0] = -1;
            a_matrix[3][1] =  2;
            a_matrix[3][2] = -3;
            a_matrix[3][3] =  4;
            a_matrix[3][4] = -5;
            a_matrix[3][5] =  6;
            a_matrix[3][6] = -7;
            a_matrix[3][7] =  8;

            a_matrix[4][0] =  2;
            a_matrix[4][1] =  3;
            a_matrix[4][2] = -1;
            a_matrix[4][3] = -2;
            a_matrix[4][4] =  4;
            a_matrix[4][5] =  5;
            a_matrix[4][6] = -3;
            a_matrix[4][7] = -4;

            a_matrix[5][0] = -2;
            a_matrix[5][1] =  4;
            a_matrix[5][2] = -6;
            a_matrix[5][3] =  8;
            a_matrix[5][4] =  1;
            a_matrix[5][5] = -3;
            a_matrix[5][6] =  5;
            a_matrix[5][7] = -7;

            a_matrix[6][0] =  3;
            a_matrix[6][1] = -3;
            a_matrix[6][2] =  2;
            a_matrix[6][3] = -2;
            a_matrix[6][4] =  1;
            a_matrix[6][5] = -1;
            a_matrix[6][6] =  4;
            a_matrix[6][7] = -4;

            a_matrix[7][0] = -4;
            a_matrix[7][1] = -3;
            a_matrix[7][2] = -2;
            a_matrix[7][3] = -1;
            a_matrix[7][4] =  1;
            a_matrix[7][5] =  2;
            a_matrix[7][6] =  3;
            a_matrix[7][7] =  4;


            /*
             * Matrix B.
             */
            b_matrix[0][0] =  1;
            b_matrix[0][1] =  0;
            b_matrix[0][2] =  2;
            b_matrix[0][3] = -1;
            b_matrix[0][4] =  1;
            b_matrix[0][5] =  2;
            b_matrix[0][6] = -2;
            b_matrix[0][7] =  1;

            b_matrix[1][0] =  2;
            b_matrix[1][1] =  1;
            b_matrix[1][2] = -1;
            b_matrix[1][3] =  2;
            b_matrix[1][4] =  0;
            b_matrix[1][5] = -2;
            b_matrix[1][6] =  1;
            b_matrix[1][7] =  3;

            b_matrix[2][0] =  0;
            b_matrix[2][1] =  2;
            b_matrix[2][2] =  1;
            b_matrix[2][3] =  1;
            b_matrix[2][4] = -2;
            b_matrix[2][5] =  0;
            b_matrix[2][6] =  2;
            b_matrix[2][7] = -1;

            b_matrix[3][0] =  1;
            b_matrix[3][1] = -1;
            b_matrix[3][2] =  2;
            b_matrix[3][3] =  0;
            b_matrix[3][4] =  1;
            b_matrix[3][5] =  3;
            b_matrix[3][6] = -1;
            b_matrix[3][7] =  2;

            b_matrix[4][0] = -1;
            b_matrix[4][1] =  2;
            b_matrix[4][2] =  0;
            b_matrix[4][3] =  1;
            b_matrix[4][4] =  2;
            b_matrix[4][5] = -2;
            b_matrix[4][6] =  1;
            b_matrix[4][7] =  0;

            b_matrix[5][0] =  2;
            b_matrix[5][1] =  0;
            b_matrix[5][2] = -2;
            b_matrix[5][3] =  1;
            b_matrix[5][4] =  3;
            b_matrix[5][5] =  1;
            b_matrix[5][6] =  0;
            b_matrix[5][7] = -1;

            b_matrix[6][0] =  1;
            b_matrix[6][1] = -2;
            b_matrix[6][2] =  1;
            b_matrix[6][3] =  2;
            b_matrix[6][4] =  0;
            b_matrix[6][5] =  1;
            b_matrix[6][6] =  2;
            b_matrix[6][7] = -2;

            b_matrix[7][0] =  0;
            b_matrix[7][1] =  1;
            b_matrix[7][2] =  2;
            b_matrix[7][3] = -2;
            b_matrix[7][4] =  1;
            b_matrix[7][5] =  0;
            b_matrix[7][6] =  3;
            b_matrix[7][7] =  1;


            /*
             * Pack the matrices into flat buses.
             */
            a_flat = 512'b0;
            b_flat = 512'b0;

            for (rr = 0; rr < 8; rr = rr + 1) begin

                for (cc = 0; cc < 8; cc = cc + 1) begin

                    set_a(
                        rr,
                        cc,
                        a_matrix[rr][cc]
                    );

                    set_b(
                        rr,
                        cc,
                        b_matrix[rr][cc]
                    );

                end

            end

            calculate_expected;

        end

    endtask


    /*
     * Main test.
     */
    initial begin

        rst   = 1'b1;
        start = 1'b0;

        a_flat = 512'b0;
        b_flat = 512'b0;

        cycle_count    = 0;
        start_cycle    = 0;
        done_cycle     = 0;
        measured_cycles = 0;

        load_test_matrices;


        /*
         * Reset.
         */
        repeat (3) @(posedge clk);

        rst <= 1'b0;

        @(posedge clk);

        /*
         * Start accelerator.
         */
        start <= 1'b1;

        @(posedge clk);

        start <= 1'b0;

        start_cycle = cycle_count;


        /*
         * Wait for completion.
         */
        wait (done == 1'b1);

        done_cycle = cycle_count;

        measured_cycles = done_cycle - start_cycle;


        /*
         * Verify every element.
         */
        for (i = 0; i < 8; i = i + 1) begin

            for (j = 0; j < 8; j = j + 1) begin

                get_c(i, j);

                expected_value = expected_matrix[i][j];

                if (actual_value !== expected_value) begin

                    $display(
                        "FAIL: PE=%0d C[%0d][%0d] expected %0d got %0d",
                        NUM_PE,
                        i,
                        j,
                        expected_value,
                        actual_value
                    );

                    $fatal(1);

                end

            end

        end


        /*
         * Print complete benchmark result.
         */
        $display("");
        $display("==============================================");
        $display("8x8 MATRIX MULTIPLICATION BENCHMARK");
        $display("==============================================");
        $display("PE configuration : %0d", NUM_PE);
        $display("Measured cycles  : %0d", measured_cycles);
        $display("----------------------------------------------");
        $display("PASS: All 64 output elements correct");
        $display("==============================================");
        $display("");


        $finish;

    end

endmodule
