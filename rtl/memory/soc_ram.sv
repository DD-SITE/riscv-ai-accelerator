module soc_ram #(
    parameter integer DEPTH = 1024
) (
    input  logic        clk,
    input  logic        rst,

    input  logic        valid,
    input  logic        write,
    input  logic [11:0] addr,
    input  logic [31:0] wdata,

    output logic [31:0] rdata
);

    logic [31:0] mem [0:DEPTH-1];

    integer i;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= 32'b0;
        end
        else if (valid && write) begin
            mem[addr[11:2]] <= wdata;
        end
    end

    always_comb begin
        rdata = mem[addr[11:2]];
    end

endmodule