module riscv_ai_soc (
    input logic clk,
    input logic rst,

    // Debug output
    output logic [31:0] debug_pc,

    // Accelerator status
    output logic accel_busy,
    output logic accel_done
);

    // ============================================================
    // CPU instruction interface
    // ============================================================

    logic [31:0] cpu_imem_addr;
    logic [31:0] cpu_imem_instruction;

    // ============================================================
    // CPU data interface
    // ============================================================

    logic        cpu_dmem_read;
    logic        cpu_dmem_write;
    logic [31:0] cpu_dmem_addr;
    logic [31:0] cpu_dmem_write_data;
    logic [31:0] cpu_dmem_read_data;

    // ============================================================
    // RAM interface
    // ============================================================

    logic [31:0] ram_instr_rdata;

    logic        ram_data_valid;
    logic        ram_data_write;
    logic [11:0] ram_data_addr;
    logic [31:0] ram_data_wdata;
    logic [31:0] ram_data_rdata;

    // ============================================================
    // Accelerator interface
    // ============================================================

    logic        accel_valid;
    logic        accel_write;
    logic [4:0]  accel_addr;
    logic [31:0] accel_wdata;
    logic [31:0] accel_rdata;

    // ============================================================
    // Address map
    // ============================================================

    localparam logic [31:0] ACCEL_BASE = 32'h0000_1000;
    localparam logic [31:0] RAM_LIMIT  = 32'h0000_1000;

    logic data_access_ram;
    logic data_access_accel;

    // ============================================================
    // CPU
    // ============================================================

    cpu cpu (
        .clk(clk),
        .rst(rst),

        .imem_addr(cpu_imem_addr),
        .imem_instruction(cpu_imem_instruction),

        .dmem_read(cpu_dmem_read),
        .dmem_write(cpu_dmem_write),
        .dmem_addr(cpu_dmem_addr),
        .dmem_write_data(cpu_dmem_write_data),
        .dmem_read_data(cpu_dmem_read_data),

        .debug_pc(debug_pc)
    );

    // ============================================================
    // Instruction memory
    //
    // Instruction fetches always come from RAM.
    // ============================================================

    assign cpu_imem_instruction = ram_instr_rdata;

    // ============================================================
    // Data address decoding
    // ============================================================

    always_comb begin

        data_access_ram =
            (cpu_dmem_addr < RAM_LIMIT);

        data_access_accel =
            (cpu_dmem_addr >= ACCEL_BASE) &&
            (cpu_dmem_addr < ACCEL_BASE + 32'h0000_0014);

    end

    // ============================================================
    // RAM data interface
    // ============================================================

    always_comb begin

        ram_data_valid = 1'b0;
        ram_data_write = 1'b0;
        ram_data_addr  = 12'b0;
        ram_data_wdata = 32'b0;

        if ((cpu_dmem_read || cpu_dmem_write) &&
            data_access_ram) begin

            ram_data_valid = 1'b1;
            ram_data_write = cpu_dmem_write;
            ram_data_addr  = cpu_dmem_addr[11:0];
            ram_data_wdata = cpu_dmem_write_data;

        end

    end

    // ============================================================
    // Accelerator interface
    // ============================================================

    always_comb begin

        accel_valid = 1'b0;
        accel_write = 1'b0;
        accel_addr  = 5'b0;
        accel_wdata = 32'b0;

        if ((cpu_dmem_read || cpu_dmem_write) &&
            data_access_accel) begin

            accel_valid = 1'b1;
            accel_write = cpu_dmem_write;
            accel_addr  = cpu_dmem_addr[4:0];
            accel_wdata = cpu_dmem_write_data;

        end

    end

    // ============================================================
    // Data readback mux
    // ============================================================

    always_comb begin

        cpu_dmem_read_data = 32'b0;

        if (cpu_dmem_read) begin

            if (data_access_ram)
                cpu_dmem_read_data = ram_data_rdata;

            else if (data_access_accel)
                cpu_dmem_read_data = accel_rdata;

        end

    end

    // ============================================================
    // Dual-port RAM
    // ============================================================

    soc_ram_dual #(
        .DEPTH(1024)
    ) ram (
        .clk(clk),
        .rst(rst),

        .instr_addr(cpu_imem_addr[11:0]),
        .instr_rdata(ram_instr_rdata),

        .data_valid(ram_data_valid),
        .data_write(ram_data_write),
        .data_addr(ram_data_addr),
        .data_wdata(ram_data_wdata),
        .data_rdata(ram_data_rdata)
    );

    // ============================================================
    // AI Accelerator
    // ============================================================

    accelerator_ctrl accelerator (
        .clk(clk),
        .rst(rst),

        .bus_valid(accel_valid),
        .bus_write(accel_write),
        .bus_addr(accel_addr),
        .bus_wdata(accel_wdata),

        .bus_rdata(accel_rdata),

        .busy(accel_busy),
        .done(accel_done)
    );

endmodule