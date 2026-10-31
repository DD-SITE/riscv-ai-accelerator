module decoder (
    input  logic [31:0] instruction,

    output logic [4:0]  rs1_addr,
    output logic [4:0]  rs2_addr,
    output logic [4:0]  rd_addr,

    output logic [31:0] imm,

    output logic        reg_write,
    output logic        alu_src,
    output logic        mem_read,
    output logic        mem_write,
    output logic        mem_to_reg,
    output logic        branch,
    output logic        jump,

    output logic [3:0]  alu_op
);

    // Opcodes
    localparam OP_RTYPE  = 7'b0110011;
    localparam OP_ITYPE  = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;

    // ALU operations
    localparam ALU_ADD   = 4'b0000;
    localparam ALU_SUB   = 4'b0001;
    localparam ALU_AND   = 4'b0010;
    localparam ALU_OR    = 4'b0011;
    localparam ALU_XOR   = 4'b0100;
    localparam ALU_SLL   = 4'b0101;
    localparam ALU_SRL   = 4'b0110;
    localparam ALU_SRA   = 4'b0111;
    localparam ALU_SLT   = 4'b1000;
    localparam ALU_SLTU  = 4'b1001;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instruction[6:0];
    assign rd_addr = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign funct7 = instruction[31:25];

    always_comb begin

        // Safe defaults
        imm        = 32'b0;

        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;

        alu_op     = ALU_ADD;

        case (opcode)

            // ----------------------------------------
            // R-type
            // ----------------------------------------
            OP_RTYPE: begin

                reg_write = 1'b1;

                case (funct3)

                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            alu_op = ALU_SUB;
                        else
                            alu_op = ALU_ADD;
                    end

                    3'b111: alu_op = ALU_AND;
                    3'b110: alu_op = ALU_OR;
                    3'b100: alu_op = ALU_XOR;
                    3'b001: alu_op = ALU_SLL;
                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_op = ALU_SRA;
                        else
                            alu_op = ALU_SRL;
                    end

                    3'b010: alu_op = ALU_SLT;
                    3'b011: alu_op = ALU_SLTU;

                    default: alu_op = ALU_ADD;

                endcase
            end

            // ----------------------------------------
            // I-type ALU
            // ----------------------------------------
            OP_ITYPE: begin

                reg_write = 1'b1;
                alu_src   = 1'b1;

                imm = {{20{instruction[31]}}, instruction[31:20]};

                case (funct3)

                    3'b000: alu_op = ALU_ADD;   // ADDI
                    3'b111: alu_op = ALU_AND;   // ANDI
                    3'b110: alu_op = ALU_OR;    // ORI
                    3'b100: alu_op = ALU_XOR;   // XORI
                    3'b010: alu_op = ALU_SLT;   // SLTI
                    3'b011: alu_op = ALU_SLTU;  // SLTIU

                    3'b001: alu_op = ALU_SLL;   // SLLI

                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_op = ALU_SRA;   // SRAI
                        else
                            alu_op = ALU_SRL;   // SRLI
                    end

                    default: alu_op = ALU_ADD;

                endcase
            end

            // ----------------------------------------
            // Load
            // ----------------------------------------
            OP_LOAD: begin

                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;

                alu_op = ALU_ADD;

                imm = {{20{instruction[31]}}, instruction[31:20]};
            end

            // ----------------------------------------
            // Store
            // ----------------------------------------
            OP_STORE: begin

                alu_src   = 1'b1;
                mem_write = 1'b1;

                alu_op = ALU_ADD;

                imm = {{20{instruction[31]}},
                       instruction[31:25],
                       instruction[11:7]};
            end

            // ----------------------------------------
            // Branch
            // ----------------------------------------
            OP_BRANCH: begin

                branch = 1'b1;

                imm = {{19{instruction[31]}},
                       instruction[31],
                       instruction[7],
                       instruction[30:25],
                       instruction[11:8],
                       1'b0};

                case (funct3)

                    3'b000: alu_op = ALU_SUB; // BEQ
                    3'b001: alu_op = ALU_SUB; // BNE
                    3'b100: alu_op = ALU_SLT; // BLT
                    3'b101: alu_op = ALU_SLT; // BGE

                    default: alu_op = ALU_SUB;

                endcase
            end

            // ----------------------------------------
            // JAL
            // ----------------------------------------
            OP_JAL: begin

                reg_write = 1'b1;
                jump      = 1'b1;

                imm = {{11{instruction[31]}},
                       instruction[31],
                       instruction[19:12],
                       instruction[20],
                       instruction[30:21],
                       1'b0};
            end

            // ----------------------------------------
            // JALR
            // ----------------------------------------
            OP_JALR: begin

                reg_write = 1'b1;
                jump      = 1'b1;
                alu_src   = 1'b1;

                imm = {{20{instruction[31]}},
                       instruction[31:20]};
            end

            // ----------------------------------------
            // LUI
            // ----------------------------------------
            OP_LUI: begin

                reg_write = 1'b1;
                alu_src   = 1'b1;

                imm = {instruction[31:12], 12'b0};

                alu_op = ALU_ADD;
            end

            // ----------------------------------------
            // AUIPC
            // ----------------------------------------
            OP_AUIPC: begin

                reg_write = 1'b1;
                alu_src   = 1'b1;

                imm = {instruction[31:12], 12'b0};

                alu_op = ALU_ADD;
            end

            default: begin
                // Keep safe defaults
            end

        endcase
    end

endmodule