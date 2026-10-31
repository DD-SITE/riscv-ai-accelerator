`timescale 1ns/1ps

module riscv_ai_soc_tb;

    logic clk;
    logic rst;

    logic [31:0] debug_pc;
    logic accel_busy;
    logic accel_done;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    riscv_ai_soc dut (
        .clk        (clk),
        .rst        (rst),
        .debug_pc   (debug_pc),
        .accel_busy (accel_busy),
        .accel_done (accel_done)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // DEBUG MONITOR
    // ------------------------------------------------------------

    always @(posedge clk) begin

        if (!rst &&
            dut.cpu_dmem_write &&
            ((dut.cpu_dmem_addr >= 32'h0000_1000) &&
             (dut.cpu_dmem_addr <= 32'h0000_1010))) begin

            $display(
                "MMIO WRITE: PC=0x%08h  ADDR=0x%08h  DATA=0x%08h (%0d)",
                debug_pc,
                dut.cpu_dmem_addr,
                dut.cpu_dmem_write_data,
                $signed(dut.cpu_dmem_write_data)
            );

        end

        // --------------------------------------------------------
        // C_DATA READ TRACE
        // --------------------------------------------------------

        if (!rst &&
            dut.cpu_dmem_read &&
            (dut.cpu_dmem_addr == 32'h0000_1010)) begin

            $display(
                "C_DATA READ: PC=0x%08h  c_index=%0d  C_DATA=0x%08h (%0d)  busy=%b  done=%b  busy_latched=%b",
                debug_pc,
                dut.accelerator.c_index,
                dut.cpu_dmem_read_data,
                $signed(dut.cpu_dmem_read_data),
                dut.accelerator.matmul_busy,
                dut.accelerator.matmul_done,
                dut.accelerator.busy_latched
            );

        end

    end

    // ------------------------------------------------------------
    // RV32I instruction encoders
    // ------------------------------------------------------------

    function automatic [31:0] enc_lui(
        input integer rd,
        input integer imm20
    );
        enc_lui = {
            imm20[19:0],
            rd[4:0],
            7'b0110111
        };
    endfunction

    function automatic [31:0] enc_addi(
        input integer rd,
        input integer rs1,
        input integer imm12
    );
        enc_addi = {
            imm12[11:0],
            rs1[4:0],
            3'b000,
            rd[4:0],
            7'b0010011
        };
    endfunction

    function automatic [31:0] enc_andi(
        input integer rd,
        input integer rs1,
        input integer imm12
    );
        enc_andi = {
            imm12[11:0],
            rs1[4:0],
            3'b111,
            rd[4:0],
            7'b0010011
        };
    endfunction

    function automatic [31:0] enc_lw(
        input integer rd,
        input integer rs1,
        input integer imm12
    );
        enc_lw = {
            imm12[11:0],
            rs1[4:0],
            3'b010,
            rd[4:0],
            7'b0000011
        };
    endfunction

    function automatic [31:0] enc_sw(
        input integer rs2,
        input integer rs1,
        input integer imm12
    );
        enc_sw = {
            imm12[11:5],
            rs2[4:0],
            rs1[4:0],
            3'b010,
            imm12[4:0],
            7'b0100011
        };
    endfunction

    function automatic [31:0] enc_beq(
        input integer rs1,
        input integer rs2,
        input integer imm13
    );
        reg [12:0] imm;

        begin
            imm = imm13[12:0];

            enc_beq = {
                imm[12],
                imm[10:5],
                rs2[4:0],
                rs1[4:0],
                3'b000,
                imm[4:1],
                imm[11],
                7'b1100011
            };
        end
    endfunction

    // ------------------------------------------------------------
    // Program storage helper
    // ------------------------------------------------------------

    integer pc_index;

    task automatic emit(
        input [31:0] instruction
    );
        begin
            dut.ram.mem[pc_index] = instruction;
            pc_index = pc_index + 1;
        end
    endtask

    // ------------------------------------------------------------
    // Test variables
    // ------------------------------------------------------------

    integer i;
    integer halt_pc;

    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------

    initial begin

        clk = 1'b0;
        rst = 1'b1;
        pc_index = 0;

        // --------------------------------------------------------
        // Keep reset asserted while program is loaded.
        //
        // The #1 after the reset edges prevents the RAM reset NBA
        // from overwriting the program loaded below.
        // --------------------------------------------------------

        repeat (3) @(posedge clk);
        #1;

        // ========================================================
        // PROGRAM
        // ========================================================

        // --------------------------------------------------------
        // x1 = A_DATA = 0x1008
        // --------------------------------------------------------

        emit(enc_lui(1, 1));
        emit(enc_addi(1, 1, 8));

        // --------------------------------------------------------
        // Write A matrix
        // --------------------------------------------------------

        emit(enc_addi(2, 0, 1));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, 2));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, 3));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, 4));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, 5));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, 6));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, 7));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, 8));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, -1));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, 2));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, -3));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, 4));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, -5));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, -6));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, 7));
        emit(enc_sw  (2, 1, 0));

        emit(enc_addi(2, 0, -8));
        emit(enc_sw  (2, 1, 0));

        // --------------------------------------------------------
        // x2 = B_DATA = 0x100c
        // --------------------------------------------------------

        emit(enc_addi(2, 1, 4));

        // --------------------------------------------------------
        // Write B matrix
        // --------------------------------------------------------

        emit(enc_addi(6, 0, 1));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 2));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 0));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 1));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 0));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 1));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 1));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 0));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 1));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 0));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 1));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 2));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 0));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 1));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 2));
        emit(enc_sw  (6, 2, 0));

        emit(enc_addi(6, 0, 1));
        emit(enc_sw  (6, 2, 0));

        // --------------------------------------------------------
        // x3 = CONTROL = 0x1000
        // --------------------------------------------------------

        emit(enc_addi(3, 1, -8));

        // --------------------------------------------------------
        // Start accelerator
        // --------------------------------------------------------

        emit(enc_addi(6, 0, 1));
        emit(enc_sw  (6, 3, 0));

        // --------------------------------------------------------
        // x4 = STATUS = 0x1004
        // --------------------------------------------------------

        emit(enc_addi(4, 3, 4));

        // --------------------------------------------------------
        // Poll DONE
        //
        // STATUS bit 0 = BUSY
        // STATUS bit 1 = DONE
        //
        // DONE is sticky in accelerator_ctrl, so software waits
        // until bit 1 becomes 1.
        // --------------------------------------------------------

        emit(enc_lw   (6, 4, 0));
        emit(enc_andi (6, 6, 2));
        emit(enc_beq  (6, 0, -8));

        // --------------------------------------------------------
        // x5 = C_DATA = 0x1010
        // --------------------------------------------------------

        emit(enc_addi(5, 3, 16));

        // --------------------------------------------------------
        // x7 = RAM result address = 0x0200
        // --------------------------------------------------------

        emit(enc_addi(7, 0, 12'h200));

        // --------------------------------------------------------
        // Read 16 C values and store into RAM.
        // --------------------------------------------------------

        for (i = 0; i < 16; i = i + 1) begin

            emit(enc_lw  (6, 5, 0));
            emit(enc_sw  (6, 7, 0));
            emit(enc_addi(7, 7, 4));

        end

        // --------------------------------------------------------
        // Halt loop
        // --------------------------------------------------------

        halt_pc = pc_index * 4;

        emit(enc_beq(0, 0, 0));

        // ========================================================
        // PROGRAM LOADED
        // ========================================================

        $display("");
        $display("==============================================");
        $display("Program loaded successfully");
        $display("Program size: %0d instructions", pc_index);
        $display("Program halt PC: 0x%08h", halt_pc);
        $display("Reset still asserted: YES");
        $display("==============================================");
        $display("");

        // --------------------------------------------------------
        // Release reset
        // --------------------------------------------------------

        rst = 1'b0;
        #1;

        // --------------------------------------------------------
        // Wait for halt
        // --------------------------------------------------------

        wait (debug_pc == halt_pc);

        repeat (5) @(posedge clk);

        // ========================================================
        // BASIC PASS CHECKS
        // ========================================================

        if (debug_pc == halt_pc)
            $display("PASS: CPU reached halt loop");

        if (accel_done)
            $display("PASS: Accelerator completed");

        if (dut.accelerator.c_matrix[0][0] == 32'sd4)
            $display("PASS: Accelerator C[0][0] correct");

        // ========================================================
        // DEBUG CPU REGISTER STATE
        // ========================================================

        $display("");
        $display("================================================");
        $display("DEBUG: CPU REGISTER STATE");
        $display("================================================");

        $display("x1 = 0x%08h (%0d)",
                 dut.cpu.register_file.regs[1],
                 $signed(dut.cpu.register_file.regs[1]));

        $display("x2 = 0x%08h (%0d)",
                 dut.cpu.register_file.regs[2],
                 $signed(dut.cpu.register_file.regs[2]));

        $display("x3 = 0x%08h (%0d)",
                 dut.cpu.register_file.regs[3],
                 $signed(dut.cpu.register_file.regs[3]));

        $display("x4 = 0x%08h (%0d)",
                 dut.cpu.register_file.regs[4],
                 $signed(dut.cpu.register_file.regs[4]));

        $display("x5 = 0x%08h (%0d)",
                 dut.cpu.register_file.regs[5],
                 $signed(dut.cpu.register_file.regs[5]));

        $display("x6 = 0x%08h (%0d)",
                 dut.cpu.register_file.regs[6],
                 $signed(dut.cpu.register_file.regs[6]));

        $display("x7 = 0x%08h (%0d)",
                 dut.cpu.register_file.regs[7],
                 $signed(dut.cpu.register_file.regs[7]));

        // ========================================================
        // CURRENT CPU DATA BUS
        // ========================================================

        $display("");
        $display("================================================");
        $display("DEBUG: CURRENT CPU DATA BUS");
        $display("================================================");

        $display("dmem_read       = %b", dut.cpu_dmem_read);
        $display("dmem_write      = %b", dut.cpu_dmem_write);
        $display("dmem_addr       = 0x%08h", dut.cpu_dmem_addr);
        $display("dmem_write_data = 0x%08h", dut.cpu_dmem_write_data);

        // ========================================================
        // ACCELERATOR INTERNAL STATE
        // ========================================================

        $display("");
        $display("================================================");
        $display("DEBUG: ACCELERATOR INTERNAL STATE");
        $display("================================================");

        // --------------------------------------------------------
        // A BUFFER
        // --------------------------------------------------------

        $display("");
        $display("A BUFFER:");

        $display("A[0] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.a_buffer[0][0]),
                 $signed(dut.accelerator.a_buffer[0][1]),
                 $signed(dut.accelerator.a_buffer[0][2]),
                 $signed(dut.accelerator.a_buffer[0][3]));

        $display("A[1] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.a_buffer[1][0]),
                 $signed(dut.accelerator.a_buffer[1][1]),
                 $signed(dut.accelerator.a_buffer[1][2]),
                 $signed(dut.accelerator.a_buffer[1][3]));

        $display("A[2] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.a_buffer[2][0]),
                 $signed(dut.accelerator.a_buffer[2][1]),
                 $signed(dut.accelerator.a_buffer[2][2]),
                 $signed(dut.accelerator.a_buffer[2][3]));

        $display("A[3] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.a_buffer[3][0]),
                 $signed(dut.accelerator.a_buffer[3][1]),
                 $signed(dut.accelerator.a_buffer[3][2]),
                 $signed(dut.accelerator.a_buffer[3][3]));

        // --------------------------------------------------------
        // B BUFFER
        // --------------------------------------------------------

        $display("");
        $display("B BUFFER:");

        $display("B[0] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.b_buffer[0][0]),
                 $signed(dut.accelerator.b_buffer[0][1]),
                 $signed(dut.accelerator.b_buffer[0][2]),
                 $signed(dut.accelerator.b_buffer[0][3]));

        $display("B[1] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.b_buffer[1][0]),
                 $signed(dut.accelerator.b_buffer[1][1]),
                 $signed(dut.accelerator.b_buffer[1][2]),
                 $signed(dut.accelerator.b_buffer[1][3]));

        $display("B[2] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.b_buffer[2][0]),
                 $signed(dut.accelerator.b_buffer[2][1]),
                 $signed(dut.accelerator.b_buffer[2][2]),
                 $signed(dut.accelerator.b_buffer[2][3]));

        $display("B[3] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.b_buffer[3][0]),
                 $signed(dut.accelerator.b_buffer[3][1]),
                 $signed(dut.accelerator.b_buffer[3][2]),
                 $signed(dut.accelerator.b_buffer[3][3]));

        // --------------------------------------------------------
        // A MATRIX
        // --------------------------------------------------------

        $display("");
        $display("A MATRIX:");

        $display("A[0] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.a_matrix[0][0]),
                 $signed(dut.accelerator.a_matrix[0][1]),
                 $signed(dut.accelerator.a_matrix[0][2]),
                 $signed(dut.accelerator.a_matrix[0][3]));

        $display("A[1] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.a_matrix[1][0]),
                 $signed(dut.accelerator.a_matrix[1][1]),
                 $signed(dut.accelerator.a_matrix[1][2]),
                 $signed(dut.accelerator.a_matrix[1][3]));

        $display("A[2] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.a_matrix[2][0]),
                 $signed(dut.accelerator.a_matrix[2][1]),
                 $signed(dut.accelerator.a_matrix[2][2]),
                 $signed(dut.accelerator.a_matrix[2][3]));

        $display("A[3] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.a_matrix[3][0]),
                 $signed(dut.accelerator.a_matrix[3][1]),
                 $signed(dut.accelerator.a_matrix[3][2]),
                 $signed(dut.accelerator.a_matrix[3][3]));

        // --------------------------------------------------------
        // B MATRIX
        // --------------------------------------------------------

        $display("");
        $display("B MATRIX:");

        $display("B[0] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.b_matrix[0][0]),
                 $signed(dut.accelerator.b_matrix[0][1]),
                 $signed(dut.accelerator.b_matrix[0][2]),
                 $signed(dut.accelerator.b_matrix[0][3]));

        $display("B[1] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.b_matrix[1][0]),
                 $signed(dut.accelerator.b_matrix[1][1]),
                 $signed(dut.accelerator.b_matrix[1][2]),
                 $signed(dut.accelerator.b_matrix[1][3]));

        $display("B[2] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.b_matrix[2][0]),
                 $signed(dut.accelerator.b_matrix[2][1]),
                 $signed(dut.accelerator.b_matrix[2][2]),
                 $signed(dut.accelerator.b_matrix[2][3]));

        $display("B[3] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.b_matrix[3][0]),
                 $signed(dut.accelerator.b_matrix[3][1]),
                 $signed(dut.accelerator.b_matrix[3][2]),
                 $signed(dut.accelerator.b_matrix[3][3]));

        // --------------------------------------------------------
        // C MATRIX
        // --------------------------------------------------------

        $display("");
        $display("C MATRIX:");

        $display("C[0] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.c_matrix[0][0]),
                 $signed(dut.accelerator.c_matrix[0][1]),
                 $signed(dut.accelerator.c_matrix[0][2]),
                 $signed(dut.accelerator.c_matrix[0][3]));

        $display("C[1] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.c_matrix[1][0]),
                 $signed(dut.accelerator.c_matrix[1][1]),
                 $signed(dut.accelerator.c_matrix[1][2]),
                 $signed(dut.accelerator.c_matrix[1][3]));

        $display("C[2] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.c_matrix[2][0]),
                 $signed(dut.accelerator.c_matrix[2][1]),
                 $signed(dut.accelerator.c_matrix[2][2]),
                 $signed(dut.accelerator.c_matrix[2][3]));

        $display("C[3] = %0d  %0d  %0d  %0d",
                 $signed(dut.accelerator.c_matrix[3][0]),
                 $signed(dut.accelerator.c_matrix[3][1]),
                 $signed(dut.accelerator.c_matrix[3][2]),
                 $signed(dut.accelerator.c_matrix[3][3]));

        // ========================================================
        // RAM RESULT AREA
        // ========================================================

        $display("");
        $display("RAM RESULT AREA:");

        for (i = 0; i < 16; i = i + 1) begin

            $display(
                "RAM[%0d] = %0d",
                128 + i,
                $signed(dut.ram.mem[128 + i])
            );

        end

        $display("");
        $display("================================================");
        $display("");

        // ========================================================
        // VERIFY EXPECTED MATRIX
        // ========================================================

        if ($signed(dut.ram.mem[128]) !== 32'sd4) begin
            $display(
                "ERROR: C[0][0] expected 4, got %0d",
                $signed(dut.ram.mem[128])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[129]) !== 32'sd8) begin
            $display(
                "ERROR: C[0][1] expected 8, got %0d",
                $signed(dut.ram.mem[129])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[130]) !== 32'sd13) begin
            $display(
                "ERROR: C[0][2] expected 13, got %0d",
                $signed(dut.ram.mem[130])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[131]) !== 32'sd11) begin
            $display(
                "ERROR: C[0][3] expected 11, got %0d",
                $signed(dut.ram.mem[131])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[132]) !== 32'sd12) begin
            $display(
                "ERROR: C[1][0] expected 12, got %0d",
                $signed(dut.ram.mem[132])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[133]) !== 32'sd24) begin
            $display(
                "ERROR: C[1][1] expected 24, got %0d",
                $signed(dut.ram.mem[133])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[134]) !== 32'sd29) begin
            $display(
                "ERROR: C[1][2] expected 29, got %0d",
                $signed(dut.ram.mem[134])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[135]) !== 32'sd27) begin
            $display(
                "ERROR: C[1][3] expected 27, got %0d",
                $signed(dut.ram.mem[135])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[136]) !== -32'sd4) begin
            $display(
                "ERROR: C[2][0] expected -4, got %0d",
                $signed(dut.ram.mem[136])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[137]) !== 32'sd4) begin
            $display(
                "ERROR: C[2][1] expected 4, got %0d",
                $signed(dut.ram.mem[137])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[138]) !== 32'sd7) begin
            $display(
                "ERROR: C[2][2] expected 7, got %0d",
                $signed(dut.ram.mem[138])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[139]) !== -32'sd3) begin
            $display(
                "ERROR: C[2][3] expected -3, got %0d",
                $signed(dut.ram.mem[139])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[140]) !== 32'sd2) begin
            $display(
                "ERROR: C[3][0] expected 2, got %0d",
                $signed(dut.ram.mem[140])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[141]) !== -32'sd24) begin
            $display(
                "ERROR: C[3][1] expected -24, got %0d",
                $signed(dut.ram.mem[141])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[142]) !== -32'sd15) begin
            $display(
                "ERROR: C[3][2] expected -15, got %0d",
                $signed(dut.ram.mem[142])
            );
            $finish;
        end

        if ($signed(dut.ram.mem[143]) !== 32'sd1) begin
            $display(
                "ERROR: C[3][3] expected 1, got %0d",
                $signed(dut.ram.mem[143])
            );
            $finish;
        end

        $display("PASS: 4x4 matrix result correctly transferred to RAM");

        // --------------------------------------------------------
        // End simulation
        // --------------------------------------------------------

        $finish;

    end

    // ------------------------------------------------------------
    // VCD
    // ------------------------------------------------------------

    initial begin
        $dumpfile("waveforms/riscv_ai_soc_tb.vcd");
        $dumpvars(0, riscv_ai_soc_tb);
    end

endmodule