`timescale 1ns/1ps

module matmul_engine_tb;

    logic               clk;
    logic               rst;
    logic               start;

    logic signed [7:0]  a [4][4];
    logic signed [7:0]  b [4][4];

    logic signed [31:0] c [4][4];

    logic               busy;
    logic               done;

    matmul_engine dut (
        .clk   (clk),
        .rst   (rst),
        .start (start),
        .a     (a),
        .b     (b),
        .c     (c),
        .busy  (busy),
        .done  (done)
    );

    always #5 clk = ~clk;


    // ============================================================
    // TEST 1: Identity Matrix
    //
    // A × I = A
    // ============================================================
    task automatic test_identity;
        begin

            // Matrix A
            a[0][0] =  1;
            a[0][1] =  2;
            a[0][2] =  3;
            a[0][3] =  4;

            a[1][0] =  5;
            a[1][1] =  6;
            a[1][2] =  7;
            a[1][3] =  8;

            a[2][0] =  9;
            a[2][1] = 10;
            a[2][2] = 11;
            a[2][3] = 12;

            a[3][0] = 13;
            a[3][1] = 14;
            a[3][2] = 15;
            a[3][3] = 16;

            // Identity matrix B
            b[0][0] = 1;
            b[0][1] = 0;
            b[0][2] = 0;
            b[0][3] = 0;

            b[1][0] = 0;
            b[1][1] = 1;
            b[1][2] = 0;
            b[1][3] = 0;

            b[2][0] = 0;
            b[2][1] = 0;
            b[2][2] = 1;
            b[2][3] = 0;

            b[3][0] = 0;
            b[3][1] = 0;
            b[3][2] = 0;
            b[3][3] = 1;

            // Start multiplication
            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            // Wait until computation completes
            wait (done == 1'b1);
            #1;

            // Check C = A
            for (integer i = 0; i < 4; i = i + 1) begin
                for (integer j = 0; j < 4; j = j + 1) begin

                    if (c[i][j] !== a[i][j]) begin
                        $display(
                            "ERROR: Identity test C[%0d][%0d] expected %0d, got %0d",
                            i,
                            j,
                            a[i][j],
                            c[i][j]
                        );
                        $finish;
                    end

                end
            end

            $display("PASS: Identity matrix test");

        end
    endtask


    // ============================================================
    // TEST 2: Non-Trivial Signed Matrix Multiplication
    //
    // A =
    //
    //   [  1   2   3   4 ]
    //   [  5   6   7   8 ]
    //   [ -1   2  -3   4 ]
    //   [ -5  -6   7  -8 ]
    //
    //
    // B =
    //
    //   [ 1  2  0  1 ]
    //   [ 0  1  1  0 ]
    //   [ 1  0  1  2 ]
    //   [ 0  1  2  1 ]
    //
    //
    // Expected C =
    //
    //   [  4    8   13   11 ]
    //   [ 12   24   29   27 ]
    //   [ -4    4    7   -3 ]
    //   [  2  -24  -15    1 ]
    //
    // ============================================================
    task automatic test_signed_matrix;
        begin

            // Matrix A
            a[0][0] =   1;
            a[0][1] =   2;
            a[0][2] =   3;
            a[0][3] =   4;

            a[1][0] =   5;
            a[1][1] =   6;
            a[1][2] =   7;
            a[1][3] =   8;

            a[2][0] =  -1;
            a[2][1] =   2;
            a[2][2] =  -3;
            a[2][3] =   4;

            a[3][0] =  -5;
            a[3][1] =  -6;
            a[3][2] =   7;
            a[3][3] =  -8;


            // Matrix B
            b[0][0] = 1;
            b[0][1] = 2;
            b[0][2] = 0;
            b[0][3] = 1;

            b[1][0] = 0;
            b[1][1] = 1;
            b[1][2] = 1;
            b[1][3] = 0;

            b[2][0] = 1;
            b[2][1] = 0;
            b[2][2] = 1;
            b[2][3] = 2;

            b[3][0] = 0;
            b[3][1] = 1;
            b[3][2] = 2;
            b[3][3] = 1;


            // Start multiplication
            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            // Wait until computation completes
            wait (done == 1'b1);
            #1;


            // ----------------------------------------------------
            // Check expected result
            // ----------------------------------------------------

            // Row 0
            if (c[0][0] !==  32'sd4) begin
                $display("ERROR: C[0][0] expected 4, got %0d", c[0][0]);
                $finish;
            end

            if (c[0][1] !==  32'sd8) begin
                $display("ERROR: C[0][1] expected 8, got %0d", c[0][1]);
                $finish;
            end

            if (c[0][2] !== 32'sd13) begin
                $display("ERROR: C[0][2] expected 13, got %0d", c[0][2]);
                $finish;
            end

            if (c[0][3] !== 32'sd11) begin
                $display("ERROR: C[0][3] expected 11, got %0d", c[0][3]);
                $finish;
            end


            // Row 1
            if (c[1][0] !== 32'sd12) begin
                $display("ERROR: C[1][0] expected 12, got %0d", c[1][0]);
                $finish;
            end

            if (c[1][1] !== 32'sd24) begin
                $display("ERROR: C[1][1] expected 24, got %0d", c[1][1]);
                $finish;
            end

            if (c[1][2] !== 32'sd29) begin
                $display("ERROR: C[1][2] expected 29, got %0d", c[1][2]);
                $finish;
            end

            if (c[1][3] !== 32'sd27) begin
                $display("ERROR: C[1][3] expected 27, got %0d", c[1][3]);
                $finish;
            end


            // Row 2
            if (c[2][0] !== -32'sd4) begin
                $display("ERROR: C[2][0] expected -4, got %0d", c[2][0]);
                $finish;
            end

            if (c[2][1] !== 32'sd4) begin
                $display("ERROR: C[2][1] expected 4, got %0d", c[2][1]);
                $finish;
            end

            if (c[2][2] !== 32'sd7) begin
                $display("ERROR: C[2][2] expected 7, got %0d", c[2][2]);
                $finish;
            end

            if (c[2][3] !== -32'sd3) begin
                $display("ERROR: C[2][3] expected -3, got %0d", c[2][3]);
                $finish;
            end


            // Row 3
            if (c[3][0] !== 32'sd2) begin
                $display("ERROR: C[3][0] expected 2, got %0d", c[3][0]);
                $finish;
            end

            if (c[3][1] !== -32'sd24) begin
                $display("ERROR: C[3][1] expected -24, got %0d", c[3][1]);
                $finish;
            end

            if (c[3][2] !== -32'sd15) begin
                $display("ERROR: C[3][2] expected -15, got %0d", c[3][2]);
                $finish;
            end

            if (c[3][3] !== 32'sd1) begin
                $display("ERROR: C[3][3] expected 1, got %0d", c[3][3]);
                $finish;
            end


            $display("PASS: Signed non-trivial matrix test");

        end
    endtask


    // ============================================================
    // MAIN TEST SEQUENCE
    // ============================================================
    initial begin

        $dumpfile("waveforms/matmul_engine_tb.vcd");
        $dumpvars(0, matmul_engine_tb);

        clk   = 1'b0;
        rst   = 1'b1;
        start = 1'b0;

        // Reset
        #20;

        rst = 1'b0;

        // --------------------------------------------------------
        // Test 1
        // --------------------------------------------------------
        test_identity;

        // Wait one idle cycle between tests
        @(negedge clk);

        // --------------------------------------------------------
        // Test 2
        // --------------------------------------------------------
        test_signed_matrix;

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------
        $display("========================================");
        $display("4x4 MATRIX MULTIPLICATION ALL TESTS PASSED");
        $display("========================================");

        $finish;

    end

endmodule