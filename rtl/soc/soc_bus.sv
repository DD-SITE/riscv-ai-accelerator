module soc_bus (
    input  logic        clk,
    input  logic        rst,

    // CPU instruction/data interface
    input  logic        cpu_mem_valid,
    input  logic        cpu_mem_write,
    input  logic [31:0] cpu_mem_addr,
    input  logic [31:0] cpu_mem_wdata,
    output logic [31:0] cpu_mem_rdata,

    // RAM interface
    output logic        ram_valid,
    output logic        ram_write,
    output logic [11:0] ram_addr,
    output logic [31:0] ram_wdata,
    input  logic [31:0] ram_rdata,

    // Accelerator bus interface
    output logic        accel_valid,
    output logic        accel_write,
    output logic [4:0]  accel_addr,
    output logic [31:0] accel_wdata,
    input  logic [31:0] accel_rdata
);

    // ------------------------------------------------------------
    // Memory map
    //
    // 0x0000 - 0x0FFF : RAM
    // 0x1000          : Accelerator CONTROL
    // 0x1004          : Accelerator STATUS
    // 0x1008          : Accelerator A_DATA
    // 0x100C          : Accelerator B_DATA
    // 0x1010          : Accelerator C_DATA
    // ------------------------------------------------------------

    localparam logic [31:0] ACCEL_BASE = 32'h0000_1000;
    localparam logic [31:0] RAM_LIMIT  = 32'h0000_1000;

    logic access_ram;
    logic access_accel;

    always_comb begin
        // Default outputs
        cpu_mem_rdata = 32'b0;

        ram_valid = 1'b0;
        ram_write = 1'b0;
        ram_addr  = 12'b0;
        ram_wdata = 32'b0;

        accel_valid = 1'b0;
        accel_write = 1'b0;
        accel_addr  = 5'b0;
        accel_wdata = 32'b0;

        // Address decoding
        access_ram   = (cpu_mem_addr < RAM_LIMIT);
        access_accel = (cpu_mem_addr >= ACCEL_BASE) &&
                       (cpu_mem_addr < ACCEL_BASE + 32'h0000_0014);

        // --------------------------------------------------------
        // RAM access
        // --------------------------------------------------------
        if (cpu_mem_valid && access_ram) begin
            ram_valid = 1'b1;
            ram_write = cpu_mem_write;

            // Word-addressed RAM.
            // CPU address bits [11:2] select a 32-bit word.
            ram_addr  = cpu_mem_addr[11:0];
            ram_wdata = cpu_mem_wdata;

            if (!cpu_mem_write)
                cpu_mem_rdata = ram_rdata;
        end

        // --------------------------------------------------------
        // Accelerator access
        // --------------------------------------------------------
        else if (cpu_mem_valid && access_accel) begin
            accel_valid = 1'b1;
            accel_write = cpu_mem_write;

            // Accelerator uses 5-bit register addresses.
            accel_addr  = cpu_mem_addr[4:0];
            accel_wdata = cpu_mem_wdata;

            if (!cpu_mem_write)
                cpu_mem_rdata = accel_rdata;
        end
    end

endmodule