`timescale 1ns/1ps

`ifndef NUM_PE_VALUE
    `define NUM_PE_VALUE 4
`endif

module matmul_scaling_tb;

    localparam integer NUM_PE = `NUM_PE_VALUE;

    logic clk;
    logic rst;
    logic start;

    logic [127:0] a_flat;
    logic [127:0] b_flat;

    logic [511:0] c_flat;

    logic busy;
    logic done;

    logic [31:0] cycle_count;


    matmul_scalable #(
        .NUM_PE(NUM_PE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),

        .a_flat(a_flat),
        .b_flat(b_flat),

        .c_flat(c_flat),

        .busy(busy),
        .done(done),

        .cycle_count(cycle_count)
    );


    always #5 clk = ~clk;


    task automatic set_a;

        integer i;

        begin

            a_flat = 128'b0;

            a_flat[(0*8) +: 8] = $signed(8'sd1);
            a_flat[(1*8) +: 8] = $signed(8'sd2);
            a_flat[(2*8) +: 8] = $signed(8'sd3);
            a_flat[(3*8) +: 8] = $signed(8'sd4);

            a_flat[(4*8) +: 8] = $signed(8'sd5);
            a_flat[(5*8) +: 8] = $signed(8'sd6);
            a_flat[(6*8) +: 8] = $signed(8'sd7);
            a_flat[(7*8) +: 8] = $signed(8'sd8);

            a_flat[(8*8) +: 8] = $signed(-8'sd1);
            a_flat[(9*8) +: 8] = $signed(8'sd2);
            a_flat[(10*8) +: 8] = $signed(-8'sd3);
            a_flat[(11*8) +: 8] = $signed(8'sd4);

            a_flat[(12*8) +: 8] = $signed(-8'sd5);
            a_flat[(13*8) +: 8] = $signed(-8'sd6);
            a_flat[(14*8) +: 8] = $signed(8'sd7);
            a_flat[(15*8) +: 8] = $signed(-8'sd8);

        end

    endtask


    task automatic set_b;

        begin

            b_flat = 128'b0;

            b_flat[(0*8) +: 8] = $signed(8'sd1);
            b_flat[(1*8) +: 8] = $signed(8'sd2);
            b_flat[(2*8) +: 8] = $signed(8'sd0);
            b_flat[(3*8) +: 8] = $signed(8'sd1);

            b_flat[(4*8) +: 8] = $signed(8'sd0);
            b_flat[(5*8) +: 8] = $signed(8'sd1);
            b_flat[(6*8) +: 8] = $signed(8'sd1);
            b_flat[(7*8) +: 8] = $signed(8'sd0);

            b_flat[(8*8) +: 8] = $signed(8'sd1);
            b_flat[(9*8) +: 8] = $signed(8'sd0);
            b_flat[(10*8) +: 8] = $signed(8'sd1);
            b_flat[(11*8) +: 8] = $signed(8'sd2);

            b_flat[(12*8) +: 8] = $signed(8'sd0);
            b_flat[(13*8) +: 8] = $signed(8'sd1);
            b_flat[(14*8) +: 8] = $signed(8'sd2);
            b_flat[(15*8) +: 8] = $signed(8'sd1);

        end

    endtask


    task automatic check_result;

        integer expected [4][4];

        integer r;
        integer col;
        integer index;

        integer actual_value;
        integer errors;

        begin

            expected[0][0] = 4;
            expected[0][1] = 8;
            expected[0][2] = 13;
            expected[0][3] = 11;

            expected[1][0] = 12;
            expected[1][1] = 24;
            expected[1][2] = 29;
            expected[1][3] = 27;

            expected[2][0] = -4;
            expected[2][1] = 4;
            expected[2][2] = 7;
            expected[2][3] = -3;

            expected[3][0] = 2;
            expected[3][1] = -24;
            expected[3][2] = -15;
            expected[3][3] = 1;


            errors = 0;


            for (r = 0; r < 4; r = r + 1) begin

                for (col = 0; col < 4; col = col + 1) begin

                    index = r * 4 + col;

                    actual_value =
                        $signed(c_flat[index*32 +: 32]);


                    if (actual_value !== expected[r][col]) begin

                        $display(
                            "ERROR: C[%0d][%0d] expected %0d got %0d",
                            r,
                            col,
                            expected[r][col],
                            actual_value
                        );

                        errors = errors + 1;

                    end

                end

            end


            if (errors == 0) begin

                $display(
                    "PASS: %0d-PE matrix result correct",
                    NUM_PE
                );

            end

            else begin

                $display(
                    "FAIL: %0d-PE matrix result has %0d errors",
                    NUM_PE,
                    errors
                );

            end

        end

    endtask


    initial begin

        clk   = 1'b0;
        rst   = 1'b1;
        start = 1'b0;

        set_a();
        set_b();


        /*
         * Reset.
         */
        #20;

        rst = 1'b0;

        #10;


        /*
         * Start.
         */
        start = 1'b1;

        #10;

        start = 1'b0;


        /*
         * Wait for accelerator completion.
         */
        wait(done);

        #10;


        /*
         * Results.
         */
        $display("");
        $display("==============================================");
        $display("%0d-PE SCALING BENCHMARK", NUM_PE);
        $display("==============================================");

        $display(
            "Measured cycles = %0d",
            cycle_count
        );

        $display("");
        $display("RESULT MATRIX:");


        $display(
            "%0d %0d %0d %0d",
            $signed(c_flat[0*32 +: 32]),
            $signed(c_flat[1*32 +: 32]),
            $signed(c_flat[2*32 +: 32]),
            $signed(c_flat[3*32 +: 32])
        );


        $display(
            "%0d %0d %0d %0d",
            $signed(c_flat[4*32 +: 32]),
            $signed(c_flat[5*32 +: 32]),
            $signed(c_flat[6*32 +: 32]),
            $signed(c_flat[7*32 +: 32])
        );


        $display(
            "%0d %0d %0d %0d",
            $signed(c_flat[8*32 +: 32]),
            $signed(c_flat[9*32 +: 32]),
            $signed(c_flat[10*32 +: 32]),
            $signed(c_flat[11*32 +: 32])
        );


        $display(
            "%0d %0d %0d %0d",
            $signed(c_flat[12*32 +: 32]),
            $signed(c_flat[13*32 +: 32]),
            $signed(c_flat[14*32 +: 32]),
            $signed(c_flat[15*32 +: 32])
        );


        check_result();

        $display("");

        $finish;

    end

endmodule
