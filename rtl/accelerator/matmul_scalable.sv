module scalable_mac_unit (
    input  logic        clk,
    input  logic        rst,
    input  logic        enable,
    input  logic        clear,
    input  logic [7:0]  a,
    input  logic [7:0]  b,
    output logic [31:0] acc
);

    logic signed [15:0] product;
    logic signed [31:0] acc_signed;

    assign product   = $signed(a) * $signed(b);
    assign acc_signed = $signed(acc);

    always_ff @(posedge clk) begin
        if (rst || clear)
            acc <= 32'b0;
        else if (enable)
            acc <= acc_signed + {{16{product[15]}}, product};
    end

endmodule


module matmul_scalable #(
    parameter integer NUM_PE = 4
) (
    input  logic clk,
    input  logic rst,
    input  logic start,

    input  logic [127:0] a_flat,
    input  logic [127:0] b_flat,

    output logic [511:0] c_flat,

    output logic busy,
    output logic done,

    output logic [31:0] cycle_count
);

    localparam integer MAX_PE = 8;

    typedef enum logic [1:0] {
        IDLE,
        CLEAR,
        COMPUTE,
        STORE
    } state_t;

    state_t state;

    logic [2:0] row;
    logic [2:0] col;
    logic [2:0] k;

    logic [MAX_PE*8-1:0]  pe_a_bus;
    logic [MAX_PE*8-1:0]  pe_b_bus;
    logic [MAX_PE*32-1:0] pe_result_bus;

    logic pe_enable;
    logic pe_clear;

    genvar i;

    /*
     * Generate exactly NUM_PE processing elements.
     *
     * The buses are fixed at 8 PEs wide so that Yosys does not
     * have to deal with parameter-dependent port widths.
     */
    generate
        for (i = 0; i < NUM_PE; i = i + 1) begin : PE_GEN

            scalable_mac_unit mac (
                .clk    (clk),
                .rst    (rst),
                .enable (pe_enable),
                .clear  (pe_clear),
                .a      (pe_a_bus[i*8 +: 8]),
                .b      (pe_b_bus[i*8 +: 8]),
                .acc    (pe_result_bus[i*32 +: 32])
            );

            /*
             * PE i computes:
             *
             * C[row][col+i] += A[row][k] * B[k][col+i]
             *
             * when that output column exists.
             */
            always_comb begin
                pe_a_bus[i*8 +: 8] = 8'b0;
                pe_b_bus[i*8 +: 8] = 8'b0;

                if (state == COMPUTE) begin
                    if ((col + i) < 4) begin
                        pe_a_bus[i*8 +: 8] =
                            a_flat[((row*4 + k)*8) +: 8];

                        pe_b_bus[i*8 +: 8] =
                            b_flat[((k*4 + col + i)*8) +: 8];
                    end
                end
            end

        end
    endgenerate


    /*
     * Control signals for all active PEs.
     */
    always_comb begin
        pe_enable = 1'b0;
        pe_clear  = 1'b0;

        if (state == CLEAR)
            pe_clear = 1'b1;

        if (state == COMPUTE)
            pe_enable = 1'b1;
    end


    assign busy = (state != IDLE);


    /*
     * Store results.
     *
     * NUM_PE is limited to 8 and the matrix has only four columns.
     * Explicit cases avoid synthesis problems with procedural
     * loop variables in older Yosys versions.
     */
    always_ff @(posedge clk) begin

        if (rst) begin
            state       <= IDLE;
            row         <= 3'd0;
            col         <= 3'd0;
            k           <= 3'd0;
            done        <= 1'b0;
            cycle_count <= 32'd0;
            c_flat      <= 512'b0;
        end

        else begin

            done <= 1'b0;

            case (state)

                IDLE: begin

                    cycle_count <= 32'd0;

                    if (start) begin
                        row   <= 3'd0;
                        col   <= 3'd0;
                        k     <= 3'd0;
                        state <= CLEAR;
                    end

                end


                CLEAR: begin

                    cycle_count <= cycle_count + 32'd1;
                    state <= COMPUTE;

                end


                COMPUTE: begin

                    cycle_count <= cycle_count + 32'd1;

                    if (k == 3)
                        state <= STORE;
                    else
                        k <= k + 3'd1;

                end


                STORE: begin

                    /*
                     * Store PE results for the current output columns.
                     */

                    if (NUM_PE >= 1) begin
                        if ((col + 0) < 4)
                            c_flat[((row*4 + col + 0)*32) +: 32]
                                <= pe_result_bus[0*32 +: 32];
                    end

                    if (NUM_PE >= 2) begin
                        if ((col + 1) < 4)
                            c_flat[((row*4 + col + 1)*32) +: 32]
                                <= pe_result_bus[1*32 +: 32];
                    end

                    if (NUM_PE >= 3) begin
                        if ((col + 2) < 4)
                            c_flat[((row*4 + col + 2)*32) +: 32]
                                <= pe_result_bus[2*32 +: 32];
                    end

                    if (NUM_PE >= 4) begin
                        if ((col + 3) < 4)
                            c_flat[((row*4 + col + 3)*32) +: 32]
                                <= pe_result_bus[3*32 +: 32];
                    end

                    if (NUM_PE >= 5) begin
                        if ((col + 4) < 4)
                            c_flat[((row*4 + col + 4)*32) +: 32]
                                <= pe_result_bus[4*32 +: 32];
                    end

                    if (NUM_PE >= 6) begin
                        if ((col + 5) < 4)
                            c_flat[((row*4 + col + 5)*32) +: 32]
                                <= pe_result_bus[5*32 +: 32];
                    end

                    if (NUM_PE >= 7) begin
                        if ((col + 6) < 4)
                            c_flat[((row*4 + col + 6)*32) +: 32]
                                <= pe_result_bus[6*32 +: 32];
                    end

                    if (NUM_PE >= 8) begin
                        if ((col + 7) < 4)
                            c_flat[((row*4 + col + 7)*32) +: 32]
                                <= pe_result_bus[7*32 +: 32];
                    end


                    /*
                     * Move to the next group of output columns.
                     *
                     * For this 4x4 workload:
                     *   1 PE -> col 0,1,2,3 separately
                     *   4 PE -> all four columns together
                     *   8 PE -> all four columns together
                     */

                    if ((col + NUM_PE) < 4) begin

                        col   <= col + NUM_PE;
                        k     <= 3'd0;
                        state <= CLEAR;

                    end

                    else if (row < 3) begin

                        row   <= row + 3'd1;
                        col   <= 3'd0;
                        k     <= 3'd0;
                        state <= CLEAR;

                    end

                    else begin

                        state <= IDLE;
                        done  <= 1'b1;

                    end

                end


                default: begin
                    state <= IDLE;
                end

            endcase

        end

    end

endmodule
