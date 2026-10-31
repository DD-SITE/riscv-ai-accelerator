module matmul_engine (
    input  logic               clk,
    input  logic               rst,

    input  logic               start,

    input  logic signed [7:0]  a [4][4],
    input  logic signed [7:0]  b [4][4],

    output logic signed [31:0] c [4][4],

    output logic               busy,
    output logic               done
);

    logic signed [7:0]  pe_a [4];
    logic signed [7:0]  pe_b [4];
    logic signed [31:0] pe_result [4];

    logic pe_enable;
    logic pe_clear;

    logic [1:0] k;
    logic [1:0] row;

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        CLEAR   = 2'b01,
        COMPUTE = 2'b10,
        STORE   = 2'b11
    } state_t;

    state_t state;

    // ------------------------------------------------------------
    // 4 parallel processing elements
    // ------------------------------------------------------------
    pe_array #(
        .NUM_PE(4)
    ) pe_array_inst (
        .clk    (clk),
        .rst    (rst),
        .enable (pe_enable),
        .clear  (pe_clear),
        .a      (pe_a),
        .b      (pe_b),
        .result (pe_result)
    );

    // ------------------------------------------------------------
    // Feed one row of A and one column of B to the PEs
    // ------------------------------------------------------------
    always_comb begin
        pe_a[0] = a[row][k];
        pe_a[1] = a[row][k];
        pe_a[2] = a[row][k];
        pe_a[3] = a[row][k];

        pe_b[0] = b[k][0];
        pe_b[1] = b[k][1];
        pe_b[2] = b[k][2];
        pe_b[3] = b[k][3];
    end

    // ------------------------------------------------------------
    // PE control
    // ------------------------------------------------------------
    always_comb begin
        pe_enable = 1'b0;
        pe_clear  = 1'b0;

        case (state)

            CLEAR: begin
                pe_clear = 1'b1;
            end

            COMPUTE: begin
                pe_enable = 1'b1;
            end

            default: begin
                pe_enable = 1'b0;
                pe_clear  = 1'b0;
            end

        endcase
    end

    // ------------------------------------------------------------
    // Busy indication
    // ------------------------------------------------------------
    always_comb begin
        busy = (state != IDLE);
    end

    // ------------------------------------------------------------
    // Main controller
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin

        if (rst) begin

            state <= IDLE;

            k   <= 2'd0;
            row <= 2'd0;

            done <= 1'b0;

            for (integer i = 0; i < 4; i = i + 1) begin
                for (integer j = 0; j < 4; j = j + 1) begin
                    c[i][j] <= 32'sd0;
                end
            end

        end
        else begin

            // done is a one-cycle pulse
            done <= 1'b0;

            case (state)

                // ------------------------------------------------
                // Wait for a new matrix multiplication
                // ------------------------------------------------
                IDLE: begin

                    if (start) begin
                        row   <= 2'd0;
                        k     <= 2'd0;
                        state <= CLEAR;
                    end

                end

                // ------------------------------------------------
                // Clear all PE accumulators
                // ------------------------------------------------
                CLEAR: begin

                    k <= 2'd0;

                    state <= COMPUTE;

                end

                // ------------------------------------------------
                // Perform one MAC operation for every PE
                // ------------------------------------------------
                COMPUTE: begin

                    if (k == 2'd3) begin
                        state <= STORE;
                    end
                    else begin
                        k <= k + 2'd1;
                    end

                end

                // ------------------------------------------------
                // Store the completed row
                // ------------------------------------------------
                STORE: begin

                    c[row][0] <= pe_result[0];
                    c[row][1] <= pe_result[1];
                    c[row][2] <= pe_result[2];
                    c[row][3] <= pe_result[3];

                    if (row == 2'd3) begin

                        // Entire 4x4 matrix is complete
                        done  <= 1'b1;
                        state <= IDLE;

                    end
                    else begin

                        row   <= row + 2'd1;
                        k     <= 2'd0;
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