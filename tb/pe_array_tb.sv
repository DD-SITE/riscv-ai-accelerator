`timescale 1ns/1ps

module pe_array_tb;

    localparam integer NUM_PE = 4;

    logic                   clk;
    logic                   rst;
    logic                   enable;
    logic                   clear;

    logic signed [7:0]      a [NUM_PE];
    logic signed [7:0]      b [NUM_PE];

    logic signed [31:0]     result [NUM_PE];

    pe_array #(
        .NUM_PE(NUM_PE)
    ) dut (
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
        $dumpfile("waveforms/pe_array_tb.vcd");
        $dumpvars(0, pe_array_tb);

        clk    = 1'b0;
        rst    = 1'b1;
        enable = 1'b0;
        clear  = 1'b0;

        for (integer i = 0; i < NUM_PE; i = i + 1) begin
            a[i] = 8'sd0;
            b[i] = 8'sd0;
        end

        // ---------------------------------------------
        // Reset
        // ---------------------------------------------
        @(negedge clk);
        rst = 1'b0;

        for (integer i = 0; i < NUM_PE; i = i + 1) begin
            if (result[i] !== 32'sd0) begin
                $display("ERROR: PE%0d not reset", i);
                $finish;
            end
        end

        // ---------------------------------------------
        // First parallel computation
        //
        // PE0:  2 * 3  =  6
        // PE1:  4 * 5  = 20
        // PE2: -3 * 6  = -18
        // PE3: -4 * -2 =  8
        // ---------------------------------------------
        @(negedge clk);

        a[0] =  8'sd2;
        b[0] =  8'sd3;

        a[1] =  8'sd4;
        b[1] =  8'sd5;

        a[2] = -8'sd3;
        b[2] =  8'sd6;

        a[3] = -8'sd4;
        b[3] = -8'sd2;

        enable = 1'b1;

        @(posedge clk);
        #1;

        if (result[0] !== 32'sd6) begin
            $display("ERROR: PE0 expected 6, got %0d", result[0]);
            $finish;
        end

        if (result[1] !== 32'sd20) begin
            $display("ERROR: PE1 expected 20, got %0d", result[1]);
            $finish;
        end

        if (result[2] !== -32'sd18) begin
            $display("ERROR: PE2 expected -18, got %0d", result[2]);
            $finish;
        end

        if (result[3] !== 32'sd8) begin
            $display("ERROR: PE3 expected 8, got %0d", result[3]);
            $finish;
        end

        // ---------------------------------------------
        // Second parallel computation
        //
        // PE0: 6 + 1*10  = 16
        // PE1: 20 + 2*10 = 40
        // PE2: -18 + 3*2 = -12
        // PE3: 8 + 4*3   = 20
        // ---------------------------------------------
        @(negedge clk);

        a[0] = 8'sd1;
        b[0] = 8'sd10;

        a[1] = 8'sd2;
        b[1] = 8'sd10;

        a[2] = 8'sd3;
        b[2] = 8'sd2;

        a[3] = 8'sd4;
        b[3] = 8'sd3;

        @(posedge clk);
        #1;

        if (result[0] !== 32'sd16) begin
            $display("ERROR: PE0 expected 16, got %0d", result[0]);
            $finish;
        end

        if (result[1] !== 32'sd40) begin
            $display("ERROR: PE1 expected 40, got %0d", result[1]);
            $finish;
        end

        if (result[2] !== -32'sd12) begin
            $display("ERROR: PE2 expected -12, got %0d", result[2]);
            $finish;
        end

        if (result[3] !== 32'sd20) begin
            $display("ERROR: PE3 expected 20, got %0d", result[3]);
            $finish;
        end

        // ---------------------------------------------
        // Disable array and verify results hold
        // ---------------------------------------------
        @(negedge clk);
        enable = 1'b0;

        a[0] = 8'sd100;
        b[0] = 8'sd100;

        @(posedge clk);
        #1;

        if (result[0] !== 32'sd16) begin
            $display("ERROR: PE0 changed while disabled");
            $finish;
        end

        // ---------------------------------------------
        // Clear all PEs
        // ---------------------------------------------
        @(negedge clk);
        clear  = 1'b1;
        enable = 1'b0;

        @(posedge clk);
        #1;

        clear = 1'b0;

        for (integer i = 0; i < NUM_PE; i = i + 1) begin
            if (result[i] !== 32'sd0) begin
                $display(
                    "ERROR: PE%0d did not clear, got %0d",
                    i,
                    result[i]
                );
                $finish;
            end
        end

        $display("================================");
        $display("4-PE ARRAY TEST PASSED");
        $display("================================");

        $finish;
    end

endmodule