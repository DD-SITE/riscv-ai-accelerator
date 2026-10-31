module regfile (
    input  logic        clk,
    input  logic        rst,

    input  logic [4:0]  rs1_addr,
    input  logic [4:0]  rs2_addr,
    input  logic [4:0]  rd_addr,

    input  logic [31:0] rd_data,
    input  logic        rd_we,

    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    logic [31:0] regs [0:31];

    integer i;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end
        else if (rd_we && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= rd_data;
        end
    end

    always_comb begin
        if (rs1_addr == 5'd0)
            rs1_data = 32'b0;
        else
            rs1_data = regs[rs1_addr];

        if (rs2_addr == 5'd0)
            rs2_data = 32'b0;
        else
            rs2_data = regs[rs2_addr];
    end

endmodule

