# Experimental Results

## 1. Workload

The scalable accelerator evaluates:

    Y = ReLU(A x B + Bias)

with:

- A: 8x8 signed INT8 matrix
- B: 8x8 signed INT8 matrix
- Bias: 64 signed INT32 values
- Y: 64 signed INT32 values

Three hardware configurations were evaluated:

    1 PE
    4 PE
    8 PE

---

## 2. Functional Results

All configurations successfully produced the expected output.

| Configuration | Latency | Functional Verification |
|---:|---:|:---:|
| 1 PE | 641 cycles | PASS |
| 4 PE | 161 cycles | PASS |
| 8 PE | 81 cycles | PASS |

All 64 output elements were checked in every configuration.

---

## 3. Performance Scaling

The 1-PE configuration is used as the baseline.

Speedup is calculated as:

    Speedup = Latency_1PE / Latency_configuration

Results:

| PE | Cycles | Speedup |
|---:|---:|---:|
| 1 | 641 | 1.00x |
| 4 | 161 | 3.98x |
| 8 | 81 | 7.91x |

The 1-to-4 PE configuration therefore achieves approximately 4x speedup.

The 1-to-8 PE configuration achieves approximately 7.91x speedup.

The small deviation from ideal scaling is caused by fixed control, clear, and store overheads.

---

## 4. Synthesis Results

RTL synthesis was performed using Yosys with generic ABC technology mapping.

The complete hierarchical cell counts were:

| PE | Synthesized Cells |
|---:|---:|
| 1 | 26,971 |
| 4 | 50,304 |
| 8 | 81,514 |

Relative to the 1-PE baseline:

| PE | Cell Growth |
|---:|---:|
| 1 | 1.00x |
| 4 | 1.87x |
| 8 | 3.02x |

The 8-PE architecture therefore provides 7.91x latency improvement while increasing synthesized cell count by approximately 3.02x.

---

## 5. Performance-to-Hardware Scaling

A normalized architectural efficiency metric is calculated as:

    Efficiency =
        Speedup / Cell Growth

Results:

| PE | Speedup | Cell Growth | Speedup / Cell Growth |
|---:|---:|---:|---:|
| 1 | 1.00x | 1.00x | 1.00 |
| 4 | 3.98x | 1.87x | 2.13 |
| 8 | 7.91x | 3.02x | 2.62 |

The 8-PE configuration provides the highest normalized performance improvement among the evaluated configurations.

This metric is based on synthesized logic-cell counts and should not be interpreted as physical silicon area efficiency.

---

## 6. Matrix-Only Scaling

The underlying matrix engine was independently evaluated before adding the bias and ReLU inference stage.

The matrix engine produced:

| PE | Matrix Latency |
|---:|---:|
| 1 | 641 cycles |
| 4 | 161 cycles |
| 8 | 81 cycles |

The complete inference accelerator has the same measured cycle counts.

This occurs because the current bias addition and ReLU stage is combinational and does not introduce additional sequential pipeline stages.

---

## 7. Hardware Cost Breakdown

For the 8-PE configuration, the synthesized hierarchy contains:

    matmul_inference_8x8 : 81,514 cells
    matmul_scalable_8x8  : 62,548 cells
    MAC units            : 8
    Each MAC              : 777 cells

Therefore the eight MAC instances contribute:

    8 x 777 = 6,216 cells

The remaining cells belong to control, routing, accumulation, matrix indexing, output storage, and inference post-processing logic.

---

## 8. Timing Methodology

No physical maximum operating frequency is reported.

The current synthesis flow uses Yosys and ABC with generic technology mapping. It does not use a characterized target standard-cell library with validated cell delays and timing constraints.

Therefore:

- No ASIC Fmax is claimed.
- No physical clock period is claimed.
- No silicon timing result is claimed.

This keeps the reported results consistent with what was actually measured.

---

## 9. Main Architectural Finding

The main experimental finding is:

> Increasing the number of parallel INT8 processing elements substantially reduces inference latency while requiring a smaller proportional increase in synthesized logic-cell count.

For the evaluated 8x8 workload:

    1 PE -> 4 PE:
        3.98x speedup
        1.87x cell growth

    1 PE -> 8 PE:
        7.91x speedup
        3.02x cell growth

This demonstrates the architectural benefit of parallel INT8 compute for matrix-based neural-network inference.

---

## 10. Limitations

The current results are RTL simulation and generic synthesis results.

The project does not claim:

- FPGA resource utilization
- FPGA maximum frequency
- ASIC physical area
- ASIC power
- Silicon measurements
- Post-layout timing

These measurements would require a specific FPGA target or an ASIC technology PDK and associated implementation flow.

---

## 11. Reproducibility

The main generated result files are:

    results/inference_scaling_results.csv
    results/inference_scaling_results.md

The synthesis logs are stored under:

    synthesis/results/

The inference scaling experiment can be regenerated using the project's scripts.
