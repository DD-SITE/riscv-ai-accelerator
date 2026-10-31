`timescale 1ns/1ps

module decoder_tb;

    logic [31:0] instruction;

    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [4:0] rd_addr;

    logic [31:0] imm;

    logic reg_write;
    logic alu_src;
    logic mem_read;
    logic mem_write;
    logic mem_to_reg;
    logic branch;
    logic jump;

    logic [3:0] alu_op;

    decoder dut (
        .instruction(instruction),

        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),

        .imm(imm),

        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),

        .alu_op(alu_op)
    );

    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;

    initial begin

        $dumpfile("waveforms/decoder_tb.vcd");
        $dumpvars(0, decoder_tb);

        // ----------------------------------------
        // ADD x5, x6, x7
        // ----------------------------------------
        instruction = 32'h007302B3;
        #1;

        if (rs1_addr !== 5'd6) begin
            $display("ERROR: ADD rs1");
            $finish;
        end

        if (rs2_addr !== 5'd7) begin
            $display("ERROR: ADD rs2");
            $finish;
        end

        if (rd_addr !== 5'd5) begin
            $display("ERROR: ADD rd");
            $finish;
        end

        if (!reg_write) begin
            $display("ERROR: ADD reg_write");
            $finish;
        end

        if (alu_op !== ALU_ADD) begin
            $display("ERROR: ADD ALU operation");
            $finish;
        end

        // ----------------------------------------
        // SUB x5, x6, x7
        // ----------------------------------------
        instruction = 32'h407302B3;
        #1;

        if (alu_op !== ALU_SUB) begin
            $display("ERROR: SUB ALU operation");
            $finish;
        end

        // ----------------------------------------
        // ADDI x5, x6, 10
        // ----------------------------------------
        instruction = 32'h00A30293;
        #1;

        if (!reg_write) begin
            $display("ERROR: ADDI reg_write");
            $finish;
        end

        if (!alu_src) begin
            $display("ERROR: ADDI alu_src");
            $finish;
        end

        if (imm !== 32'd10) begin
            $display(
                "ERROR: ADDI immediate expected 10, got %0d",
                imm
            );
            $finish;
        end

        // ----------------------------------------
        // LW x5, 16(x6)
        // ----------------------------------------
        instruction = 32'h01032283;
        #1;

        if (!reg_write || !mem_read || !mem_to_reg) begin
            $display("ERROR: LW control signals");
            $finish;
        end

        if (imm !== 32'd16) begin
            $display("ERROR: LW immediate");
            $finish;
        end

        // ----------------------------------------
        // SW x7, 16(x6)
        // ----------------------------------------
        instruction = 32'h00732823;
        #1;

        if (reg_write) begin
            $display("ERROR: SW should not write register");
            $finish;
        end

        if (!mem_write) begin
            $display("ERROR: SW mem_write");
            $finish;
        end

        if (imm !== 32'd16) begin
            $display("ERROR: SW immediate");
            $finish;
        end

        // ----------------------------------------
        // BEQ x6, x7, offset
        // ----------------------------------------
        instruction = 32'h00730863;
        #1;

        if (!branch) begin
            $display("ERROR: BEQ branch signal");
            $finish;
        end

        // ----------------------------------------
        // LUI x5, 0x12345
        // ----------------------------------------
        instruction = 32'h123452B7;
        #1;

        if (!reg_write) begin
            $display("ERROR: LUI reg_write");
            $finish;
        end

        if (imm !== 32'h12345000) begin
            $display("ERROR: LUI immediate");
            $finish;
        end

        $display("================================");
        $display("DECODER TEST PASSED");
        $display("================================");

        $finish;

    end

endmodule