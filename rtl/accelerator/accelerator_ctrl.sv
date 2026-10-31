module accelerator_ctrl (
    input  logic               clk,
    input  logic               rst,

    input  logic               bus_valid,
    input  logic               bus_write,
    input  logic [4:0]         bus_addr,
    input  logic [31:0]        bus_wdata,

    output logic [31:0]        bus_rdata,

    output logic               busy,
    output logic               done
);

    localparam logic [4:0] ADDR_CONTROL = 5'h00;
    localparam logic [4:0] ADDR_STATUS  = 5'h04;
    localparam logic [4:0] ADDR_A_DATA  = 5'h08;
    localparam logic [4:0] ADDR_B_DATA  = 5'h0C;
    localparam logic [4:0] ADDR_C_DATA  = 5'h10;

    logic signed [7:0]  a_buffer [4][4];
    logic signed [7:0]  b_buffer [4][4];

    logic               matmul_start;
    logic               matmul_busy;
    logic               matmul_done;

    logic signed [7:0]  a_matrix [4][4];
    logic signed [7:0]  b_matrix [4][4];
    logic signed [31:0] c_matrix [4][4];

    logic [4:0] a_index;
    logic [4:0] b_index;
    logic [4:0] c_index;

    /*
     * External accelerator state.
     *
     * busy_latched stays asserted for the entire accelerator
     * transaction. It is cleared only after matmul_done has been
     * observed. This prevents the CPU from leaving the polling
     * loop during the matrix engine's final transition.
     */
    logic busy_latched;
    logic done_latched;

    assign busy = busy_latched;
    assign done = done_latched;

    /*
     * Convert the software-visible byte streams into the
     * 4x4 matrices consumed by the matrix engine.
     */
    always_comb begin
        for (integer i = 0; i < 4; i = i + 1) begin
            for (integer j = 0; j < 4; j = j + 1) begin
                a_matrix[i][j] = a_buffer[i][j];
                b_matrix[i][j] = b_buffer[i][j];
            end
        end
    end

    /*
     * Matrix multiplication engine.
     */
    matmul_engine matmul (
        .clk   (clk),
        .rst   (rst),
        .start (matmul_start),
        .a     (a_matrix),
        .b     (b_matrix),
        .c     (c_matrix),
        .busy  (matmul_busy),
        .done  (matmul_done)
    );

    /*
     * ------------------------------------------------------------
     * SOFTWARE READ INTERFACE
     * ------------------------------------------------------------
     */

    always_comb begin
        bus_rdata = 32'b0;

        if (bus_valid && !bus_write) begin

            case (bus_addr)

                /*
                 * STATUS
                 *
                 * bit 0 = accelerator busy
                 * bit 1 = accelerator done
                 */
                ADDR_STATUS: begin
                    bus_rdata = 32'b0;
                    bus_rdata[0] = busy_latched;
                    bus_rdata[1] = done_latched;
                end

                /*
                 * C_DATA
                 *
                 * Sequential read port. The CPU performs:
                 *
                 *     LW x6, 0(x5)
                 *     SW x6, 0(x7)
                 *
                 * c_index advances once per C_DATA read.
                 */
                ADDR_C_DATA: begin

                    case (c_index)

                        5'd0:  bus_rdata = c_matrix[0][0];
                        5'd1:  bus_rdata = c_matrix[0][1];
                        5'd2:  bus_rdata = c_matrix[0][2];
                        5'd3:  bus_rdata = c_matrix[0][3];

                        5'd4:  bus_rdata = c_matrix[1][0];
                        5'd5:  bus_rdata = c_matrix[1][1];
                        5'd6:  bus_rdata = c_matrix[1][2];
                        5'd7:  bus_rdata = c_matrix[1][3];

                        5'd8:  bus_rdata = c_matrix[2][0];
                        5'd9:  bus_rdata = c_matrix[2][1];
                        5'd10: bus_rdata = c_matrix[2][2];
                        5'd11: bus_rdata = c_matrix[2][3];

                        5'd12: bus_rdata = c_matrix[3][0];
                        5'd13: bus_rdata = c_matrix[3][1];
                        5'd14: bus_rdata = c_matrix[3][2];
                        5'd15: bus_rdata = c_matrix[3][3];

                        default:
                            bus_rdata = 32'b0;

                    endcase

                end

                default:
                    bus_rdata = 32'b0;

            endcase

        end
    end

    /*
     * ------------------------------------------------------------
     * CONTROLLER
     * ------------------------------------------------------------
     */

    always_ff @(posedge clk) begin

        if (rst) begin

            a_index      <= 5'd0;
            b_index      <= 5'd0;
            c_index      <= 5'd0;

            matmul_start <= 1'b0;

            busy_latched <= 1'b0;
            done_latched <= 1'b0;

            for (integer i = 0; i < 4; i = i + 1) begin
                for (integer j = 0; j < 4; j = j + 1) begin
                    a_buffer[i][j] <= 8'sd0;
                    b_buffer[i][j] <= 8'sd0;
                end
            end

        end
        else begin

            /*
             * Default: start is a one-cycle pulse.
             */
            matmul_start <= 1'b0;

            /*
             * DONE is a software-visible sticky flag for the
             * current transaction. A new START clears it.
             */
            if (matmul_done) begin
                done_latched <= 1'b1;
                busy_latched <= 1'b0;
            end

            /*
             * ----------------------------------------------------
             * MMIO WRITES
             * ----------------------------------------------------
             */

            if (bus_valid && bus_write) begin

                case (bus_addr)

                    /*
                     * CONTROL
                     *
                     * bit 0 = START
                     */
                    ADDR_CONTROL: begin

                        if (bus_wdata[0] && !busy_latched) begin

                            matmul_start <= 1'b1;

                            busy_latched <= 1'b1;
                            done_latched <= 1'b0;

                            c_index <= 5'd0;

                        end

                    end

                    /*
                     * A_DATA
                     */
                    ADDR_A_DATA: begin

                        if (!busy_latched &&
                            (a_index < 5'd16)) begin

                            a_buffer[a_index[4:2]][a_index[1:0]]
                                <= $signed(bus_wdata[7:0]);

                            a_index <= a_index + 5'd1;

                        end

                    end

                    /*
                     * B_DATA
                     */
                    ADDR_B_DATA: begin

                        if (!busy_latched &&
                            (b_index < 5'd16)) begin

                            b_buffer[b_index[4:2]][b_index[1:0]]
                                <= $signed(bus_wdata[7:0]);

                            b_index <= b_index + 5'd1;

                        end

                    end

                    default: begin
                    end

                endcase

            end

            /*
             * ----------------------------------------------------
             * C_DATA READ INDEX
             * ----------------------------------------------------
             *
             * Only allow result reads after the accelerator has
             * completed.
             */
            if (bus_valid &&
                !bus_write &&
                (bus_addr == ADDR_C_DATA) &&
                !busy_latched) begin

                if (c_index < 5'd15)
                    c_index <= c_index + 5'd1;
                else
                    c_index <= 5'd16;

            end

        end

    end

endmodule
