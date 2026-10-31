module instruction_memory #(
    parameter DEPTH = 256
) (
    input  logic [31:0] addr,
    output logic [31:0] instruction
);

    logic [31:0] mem [0:DEPTH-1];

    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;
    end

    always_comb begin
        instruction = mem[addr[9:2]];
    end

endmodule