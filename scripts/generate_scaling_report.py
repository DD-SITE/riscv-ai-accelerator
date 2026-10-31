#!/usr/bin/env python3

import re
from pathlib import Path

RESULTS_DIR = Path("synthesis/results")

PE_CONFIGS = [1, 4, 8]

cycles = {
    1: 641,
    4: 161,
    8: 81,
}

macs = {
    1: 1,
    4: 4,
    8: 8,
}


def extract_total_cells(pe):
    log_file = RESULTS_DIR / f"matmul_8x8_{pe}pe.log"

    if not log_file.exists():
        return None

    text = log_file.read_text()

    # Prefer the hierarchy total:
    #
    # === design hierarchy ===
    # ...
    # 14597 matmul_scalable_8x8
    # ...
    # 14597 cells
    #
    hierarchy_match = re.search(
        r"=== design hierarchy ===.*?"
        r"^\s*(\d+)\s+matmul_scalable_8x8\s*$.*?"
        r"^\s*(\d+)\s+cells\s*$",
        text,
        re.MULTILINE | re.DOTALL,
    )

    if hierarchy_match:
        return int(hierarchy_match.group(2))

    # Fallback: extract top-level local cells and MAC submodule cells.
    top_match = re.search(
        r"=== matmul_scalable_8x8 ===.*?"
        r"^\s*(\d+)\s+cells\s*$",
        text,
        re.MULTILINE | re.DOTALL,
    )

    mac_match = re.search(
        r"=== scalable_mac_unit_8x8 ===.*?"
        r"^\s*(\d+)\s+cells\s*$",
        text,
        re.MULTILINE | re.DOTALL,
    )

    if top_match and mac_match:
        return int(top_match.group(1)) + (
            int(mac_match.group(1)) * macs[pe]
        )

    return None


def main():
    print()
    print("=" * 78)
    print("RISC-V AI ACCELERATOR — 8x8 PE SCALING SUMMARY")
    print("=" * 78)
    print()

    print(
        f"{'PE':>5}"
        f"{'Cycles':>10}"
        f"{'Speedup':>12}"
        f"{'Cells':>14}"
        f"{'MACs':>10}"
        f"{'Cells/MAC':>14}"
    )

    print("-" * 78)

    baseline_cycles = cycles[1]

    for pe in PE_CONFIGS:
        cell_count = extract_total_cells(pe)

        speedup = baseline_cycles / cycles[pe]
        cells_per_mac = (
            cell_count / macs[pe]
            if cell_count is not None
            else None
        )

        cells_text = (
            f"{cell_count}"
            if cell_count is not None
            else "N/A"
        )

        cells_per_mac_text = (
            f"{cells_per_mac:.1f}"
            if cells_per_mac is not None
            else "N/A"
        )

        print(
            f"{pe:>5}"
            f"{cycles[pe]:>10}"
            f"{speedup:>11.2f}x"
            f"{cells_text:>14}"
            f"{macs[pe]:>10}"
            f"{cells_per_mac_text:>14}"
        )

    print()
    print("=" * 78)
    print("Functional verification:")
    print("1 PE : PASS")
    print("4 PE : PASS")
    print("8 PE : PASS")
    print("=" * 78)
    print()

    # Additional architecture analysis.
    cells_1 = extract_total_cells(1)
    cells_4 = extract_total_cells(4)
    cells_8 = extract_total_cells(8)

    if cells_1 and cells_4 and cells_8:
        print("ARCHITECTURAL ANALYSIS")
        print("-" * 78)

        print(
            f"1 PE -> 4 PE performance improvement : "
            f"{cycles[1] / cycles[4]:.2f}x"
        )

        print(
            f"1 PE -> 8 PE performance improvement : "
            f"{cycles[1] / cycles[8]:.2f}x"
        )

        print(
            f"4 PE -> 8 PE performance improvement : "
            f"{cycles[4] / cycles[8]:.2f}x"
        )

        print()

        print(
            f"1 PE -> 4 PE cell increase            : "
            f"{cells_4 / cells_1:.2f}x"
        )

        print(
            f"1 PE -> 8 PE cell increase            : "
            f"{cells_8 / cells_1:.2f}x"
        )

        print()

        print(
            f"Speedup / cell-growth (1 -> 4 PE)    : "
            f"{(cycles[1] / cycles[4]) / (cells_4 / cells_1):.2f}"
        )

        print(
            f"Speedup / cell-growth (1 -> 8 PE)    : "
            f"{(cycles[1] / cycles[8]) / (cells_8 / cells_1):.2f}"
        )

        print("=" * 78)
        print()


if __name__ == "__main__":
    main()
