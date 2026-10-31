`timescale 1ns/1ps

module cpu_x1_debug_tb;

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

    logic [31:0] mem [0:31];

    integer i;

    cpu dut (
        .clk              (clk),
        .rst              (rst),
        .imem_addr        (imem_addr),
        .imem_instruction (imem_instruction),
        .dmem_read        (dmem_read),
        .dmem_write       (dmem_write),
        .dmem_addr        (dmem_addr),
        .dmem_write_data  (dmem_write_data),
        .dmem_read_data   (dmem_read_data),
        .debug_pc         (debug_pc)
    );

    always #5 clk = ~clk;

    always_comb begin
        imem_instruction = mem[imem_addr[6:2]];
    end

    assign dmem_read_data = 32'b0;

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
        input integer imm
    );
        enc_addi = {
            imm[11:0],
            rs1[4:0],
            3'b000,
            rd[4:0],
            7'b0010011
        };
    endfunction

    initial begin

        clk = 1'b0;
        rst = 1'b1;

        for (i = 0; i < 32; i = i + 1)
            mem[i] = 32'b0;

        // LUI x1, 0x1
        mem[0] = enc_lui(1, 20'h00001);

        // ADDI x1, x1, 8
        mem[1] = enc_addi(1, 1, 8);

        // LUI x2, 0x1
        mem[2] = enc_lui(2, 20'h00001);

        // ADDI x2, x2, 12
        mem[3] = enc_addi(2, 2, 12);

        // LUI x3, 0x1
        mem[4] = enc_lui(3, 20'h00001);

        // Infinite loop
        mem[5] = 32'h00000063;

        repeat (3) @(posedge clk);

        rst = 1'b0;

        #1;

        $display("");
        $display("==============================================");
        $display("CPU X1 INITIALIZATION DEBUG");
        $display("==============================================");

        repeat (8) begin

            @(posedge clk);

            #1;

            $display("");
            $display("PC                = 0x%08h", dut.debug_pc);
            $display("Instruction       = 0x%08h", imem_instruction);

            $display("rs1_addr          = %0d", dut.rs1_addr);
            $display("rs1_data          = 0x%08h", dut.rs1_data);

            $display("rs2_addr          = %0d", dut.rs2_addr);
            $display("rs2_data          = 0x%08h", dut.rs2_data);

            $display("rd_addr           = %0d", dut.rd_addr);
            $display("imm               = 0x%08h", dut.imm);

            $display("reg_write         = %b", dut.reg_write);
            $display("alu_src           = %b", dut.alu_src);

            $display("alu_b             = 0x%08h", dut.alu_b);
            $display("alu_result        = 0x%08h", dut.alu_result);

            $display("writeback_data    = 0x%08h", dut.writeback_data);

            $display("REGISTER x1       = 0x%08h",
                     dut.register_file.regs[1]);

            $display("REGISTER x2       = 0x%08h",
                     dut.register_file.regs[2]);

            $display("REGISTER x3       = 0x%08h",
                     dut.register_file.regs[3]);
        end

        $display("");
        $display("==============================================");
        $display("EXPECTED");
        $display("==============================================");
        $display("x1 = 0x00001008");
        $display("x2 = 0x0000100C");
        $display("x3 = 0x00001000");
        $display("==============================================");

        $finish;
    end

endmodule
