# Experimental Methodology

## 1. Objective

The experimental objective is to evaluate how parallel processing-element count affects the latency and synthesized hardware cost of an INT8 matrix-based neural-network inference accelerator.

The evaluated architecture performs:

    Y = ReLU(A x B + Bias)

for an 8x8 matrix workload.

---

## 2. Hardware Configurations

Three configurations use the same RTL architecture:

    Configuration A: 1 PE
    Configuration B: 4 PE
    Configuration C: 8 PE

Only the number of instantiated processing elements is changed.

This provides a controlled architectural comparison.

---

## 3. Data Representation

Matrix operands use signed INT8 values.

Each multiply operation is:

    INT8 x INT8 -> INT16

The product is sign-extended and accumulated into a signed INT32 accumulator.

The output and bias values are represented using INT32.

This provides substantially more accumulation range than the individual INT8 operands.

---

## 4. Matrix Computation

For every output element:

    C[i][j] = sum(k=0..7) A[i][k] * B[k][j]

There are eight multiply-accumulate operations along the k dimension for every output.

Processing elements execute independent output-column calculations in parallel.

---

## 5. Inference Post-Processing

After matrix multiplication:

    Z[i][j] = C[i][j] + Bias[i][j]

The activation function is:

    Y[i][j] = max(Z[i][j], 0)

The current implementation performs this post-processing combinationally.

No additional sequential pipeline stage is introduced.

---

## 6. Functional Verification Method

For each PE configuration:

1. A deterministic signed INT8 matrix A is generated.
2. A deterministic signed INT8 matrix B is generated.
3. A deterministic INT32 bias vector is generated.
4. A software reference calculation computes:
   
       ReLU(A x B + Bias)

5. A and B are packed into the accelerator input buses.
6. The accelerator is started.
7. The testbench waits for completion.
8. All 64 hardware outputs are compared with the software reference.

A configuration is considered functionally correct only when all 64 outputs match.

---

## 7. Latency Measurement

Latency is measured in clock cycles from the accelerator start operation until the completion signal is observed.

Measured values:

    1 PE = 641 cycles
    4 PE = 161 cycles
    8 PE = 81 cycles

Speedup is calculated relative to the 1-PE baseline:

    Speedup = Cycles_1PE / Cycles_NPE

---

## 8. Synthesis Method

The RTL is synthesized using Yosys.

The synthesis flow includes:

- SystemVerilog RTL parsing
- Parameter specialization
- Hierarchy selection
- Process conversion
- Logic optimization
- Memory processing
- Technology mapping
- ABC optimization
- Final hierarchy statistics

The resulting cell count is used as a normalized hardware-cost metric.

---

## 9. Hardware-Cost Measurement

The reported hardware cost is the total hierarchical synthesized cell count.

The hierarchy includes:

- Inference wrapper
- Scalable matrix engine
- Processing elements
- MAC units

The comparison is therefore made between complete inference accelerator configurations rather than only the MAC datapath.

---

## 10. Timing Analysis Limitation

The current flow does not provide a physically meaningful maximum frequency.

The generic ABC technology library is useful for logic mapping but is not a substitute for a characterized ASIC standard-cell library.

Therefore timing numbers are intentionally excluded from the experimental claims.

A future technology-specific implementation could add:

- Standard-cell timing libraries
- Static timing analysis
- Clock constraints
- Place and route
- Post-layout timing

---

## 11. Reproducibility

All experiments are intended to be reproducible from the repository.

Simulation:

    Icarus Verilog

RTL validation:

    Verilator

Synthesis:

    Yosys + ABC

Operating environment:

    Apple Silicon MacBook Air

The project does not require an FPGA board for the reported experiments.

---

## 12. Interpretation

The experiment is an architectural scaling study rather than a physical implementation study.

The main question is:

> How much inference latency can be reduced by increasing parallel INT8 compute resources, and how does that improvement compare with the corresponding synthesized hardware growth?

The results show near-linear latency scaling for the evaluated 8x8 workload:

    1 PE -> 4 PE : 3.98x speedup
    1 PE -> 8 PE : 7.91x speedup

while synthesized hardware grows more slowly:

    1 PE -> 4 PE : 1.87x cells
    1 PE -> 8 PE : 3.02x cells

This makes PE parallelism the central architectural variable of the experiment.
