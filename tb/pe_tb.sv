`timescale 1ns/1ps

module pe_tb;

    logic               clk;
    logic               rst;
    logic               enable;
    logic               clear;

    logic signed [7:0]  a;
    logic signed [7:0]  b;

    logic signed [31:0] result;

    processing_element dut (
        .clk    (clk),
        .rst    (rst),
        .enable (enable),
        .clear  (clear),
        .a      (a),
        .b      (b),
        .result (result)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveforms/pe_tb.vcd");
        $dumpvars(0, pe_tb);

        clk    = 1'b0;
        rst    = 1'b1;
        enable = 1'b0;
        clear  = 1'b0;
        a      = 8'sd0;
        b      = 8'sd0;

        // ---------------------------------------------
        // Reset
        // ---------------------------------------------
        @(negedge clk);
        rst = 1'b0;

        if (result !== 32'sd0) begin
            $display("ERROR: PE did not reset");
            $finish;
        end

        // ---------------------------------------------
        // 5 * 6 = 30
        // ---------------------------------------------
        @(negedge clk);
        a      = 8'sd5;
        b      = 8'sd6;
        enable = 1'b1;

        @(posedge clk);
        #1;

        if (result !== 32'sd30) begin
            $display("ERROR: expected 30, got %0d", result);
            $finish;
        end

        // ---------------------------------------------
        // 30 + (-4 * 3) = 18
        // ---------------------------------------------
        @(negedge clk);
        a = -8'sd4;
        b =  8'sd3;

        @(posedge clk);
        #1;

        if (result !== 32'sd18) begin
            $display("ERROR: expected 18, got %0d", result);
            $finish;
        end

        // ---------------------------------------------
        // 18 + (-2 * -5) = 28
        // ---------------------------------------------
        @(negedge clk);
        a = -8'sd2;
        b = -8'sd5;

        @(posedge clk);
        #1;

        if (result !== 32'sd28) begin
            $display("ERROR: expected 28, got %0d", result);
            $finish;
        end

        // ---------------------------------------------
        // Clear
        // ---------------------------------------------
        @(negedge clk);
        clear  = 1'b1;
        enable = 1'b0;

        @(posedge clk);
        #1;

        clear = 1'b0;

        if (result !== 32'sd0) begin
            $display("ERROR: PE clear failed, got %0d", result);
            $finish;
        end

        // ---------------------------------------------
        // Verify disabled PE holds result
        // ---------------------------------------------
        @(negedge clk);
        a      = 8'sd10;
        b      = 8'sd10;
        enable = 1'b0;

        @(posedge clk);
        #1;

        if (result !== 32'sd0) begin
            $display("ERROR: PE changed while disabled");
            $finish;
        end

        $display("================================");
        $display("PROCESSING ELEMENT TEST PASSED");
        $display("================================");

        $finish;
    end

endmodule