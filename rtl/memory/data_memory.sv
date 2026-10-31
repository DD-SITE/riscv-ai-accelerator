module data_memory #(
    parameter DEPTH = 256
) (
    input  logic        clk,
    input  logic        mem_read,
    input  logic        mem_write,

    input  logic [31:0] addr,
    input  logic [31:0] write_data,

    output logic [31:0] read_data
);

    logic [31:0] mem [0:DEPTH-1];

    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;
    end

    always_ff @(posedge clk) begin
        if (mem_write)
            mem[addr[9:2]] <= write_data;
    end

    always_comb begin
        if (mem_read)
            read_data = mem[addr[9:2]];
        else
            read_data = 32'b0;
    end

endmodule