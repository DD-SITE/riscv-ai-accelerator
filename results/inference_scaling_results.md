# 8x8 INT8 Inference Accelerator Scaling Results

Operation: `Y = ReLU(A × B + Bias)`  
Input precision: INT8  
Accumulator/output precision: INT32  
Matrix size: 8 × 8  
Configurations evaluated: 1, 4, and 8 PE

## Functional Verification

All 64 output elements were verified for all three PE configurations.

| PE | Cycles | Speedup | Synthesized Cells | Cell Growth | Speedup / Cell Growth |
|---:|---:|---:|---:|---:|---:|
| 1 | 641 | 1.00× | 26,971 | 1.00× | 1.00 |
| 4 | 161 | 3.98× | 50,304 | 1.87× | 2.13 |
| 8 | 81 | 7.91× | 81,514 | 3.02× | 2.62 |

## Architectural Observations

- 1 PE → 4 PE reduces latency from 641 to 161 cycles (3.98× speedup).
- 1 PE → 8 PE reduces latency from 641 to 81 cycles (7.91× speedup).
- 1 PE → 8 PE increases synthesized cell count from 26,971 to 81,514 (3.02× growth).
- The 1 PE → 8 PE speedup-to-cell-growth ratio is 2.62.

## Timing Methodology

No physical maximum-frequency value is reported. The current Yosys/ABC flow uses generic technology mapping without a characterized target standard-cell library and therefore does not provide defensible ASIC timing numbers.
