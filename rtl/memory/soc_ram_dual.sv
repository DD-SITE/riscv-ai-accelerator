module soc_ram_dual #(
    parameter integer DEPTH = 1024
) (
    input  logic        clk,
    input  logic        rst,

    // Instruction read port
    input  logic [11:0] instr_addr,
    output logic [31:0] instr_rdata,

    // Data port
    input  logic        data_valid,
    input  logic        data_write,
    input  logic [11:0] data_addr,
    input  logic [31:0] data_wdata,
    output logic [31:0] data_rdata
);

    logic [31:0] mem [0:DEPTH-1];

    integer i;

    // ------------------------------------------------------------
    // Reset and data writes
    // ------------------------------------------------------------

    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= 32'b0;
        end
        else if (data_valid && data_write) begin
            mem[data_addr[11:2]] <= data_wdata;
        end
    end

    // ------------------------------------------------------------
    // Combinational instruction read
    // ------------------------------------------------------------

    always_comb begin
        instr_rdata = mem[instr_addr[11:2]];
    end

    // ------------------------------------------------------------
    // Combinational data read
    // ------------------------------------------------------------

    always_comb begin
        data_rdata = mem[data_addr[11:2]];
    end

endmodule