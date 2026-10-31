#!/bin/bash

set -euo pipefail

mkdir -p synthesis/results

echo "=============================================="
echo "8x8 AI ACCELERATOR SYNTHESIS SCALING"
echo "=============================================="
echo ""

for PE in 1 4 8
do
    echo "----------------------------------------------"
    echo "Synthesizing ${PE}-PE configuration"
    echo "----------------------------------------------"

    yosys -p "
        read_verilog -sv rtl/accelerator/matmul_scalable_8x8.sv;

        chparam -set NUM_PE ${PE} matmul_scalable_8x8;
        hierarchy -top matmul_scalable_8x8;

        proc;
        opt;
        memory;
        opt;
        techmap;
        opt;
        abc -g simple;
        clean;

        stat;

        write_verilog synthesis/results/matmul_8x8_${PE}pe_netlist.v;
    " 2>&1 | tee synthesis/results/matmul_8x8_${PE}pe.log

    echo ""
    echo "SUCCESS: ${PE}-PE synthesis completed."
    echo ""
done

echo "=============================================="
echo "ALL 8x8 SYNTHESIS RUNS COMPLETED SUCCESSFULLY"
echo "=============================================="
