/* verilator lint_off DECLFILENAME */

module scalable_mac_unit_8x8 (
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

    assign product    = $signed(a) * $signed(b);
    assign acc_signed = $signed(acc);

    always_ff @(posedge clk) begin
        if (rst || clear) begin
            acc <= 32'b0;
        end
        else if (enable) begin
            acc <= acc_signed + {{16{product[15]}}, product};
        end
    end

endmodule


module matmul_scalable_8x8 #(
    parameter integer NUM_PE = 1
) (
    input  logic clk,
    input  logic rst,

    input  logic start,

    input  logic [511:0]  a_flat,
    input  logic [511:0]  b_flat,

    output logic [2047:0] c_flat,

    output logic busy,
    output logic done
);

    typedef enum logic [1:0] {
        IDLE,
        CLEAR,
        COMPUTE,
        STORE
    } state_t;

    state_t state;

    logic [2:0] row;
    logic [2:0] k;
    logic [3:0] col_base;

    /*
     * PE datapath buses.
     *
     * NUM_PE = 1 -> 32-bit result bus
     * NUM_PE = 4 -> 128-bit result bus
     * NUM_PE = 8 -> 256-bit result bus
     */
    logic [NUM_PE*8-1:0]  pe_a_bus;
    logic [NUM_PE*8-1:0]  pe_b_bus;
    logic [NUM_PE*32-1:0] pe_result_bus;

    /*
     * Explicit 32-bit address arithmetic.
     */
    logic [31:0] row_index;
    logic [31:0] k_index;
    logic [31:0] col_index;

    integer store_index;

    /*
     * Convert the 32-bit integer parameter into an explicitly
     * sized constant only when arithmetic requires it.
     */
    localparam logic [31:0] NUM_PE_U32 = NUM_PE;

    assign row_index = {29'b0, row};
    assign k_index   = {29'b0, k};
    assign col_index = {28'b0, col_base};

    assign busy = (state != IDLE);


    /*
     * Generate exactly NUM_PE processing elements.
     */
    generate

        for (genvar g = 0; g < NUM_PE; g = g + 1) begin : PE_GEN

            localparam integer PE_INDEX = g;

            always_comb begin

                pe_a_bus[g*8 +: 8] = 8'b0;
                pe_b_bus[g*8 +: 8] = 8'b0;

                if (state == COMPUTE) begin

                    if ((col_index + PE_INDEX) < 32'd8) begin

                        pe_a_bus[g*8 +: 8] =
                            a_flat[
                                ((row_index * 32'd8 +
                                  k_index) * 32'd8) +: 8
                            ];

                        pe_b_bus[g*8 +: 8] =
                            b_flat[
                                ((k_index * 32'd8 +
                                  col_index +
                                  PE_INDEX) * 32'd8) +: 8
                            ];

                    end

                end

            end


            scalable_mac_unit_8x8 mac (
                .clk    (clk),
                .rst    (rst),
                .enable (state == COMPUTE),
                .clear  (state == CLEAR),
                .a      (pe_a_bus[g*8 +: 8]),
                .b      (pe_b_bus[g*8 +: 8]),
                .acc    (pe_result_bus[g*32 +: 32])
            );

        end

    endgenerate


    /*
     * Main control FSM.
     *
     * c_flat is intentionally written from only this one
     * sequential process.
     */
    always_ff @(posedge clk) begin

        if (rst) begin

            state    <= IDLE;
            row      <= 3'd0;
            k        <= 3'd0;
            col_base <= 4'd0;
            c_flat   <= 2048'b0;
            done     <= 1'b0;

        end
        else begin

            done <= 1'b0;

            case (state)

                IDLE: begin

                    if (start) begin

                        row      <= 3'd0;
                        k        <= 3'd0;
                        col_base <= 4'd0;

                        state <= CLEAR;

                    end

                end


                CLEAR: begin

                    k <= 3'd0;

                    state <= COMPUTE;

                end


                COMPUTE: begin

                    if (k == 3'd7) begin

                        k <= 3'd0;

                        state <= STORE;

                    end
                    else begin

                        k <= k + 3'd1;

                    end

                end


                STORE: begin

                    /*
                     * Store one output value per active PE.
                     */
                    for (
                        store_index = 0;
                        store_index < NUM_PE;
                        store_index = store_index + 1
                    ) begin

                        c_flat[
                            (
                                (
                                    row_index * 32'd8 +
                                    col_index +
                                    store_index
                                ) * 32
                            ) +: 32
                        ] <= pe_result_bus[
                            store_index*32 +: 32
                        ];

                    end


                    /*
                     * Move to the next group of columns or
                     * advance to the next matrix row.
                     */
                    if ((col_index + NUM_PE_U32) >= 32'd8) begin

                        col_base <= 4'd0;

                        if (row == 3'd7) begin

                            row   <= 3'd0;
                            done  <= 1'b1;
                            state <= IDLE;

                        end
                        else begin

                            row <= row + 3'd1;

                            state <= CLEAR;

                        end

                    end
                    else begin

                        col_base <= col_base +
                                    NUM_PE[3:0];

                        state <= CLEAR;

                    end

                end


                default: begin

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule

/* verilator lint_on DECLFILENAME */
