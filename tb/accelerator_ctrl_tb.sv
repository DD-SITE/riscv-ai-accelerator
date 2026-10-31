`timescale 1ns/1ps

module accelerator_ctrl_tb;

    logic               clk;
    logic               rst;

    // ============================================================
    // CPU bus
    // ============================================================

    logic               bus_valid;
    logic               bus_write;
    logic [4:0]         bus_addr;
    logic [31:0]        bus_wdata;

    logic [31:0]        bus_rdata;

    logic               busy;
    logic               done;


    // ============================================================
    // Device under test
    // ============================================================

    accelerator_ctrl dut (
        .clk       (clk),
        .rst       (rst),

        .bus_valid (bus_valid),
        .bus_write  (bus_write),
        .bus_addr   (bus_addr),
        .bus_wdata  (bus_wdata),

        .bus_rdata  (bus_rdata),

        .busy       (busy),
        .done       (done)
    );


    // ============================================================
    // Clock
    // ============================================================

    always #5 clk = ~clk;


    // ============================================================
    // Bus write task
    // ============================================================

    task automatic bus_write_word(
        input logic [4:0]  addr,
        input logic [31:0] data
    );

        begin

            @(negedge clk);

            bus_valid = 1'b1;
            bus_write = 1'b1;
            bus_addr  = addr;
            bus_wdata = data;

            @(posedge clk);

            #1;

            bus_valid = 1'b0;
            bus_write = 1'b0;
            bus_addr  = 5'b0;
            bus_wdata = 32'b0;

        end

    endtask


    // ============================================================
    // Bus read task
    // ============================================================

    task automatic bus_read_word(
        input  logic [4:0] addr,
        output logic [31:0] data
    );

        begin

            @(negedge clk);

            bus_valid = 1'b1;
            bus_write = 1'b0;
            bus_addr  = addr;
            bus_wdata = 32'b0;

            #1;

            data = bus_rdata;

            @(posedge clk);

            #1;

            bus_valid = 1'b0;
            bus_addr  = 5'b0;

        end

    endtask


    // ============================================================
    // Test
    // ============================================================

    initial begin

        logic [31:0] read_data;


        // --------------------------------------------------------
        // VCD
        // --------------------------------------------------------

        $dumpfile("waveforms/accelerator_ctrl_tb.vcd");
        $dumpvars(0, accelerator_ctrl_tb);


        // --------------------------------------------------------
        // Initial values
        // --------------------------------------------------------

        clk       = 1'b0;
        rst       = 1'b1;

        bus_valid = 1'b0;
        bus_write = 1'b0;
        bus_addr  = 5'b0;
        bus_wdata = 32'b0;


        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        repeat (2) @(posedge clk);

        rst = 1'b0;

        @(posedge clk);


        // ========================================================
        // MATRIX A
        //
        // [  1   2   3   4 ]
        // [  5   6   7   8 ]
        // [ -1   2  -3   4 ]
        // [ -5  -6   7  -8 ]
        // ========================================================

        bus_write_word(5'h08, 32'sd1);
        bus_write_word(5'h08, 32'sd2);
        bus_write_word(5'h08, 32'sd3);
        bus_write_word(5'h08, 32'sd4);

        bus_write_word(5'h08, 32'sd5);
        bus_write_word(5'h08, 32'sd6);
        bus_write_word(5'h08, 32'sd7);
        bus_write_word(5'h08, 32'sd8);

        bus_write_word(5'h08, -32'sd1);
        bus_write_word(5'h08, 32'sd2);
        bus_write_word(5'h08, -32'sd3);
        bus_write_word(5'h08, 32'sd4);

        bus_write_word(5'h08, -32'sd5);
        bus_write_word(5'h08, -32'sd6);
        bus_write_word(5'h08, 32'sd7);
        bus_write_word(5'h08, -32'sd8);


        // ========================================================
        // MATRIX B
        //
        // [ 1  2  0  1 ]
        // [ 0  1  1  0 ]
        // [ 1  0  1  2 ]
        // [ 0  1  2  1 ]
        // ========================================================

        bus_write_word(5'h0C, 32'sd1);
        bus_write_word(5'h0C, 32'sd2);
        bus_write_word(5'h0C, 32'sd0);
        bus_write_word(5'h0C, 32'sd1);

        bus_write_word(5'h0C, 32'sd0);
        bus_write_word(5'h0C, 32'sd1);
        bus_write_word(5'h0C, 32'sd1);
        bus_write_word(5'h0C, 32'sd0);

        bus_write_word(5'h0C, 32'sd1);
        bus_write_word(5'h0C, 32'sd0);
        bus_write_word(5'h0C, 32'sd1);
        bus_write_word(5'h0C, 32'sd2);

        bus_write_word(5'h0C, 32'sd0);
        bus_write_word(5'h0C, 32'sd1);
        bus_write_word(5'h0C, 32'sd2);
        bus_write_word(5'h0C, 32'sd1);


        // ========================================================
        // START
        // ========================================================

        bus_write_word(5'h00, 32'h00000001);


        // ========================================================
        // Verify BUSY becomes active
        // ========================================================

        wait (busy == 1'b1);

        $display("PASS: Accelerator entered BUSY state");


        // ========================================================
        // Wait for accelerator completion
        // ========================================================

        wait (done == 1'b1);

        $display("PASS: Accelerator completed computation");


        // ========================================================
        // Read C matrix
        //
        // Expected:
        //
        // [  4    8   13   11 ]
        // [ 12   24   29   27 ]
        // [ -4    4    7   -3 ]
        // [  2  -24  -15    1 ]
        // ========================================================

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== 32'sd4) begin
            $display("ERROR: C[0][0] expected 4, got %0d",
                     $signed(read_data));
            $finish;
        end

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== 32'sd8) begin
            $display("ERROR: C[0][1] expected 8, got %0d",
                     $signed(read_data));
            $finish;
        end

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== 32'sd13) begin
            $display("ERROR: C[0][2] expected 13, got %0d",
                     $signed(read_data));
            $finish;
        end

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== 32'sd11) begin
            $display("ERROR: C[0][3] expected 11, got %0d",
                     $signed(read_data));
            $finish;
        end


        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== 32'sd12) begin
            $display("ERROR: C[1][0] expected 12, got %0d",
                     $signed(read_data));
            $finish;
        end

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== 32'sd24) begin
            $display("ERROR: C[1][1] expected 24, got %0d",
                     $signed(read_data));
            $finish;
        end

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== 32'sd29) begin
            $display("ERROR: C[1][2] expected 29, got %0d",
                     $signed(read_data));
            $finish;
        end

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== 32'sd27) begin
            $display("ERROR: C[1][3] expected 27, got %0d",
                     $signed(read_data));
            $finish;
        end


        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== -32'sd4) begin
            $display("ERROR: C[2][0] expected -4, got %0d",
                     $signed(read_data));
            $finish;
        end

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== 32'sd4) begin
            $display("ERROR: C[2][1] expected 4, got %0d",
                     $signed(read_data));
            $finish;
        end

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== 32'sd7) begin
            $display("ERROR: C[2][2] expected 7, got %0d",
                     $signed(read_data));
            $finish;
        end

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== -32'sd3) begin
            $display("ERROR: C[2][3] expected -3, got %0d",
                     $signed(read_data));
            $finish;
        end


        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== 32'sd2) begin
            $display("ERROR: C[3][0] expected 2, got %0d",
                     $signed(read_data));
            $finish;
        end

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== -32'sd24) begin
            $display("ERROR: C[3][1] expected -24, got %0d",
                     $signed(read_data));
            $finish;
        end

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== -32'sd15) begin
            $display("ERROR: C[3][2] expected -15, got %0d",
                     $signed(read_data));
            $finish;
        end

        bus_read_word(5'h10, read_data);

        if ($signed(read_data) !== 32'sd1) begin
            $display("ERROR: C[3][3] expected 1, got %0d",
                     $signed(read_data));
            $finish;
        end


        // ========================================================
        // Final result
        // ========================================================

        $display("========================================");
        $display("ACCELERATOR CONTROLLER TEST PASSED");
        $display("========================================");

        $finish;

    end

endmodule