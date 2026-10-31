`timescale 1ns/1ps

module regfile_tb;

    logic        clk;
    logic        rst;

    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;

    logic [31:0] rd_data;
    logic        rd_we;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    regfile dut (
        .clk(clk),
        .rst(rst),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rd_we(rd_we),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveforms/regfile_tb.vcd");
        $dumpvars(0, regfile_tb);

        clk = 0;
        rst = 1;
        rs1_addr = 0;
        rs2_addr = 0;
        rd_addr = 0;
        rd_data = 0;
        rd_we = 0;

        #12;
        rst = 0;

        // Write 123 to x5
        @(negedge clk);
        rd_addr = 5;
        rd_data = 32'd123;
        rd_we = 1;

        @(negedge clk);
        rd_we = 0;

        // Read x5
        rs1_addr = 5;
        #2;

        if (rs1_data !== 32'd123) begin
            $display("ERROR: x5 expected 123, got %0d", rs1_data);
            $finish;
        end

        // x0 must always remain zero
        rs1_addr = 0;
        #2;

        if (rs1_data !== 32'd0) begin
            $display("ERROR: x0 is not zero");
            $finish;
        end

        // Attempt to write x0
        @(negedge clk);
        rd_addr = 0;
        rd_data = 32'hFFFFFFFF;
        rd_we = 1;

        @(negedge clk);
        rd_we = 0;

        rs1_addr = 0;
        #2;

        if (rs1_data !== 32'd0) begin
            $display("ERROR: x0 was modified");
            $finish;
        end

        $display("================================");
        $display("REGISTER FILE TEST PASSED");
        $display("================================");

        $finish;
    end

endmodule
