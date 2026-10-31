`timescale 1ns/1ps

module alu_tb;

    logic [31:0] a;
    logic [31:0] b;
    logic [3:0]  alu_op;

    logic [31:0] result;
    logic        zero;

    alu dut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result),
        .zero(zero)
    );

    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;
    localparam ALU_SLTU = 4'b1001;

    task check_result(
        input logic [31:0] expected,
        input string operation
    );
        begin
            #1;

            if (result !== expected) begin
                $display(
                    "ERROR: %s | expected %h, got %h",
                    operation,
                    expected,
                    result
                );
                $finish;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/alu_tb.vcd");
        $dumpvars(0, alu_tb);

        // ADD
        a = 32'd10;
        b = 32'd20;
        alu_op = ALU_ADD;
        check_result(32'd30, "ADD");

        // SUB
        a = 32'd30;
        b = 32'd10;
        alu_op = ALU_SUB;
        check_result(32'd20, "SUB");

        // AND
        a = 32'hF0F0F0F0;
        b = 32'h0FF00FF0;
        alu_op = ALU_AND;
        check_result(32'h00F000F0, "AND");

        // OR
        a = 32'hF0000000;
        b = 32'h0000000F;
        alu_op = ALU_OR;
        check_result(32'hF000000F, "OR");

        // XOR
        a = 32'hAAAAAAAA;
        b = 32'hFFFFFFFF;
        alu_op = ALU_XOR;
        check_result(32'h55555555, "XOR");

        // SLL
        a = 32'd1;
        b = 32'd4;
        alu_op = ALU_SLL;
        check_result(32'd16, "SLL");

        // SRL
        a = 32'd32;
        b = 32'd3;
        alu_op = ALU_SRL;
        check_result(32'd4, "SRL");

        // SRA
        a = 32'h80000000;
        b = 32'd4;
        alu_op = ALU_SRA;
        check_result(32'hF8000000, "SRA");

        // Signed SLT
        a = 32'hFFFFFFFF;  // -1
        b = 32'd1;
        alu_op = ALU_SLT;
        check_result(32'd1, "SLT");

        // Unsigned SLTU
        a = 32'hFFFFFFFF;
        b = 32'd1;
        alu_op = ALU_SLTU;
        check_result(32'd0, "SLTU");

        // Zero flag
        a = 32'd10;
        b = 32'd10;
        alu_op = ALU_SUB;
        #1;

        if (zero !== 1'b1) begin
            $display("ERROR: zero flag should be 1");
            $finish;
        end

        $display("================================");
        $display("ALU TEST PASSED");
        $display("================================");

        $finish;
    end

endmodule
