`timescale 1ns/1ps

module cpu_tb;

    logic clk;
    logic rst;

    logic [31:0] imem_addr;
    logic [31:0] imem_instruction;

    logic        dmem_read;
    logic        dmem_write;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_write_data;
    logic [31:0] dmem_read_data;

    logic [31:0] debug_pc;

    // ------------------------------------------------------------
    // CPU
    // ------------------------------------------------------------

    cpu dut (
        .clk(clk),
        .rst(rst),

        .imem_addr(imem_addr),
        .imem_instruction(imem_instruction),

        .dmem_read(dmem_read),
        .dmem_write(dmem_write),
        .dmem_addr(dmem_addr),
        .dmem_write_data(dmem_write_data),
        .dmem_read_data(dmem_read_data),

        .debug_pc(debug_pc)
    );

    // ------------------------------------------------------------
    // Simple instruction memory
    // ------------------------------------------------------------

    logic [31:0] imem [0:31];

    assign imem_instruction = imem[imem_addr[6:2]];

    // ------------------------------------------------------------
    // Simple data memory
    // ------------------------------------------------------------

    logic [31:0] dmem [0:31];

    assign dmem_read_data = dmem[dmem_addr[6:2]];

    always_ff @(posedge clk) begin
        if (dmem_write)
            dmem[dmem_addr[6:2]] <= dmem_write_data;
    end

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Program
    // ------------------------------------------------------------
    //
    // 0: ADDI x1, x0, 10
    // 4: ADDI x2, x0, 20
    // 8: ADD  x3, x1, x2
    // 12: SW x3, 0(x0)
    // 16: LW x4, 0(x0)
    // 20: ADDI x5, x4, 5
    //
    // Expected:
    // x1 = 10
    // x2 = 20
    // x3 = 30
    // x4 = 30
    // x5 = 35
    //
    // ------------------------------------------------------------

    initial begin

        // ADDI x1, x0, 10
        imem[0] = 32'h00A00093;

        // ADDI x2, x0, 20
        imem[1] = 32'h01400113;

        // ADD x3, x1, x2
        imem[2] = 32'h002081B3;

        // SW x3, 0(x0)
        imem[3] = 32'h00302023;

        // LW x4, 0(x0)
        imem[4] = 32'h00002203;

        // ADDI x5, x4, 5
        imem[5] = 32'h00520293;

        // NOP
        imem[6] = 32'h00000013;
        imem[7] = 32'h00000013;
        imem[8] = 32'h00000013;

    end

    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------

    initial begin

        $dumpfile("waveforms/cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        clk = 0;
        rst = 1;

        #12;
        rst = 0;

        // Allow program to execute
        repeat (8)
            @(posedge clk);

        #1;

        // Check x1
        if (dut.register_file.regs[1] !== 32'd10) begin
            $display(
                "ERROR: x1 expected 10, got %0d",
                dut.register_file.regs[1]
            );
            $finish;
        end

        // Check x2
        if (dut.register_file.regs[2] !== 32'd20) begin
            $display(
                "ERROR: x2 expected 20, got %0d",
                dut.register_file.regs[2]
            );
            $finish;
        end

        // Check x3
        if (dut.register_file.regs[3] !== 32'd30) begin
            $display(
                "ERROR: x3 expected 30, got %0d",
                dut.register_file.regs[3]
            );
            $finish;
        end

        // Check memory
        if (dmem[0] !== 32'd30) begin
            $display(
                "ERROR: memory[0] expected 30, got %0d",
                dmem[0]
            );
            $finish;
        end

        // Check x4
        if (dut.register_file.regs[4] !== 32'd30) begin
            $display(
                "ERROR: x4 expected 30, got %0d",
                dut.register_file.regs[4]
            );
            $finish;
        end

        // Check x5
        if (dut.register_file.regs[5] !== 32'd35) begin
            $display(
                "ERROR: x5 expected 35, got %0d",
                dut.register_file.regs[5]
            );
            $finish;
        end

        $display("================================");
        $display("RV32I CPU TEST PASSED");
        $display("================================");

        $finish;

    end

endmodule