`timescale 1ns/1ps

module soc_bus_tb;

    logic        clk;
    logic        rst;

    logic        cpu_mem_valid;
    logic        cpu_mem_write;
    logic [31:0] cpu_mem_addr;
    logic [31:0] cpu_mem_wdata;
    logic [31:0] cpu_mem_rdata;

    logic        ram_valid;
    logic        ram_write;
    logic [11:0] ram_addr;
    logic [31:0] ram_wdata;
    logic [31:0] ram_rdata;

    logic        accel_valid;
    logic        accel_write;
    logic [4:0]  accel_addr;
    logic [31:0] accel_wdata;
    logic [31:0] accel_rdata;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    soc_bus dut (
        .clk          (clk),
        .rst          (rst),

        .cpu_mem_valid(cpu_mem_valid),
        .cpu_mem_write(cpu_mem_write),
        .cpu_mem_addr (cpu_mem_addr),
        .cpu_mem_wdata(cpu_mem_wdata),
        .cpu_mem_rdata(cpu_mem_rdata),

        .ram_valid    (ram_valid),
        .ram_write    (ram_write),
        .ram_addr     (ram_addr),
        .ram_wdata    (ram_wdata),
        .ram_rdata    (ram_rdata),

        .accel_valid  (accel_valid),
        .accel_write  (accel_write),
        .accel_addr   (accel_addr),
        .accel_wdata  (accel_wdata),
        .accel_rdata  (accel_rdata)
    );

    // ------------------------------------------------------------
    // RAM
    // ------------------------------------------------------------

    soc_ram #(
        .DEPTH(1024)
    ) ram (
        .clk   (clk),
        .rst   (rst),

        .valid (ram_valid),
        .write (ram_write),
        .addr  (ram_addr),
        .wdata (ram_wdata),

        .rdata (ram_rdata)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // CPU-style write
    // ------------------------------------------------------------

    task automatic cpu_write(
        input logic [31:0] addr,
        input logic [31:0] data
    );
        begin
            @(negedge clk);

            cpu_mem_valid = 1'b1;
            cpu_mem_write = 1'b1;
            cpu_mem_addr  = addr;
            cpu_mem_wdata = data;

            @(posedge clk);
            #1;

            cpu_mem_valid = 1'b0;
            cpu_mem_write = 1'b0;
            cpu_mem_addr  = 32'b0;
            cpu_mem_wdata = 32'b0;
        end
    endtask

    // ------------------------------------------------------------
    // CPU-style read
    // ------------------------------------------------------------

    task automatic cpu_read(
        input  logic [31:0] addr,
        output logic [31:0] data
    );
        begin
            @(negedge clk);

            cpu_mem_valid = 1'b1;
            cpu_mem_write = 1'b0;
            cpu_mem_addr  = addr;
            cpu_mem_wdata = 32'b0;

            #1;
            data = cpu_mem_rdata;

            @(posedge clk);
            #1;

            cpu_mem_valid = 1'b0;
            cpu_mem_addr  = 32'b0;
        end
    endtask

    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------

    initial begin
        logic [31:0] read_data;

        $dumpfile("waveforms/soc_bus_tb.vcd");
        $dumpvars(0, soc_bus_tb);

        clk = 1'b0;
        rst = 1'b1;

        cpu_mem_valid = 1'b0;
        cpu_mem_write = 1'b0;
        cpu_mem_addr  = 32'b0;
        cpu_mem_wdata = 32'b0;

        // Fake accelerator read data.
        // This lets us verify accelerator address routing.
        accel_rdata = 32'hAABB_CCDD;

        repeat (2) @(posedge clk);
        rst = 1'b0;

        // ========================================================
        // TEST 1: RAM WRITE
        // ========================================================

        cpu_write(32'h0000_0000, 32'h1234_5678);

        if (!ram_valid) begin
            $display("NOTE: RAM valid is only active during the bus transaction");
        end

        // ========================================================
        // TEST 2: RAM READ
        // ========================================================

        cpu_read(32'h0000_0000, read_data);

        if (read_data !== 32'h1234_5678) begin
            $display(
                "ERROR: RAM read expected 0x12345678, got 0x%08h",
                read_data
            );
            $finish;
        end

        $display("PASS: RAM write/read");

        // ========================================================
        // TEST 3: SECOND RAM LOCATION
        // ========================================================

        cpu_write(32'h0000_0004, 32'hDEAD_BEEF);

        cpu_read(32'h0000_0004, read_data);

        if (read_data !== 32'hDEAD_BEEF) begin
            $display(
                "ERROR: RAM second location expected 0xDEADBEEF, got 0x%08h",
                read_data
            );
            $finish;
        end

        $display("PASS: Multiple RAM locations");

        // ========================================================
        // TEST 4: ACCELERATOR CONTROL WRITE
        // ========================================================

        @(negedge clk);

        cpu_mem_valid = 1'b1;
        cpu_mem_write = 1'b1;
        cpu_mem_addr  = 32'h0000_1000;
        cpu_mem_wdata = 32'h0000_0001;

        #1;

        if (!accel_valid) begin
            $display("ERROR: Accelerator CONTROL not selected");
            $finish;
        end

        if (!accel_write) begin
            $display("ERROR: Accelerator CONTROL write not detected");
            $finish;
        end

        if (accel_addr !== 5'h00) begin
            $display(
                "ERROR: CONTROL address expected 0x00, got 0x%02h",
                accel_addr
            );
            $finish;
        end

        if (accel_wdata !== 32'h0000_0001) begin
            $display(
                "ERROR: CONTROL data mismatch: got 0x%08h",
                accel_wdata
            );
            $finish;
        end

        @(posedge clk);
        #1;

        cpu_mem_valid = 1'b0;
        cpu_mem_write = 1'b0;

        $display("PASS: Accelerator CONTROL routing");

        // ========================================================
        // TEST 5: ACCELERATOR STATUS READ
        // ========================================================

        cpu_read(32'h0000_1004, read_data);

        if (read_data !== 32'hAABB_CCDD) begin
            $display(
                "ERROR: STATUS read expected accelerator data 0xAABBCCDD, got 0x%08h",
                read_data
            );
            $finish;
        end

        $display("PASS: Accelerator STATUS read routing");

        // ========================================================
        // TEST 6: A_DATA WRITE
        // ========================================================

        @(negedge clk);

        cpu_mem_valid = 1'b1;
        cpu_mem_write = 1'b1;
        cpu_mem_addr  = 32'h0000_1008;
        cpu_mem_wdata = 32'h0000_00FE;

        #1;

        if (!accel_valid || !accel_write) begin
            $display("ERROR: A_DATA write not routed to accelerator");
            $finish;
        end

        if (accel_addr !== 5'h08) begin
            $display(
                "ERROR: A_DATA address expected 0x08, got 0x%02h",
                accel_addr
            );
            $finish;
        end

        if (accel_wdata !== 32'h0000_00FE) begin
            $display(
                "ERROR: A_DATA value mismatch: got 0x%08h",
                accel_wdata
            );
            $finish;
        end

        @(posedge clk);
        #1;

        cpu_mem_valid = 1'b0;
        cpu_mem_write = 1'b0;

        $display("PASS: Accelerator A_DATA routing");

        // ========================================================
        // TEST 7: B_DATA WRITE
        // ========================================================

        @(negedge clk);

        cpu_mem_valid = 1'b1;
        cpu_mem_write = 1'b1;
        cpu_mem_addr  = 32'h0000_100C;
        cpu_mem_wdata = 32'h0000_007F;

        #1;

        if (!accel_valid || !accel_write) begin
            $display("ERROR: B_DATA write not routed to accelerator");
            $finish;
        end

        if (accel_addr !== 5'h0C) begin
            $display(
                "ERROR: B_DATA address expected 0x0C, got 0x%02h",
                accel_addr
            );
            $finish;
        end

        if (accel_wdata !== 32'h0000_007F) begin
            $display(
                "ERROR: B_DATA value mismatch: got 0x%08h",
                accel_wdata
            );
            $finish;
        end

        @(posedge clk);
        #1;

        cpu_mem_valid = 1'b0;
        cpu_mem_write = 1'b0;

        $display("PASS: Accelerator B_DATA routing");

        // ========================================================
        // TEST 8: C_DATA READ
        // ========================================================

        cpu_read(32'h0000_1010, read_data);

        if (read_data !== 32'hAABB_CCDD) begin
            $display(
                "ERROR: C_DATA read expected 0xAABBCCDD, got 0x%08h",
                read_data
            );
            $finish;
        end

        $display("PASS: Accelerator C_DATA read routing");

        // ========================================================
        // TEST 9: INVALID ADDRESS
        // ========================================================

        cpu_read(32'h0000_2000, read_data);

        if (read_data !== 32'b0) begin
            $display(
                "ERROR: Invalid address expected 0, got 0x%08h",
                read_data
            );
            $finish;
        end

        $display("PASS: Invalid address handling");

        // ========================================================
        // FINAL RESULT
        // ========================================================

        $display("");
        $display("========================================");
        $display("SOC BUS TEST PASSED");
        $display("========================================");

        $finish;
    end

endmodule