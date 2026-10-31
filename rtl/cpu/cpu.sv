module cpu (
    input  logic        clk,
    input  logic        rst,

    // Instruction memory interface
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_instruction,

    // Data memory interface
    output logic        dmem_read,
    output logic        dmem_write,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_write_data,
    input  logic [31:0] dmem_read_data,

    // Debug
    output logic [31:0] debug_pc
);

    // ------------------------------------------------------------
    // Program Counter
    // ------------------------------------------------------------

    logic [31:0] pc;
    logic [31:0] next_pc;

    assign debug_pc = pc;
    assign imem_addr = pc;

    // ------------------------------------------------------------
    // Instruction
    // ------------------------------------------------------------

    logic [31:0] instruction;

    assign instruction = imem_instruction;

    // ------------------------------------------------------------
    // Decoder signals
    // ------------------------------------------------------------

    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [4:0] rd_addr;

    logic [31:0] imm;

    logic        reg_write;
    logic        alu_src;
    logic        mem_read;
    logic        mem_write;
    logic        mem_to_reg;
    logic        branch;
    logic        jump;

    logic [3:0]  alu_op;

    // ------------------------------------------------------------
    // Register File
    // ------------------------------------------------------------

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    logic [31:0] writeback_data;

    // ------------------------------------------------------------
    // ALU
    // ------------------------------------------------------------

    logic [31:0] alu_b;
    logic [31:0] alu_result;
    logic        alu_zero;

    // ------------------------------------------------------------
    // Decoder
    // ------------------------------------------------------------

    decoder decoder_unit (
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

    // ------------------------------------------------------------
    // Register File
    // ------------------------------------------------------------

    regfile register_file (
        .clk(clk),
        .rst(rst),

        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),

        .rd_data(writeback_data),
        .rd_we(reg_write),

        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // ------------------------------------------------------------
    // ALU input selection
    // ------------------------------------------------------------

    always_comb begin
        if (alu_src)
            alu_b = imm;
        else
            alu_b = rs2_data;
    end

    // ------------------------------------------------------------
    // ALU
    // ------------------------------------------------------------

    alu alu_unit (
        .a(rs1_data),
        .b(alu_b),
        .alu_op(alu_op),

        .result(alu_result),
        .zero(alu_zero)
    );

    // ------------------------------------------------------------
    // Data memory interface
    // ------------------------------------------------------------

    assign dmem_read       = mem_read;
    assign dmem_write      = mem_write;
    assign dmem_addr       = alu_result;
    assign dmem_write_data = rs2_data;

    // ------------------------------------------------------------
    // Writeback
    // ------------------------------------------------------------

    always_comb begin

        // Default ALU result
        writeback_data = alu_result;

        // Load
        if (mem_to_reg)
            writeback_data = dmem_read_data;

        // JAL / JALR: rd = PC + 4
        if (jump)
            writeback_data = pc + 32'd4;

        // LUI
        if (instruction[6:0] == 7'b0110111)
            writeback_data = imm;

        // AUIPC
        if (instruction[6:0] == 7'b0010111)
            writeback_data = pc + imm;

    end

    // ------------------------------------------------------------
    // Next PC
    // ------------------------------------------------------------

    always_comb begin

        // Default: next sequential instruction
        next_pc = pc + 32'd4;

        // Branch
        if (branch) begin

            case (instruction[14:12])

                // BEQ
                3'b000: begin
                    if (alu_zero)
                        next_pc = pc + imm;
                end

                // BNE
                3'b001: begin
                    if (!alu_zero)
                        next_pc = pc + imm;
                end

                // BLT
                3'b100: begin
                    if ($signed(rs1_data) < $signed(rs2_data))
                        next_pc = pc + imm;
                end

                // BGE
                3'b101: begin
                    if ($signed(rs1_data) >= $signed(rs2_data))
                        next_pc = pc + imm;
                end

                default: begin
                    next_pc = pc + 32'd4;
                end

            endcase
        end

        // Jumps
        if (jump) begin

            if (instruction[6:0] == 7'b1100111) begin
                // JALR
                next_pc = (rs1_data + imm) & 32'hFFFFFFFE;
            end
            else begin
                // JAL
                next_pc = pc + imm;
            end

        end

    end

    // ------------------------------------------------------------
    // Program Counter register
    // ------------------------------------------------------------

    always_ff @(posedge clk) begin
        if (rst)
            pc <= 32'b0;
        else
            pc <= next_pc;
    end

endmodule