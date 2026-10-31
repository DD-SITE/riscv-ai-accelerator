`timescale 1ns/1ps

module mac_tb;

    logic               clk;
    logic               rst;
    logic               enable;
    logic               clear;

    logic signed [7:0]  a;
    logic signed [7:0]  b;

    logic signed [31:0] acc;

    mac_unit dut (
        .clk    (clk),
        .rst    (rst),
        .enable (enable),
        .clear  (clear),
        .a      (a),
        .b      (b),
        .acc    (acc)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveforms/mac_tb.vcd");
        $dumpvars(0, mac_tb);

        clk    = 1'b0;
        rst    = 1'b1;
        enable = 1'b0;
        clear  = 1'b0;
        a      = 8'sd0;
        b      = 8'sd0;

        // Reset
        @(negedge clk);
        rst = 1'b0;

        if (acc !== 32'sd0) begin
            $display("ERROR: accumulator not reset");
            $finish;
        end

        // ------------------------------------------------
        // Test 1: 3 * 4 = 12
        // ------------------------------------------------
        @(negedge clk);
        a      = 8'sd3;
        b      = 8'sd4;
        enable = 1'b1;

        @(posedge clk);
        #1;

        if (acc !== 32'sd12) begin
            $display("ERROR: 3 * 4 expected 12, got %0d", acc);
            $finish;
        end

        // ------------------------------------------------
        // Test 2: enable = 0 -> accumulator must hold
        // ------------------------------------------------
        @(negedge clk);
        a      = 8'sd10;
        b      = 8'sd10;
        enable = 1'b0;

        @(posedge clk);
        #1;

        if (acc !== 32'sd12) begin
            $display("ERROR: accumulator changed while disabled");
            $finish;
        end

        // ------------------------------------------------
        // Test 3: 12 + (-2 * 5) = 2
        // ------------------------------------------------
        @(negedge clk);
        a      = -8'sd2;
        b      =  8'sd5;
        enable = 1'b1;

        @(posedge clk);
        #1;

        if (acc !== 32'sd2) begin
            $display("ERROR: expected 2, got %0d", acc);
            $finish;
        end

        // ------------------------------------------------
        // Test 4: 2 + (-3 * -4) = 14
        // ------------------------------------------------
        @(negedge clk);
        a = -8'sd3;
        b = -8'sd4;

        @(posedge clk);
        #1;

        if (acc !== 32'sd14) begin
            $display("ERROR: expected 14, got %0d", acc);
            $finish;
        end

        // ------------------------------------------------
        // Test 5: clear accumulator
        // ------------------------------------------------
        @(negedge clk);
        clear  = 1'b1;
        enable = 1'b0;

        @(posedge clk);
        #1;

        clear = 1'b0;

        if (acc !== 32'sd0) begin
            $display("ERROR: clear failed, got %0d", acc);
            $finish;
        end

        // ------------------------------------------------
        // Test 6: negative accumulation
        // -8 * 7 = -56
        // ------------------------------------------------
        @(negedge clk);
        a      = -8'sd8;
        b      =  8'sd7;
        enable = 1'b1;

        @(posedge clk);
        #1;

        if (acc !== -32'sd56) begin
            $display("ERROR: expected -56, got %0d", acc);
            $finish;
        end

        // ------------------------------------------------
        // Test 7: -56 + 4*4 = -40
        // ------------------------------------------------
        @(negedge clk);
        a = 8'sd4;
        b = 8'sd4;

        @(posedge clk);
        #1;

        if (acc !== -32'sd40) begin
            $display("ERROR: expected -40, got %0d", acc);
            $finish;
        end

        $display("================================");
        $display("INT8 MAC TEST PASSED");
        $display("================================");

        $finish;
    end

endmodule