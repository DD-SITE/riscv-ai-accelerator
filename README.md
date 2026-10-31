# RISC-V Based Parallel AI Accelerator for Neural Network Inference

A compact RTL implementation of a simple RV32I RISC-V processor integrated with a configurable parallel INT8 AI accelerator for matrix-based neural-network inference.

The project focuses on a practical hardware-architecture question:

> **How does increasing compute parallelism affect inference latency and synthesized hardware cost?**

The accelerator evaluates 8×8 INT8 matrix multiplication with configurable 1, 4, and 8 processing elements (PEs), followed by bias addition and ReLU activation:

\[
Y = ReLU(A \times B + Bias)
\]

The complete design is written in SystemVerilog and verified through RTL simulation and synthesis using open-source tools.

---

## 1. Project Overview

The project combines a simple 32-bit RV32I RISC-V CPU with a dedicated parallel AI accelerator.

The CPU is responsible for control and program execution, while the accelerator performs the compute-intensive matrix multiplication using parallel INT8 multiply-accumulate (MAC) units.

### High-level architecture

```text
                         ┌─────────────────────┐
                         │      RV32I CPU      │
                         │                     │
                         │  PC                 │
                         │  Decoder            │
                         │  Register File      │
                         │  ALU                │
                         │  Memory Interface   │
                         └──────────┬──────────┘
                                    │
                           Memory-Mapped Control
                                    │
                                    ▼
                     ┌──────────────────────────┐
                     │     AI Accelerator       │
                     │                          │
                     │  ┌────┐ ┌────┐ ┌────┐   │
                     │  │ PE │ │ PE │ │ PE │...│
                     │  └────┘ └────┘ └────┘   │
                     │                          │
                     │     Parallel INT8 MACs   │
                     │                          │
                     │     Matrix Controller    │
                     └────────────┬─────────────┘
                                  │
                                  ▼
                         INT8 Matrix Multiply
                                  │
                                  ▼
                             Bias + ReLU
                                  │
                                  ▼
                           Neural Inference
## 2. Motivation

Modern AI workloads contain large amounts of matrix and vector computation.

A general-purpose CPU can execute these operations, but dedicated hardware can exploit data-level parallelism by performing multiple multiply-accumulate operations simultaneously.

This project demonstrates that concept at a small and understandable RTL scale.

Instead of building a highly complex processor or accelerator, the design deliberately focuses on:

- a simple RV32I processor
- INT8 arithmetic
- parallel MAC units
- configurable processing elements
- matrix multiplication
- simple accelerator control
- memory-mapped CPU/accelerator integration
- measurable performance and hardware-cost trade-offs

The goal is to provide a compact hardware architecture that can be understood, verified, synthesized, and experimentally evaluated.

---

## 3. Main Features

### RISC-V CPU

- 32-bit RV32I-compatible instruction subset
- Simple single-cycle architecture
- Program counter
- Instruction decoder
- 32-register register file
- ALU
- Immediate generation
- Load/store support
- Conditional branches
- Jumps
- LUI/AUIPC support
- Separate instruction and data interfaces

### AI Accelerator

- INT8 input arithmetic
- INT32 accumulation
- Multiply-accumulate (MAC) units
- Configurable processing-element count
- 1 PE, 4 PE, and 8 PE configurations
- 8×8 matrix multiplication
- Bias addition
- ReLU activation
- Simple finite-state-machine controller
- Start/busy/done control
- Memory-mapped accelerator registers

### SoC Integration

- RV32I CPU integrated with accelerator
- Dual-port on-chip RAM model
- Memory-mapped accelerator interface
- CPU starts the accelerator
- Accelerator reports completion
- CPU reads accelerator results
- End-to-end CPU → accelerator → memory operation verified

---

## 4. Inference Operation

The accelerator implements:

```
Y = ReLU(A × B + Bias)
```

where:

- `A` = 8×8 INT8 matrix
- `B` = 8×8 INT8 matrix
- `A × B` = 8×8 matrix of INT32 accumulated results
- `Bias` = 8×8 INT32 bias values
- `ReLU(x)` = max(0, x)
- `Y` = final 8×8 INT32 output

Each matrix multiplication output is computed using multiply-accumulate operations:

```
C[i][j] = Σ A[i][k] × B[k][j]
```

The architecture maps these operations onto multiple processing elements.

---

## 5. Processing Element Architecture

Each processing element contains an INT8 MAC datapath.

Conceptually:

```
       INT8 A
          │
          ▼
       ┌─────┐
       │  ×  │
       └──┬──┘
          │
          ▼
     INT16 Product
          │
          ▼
     INT32 Accumulator
          │
          ▼
       INT32 Result
```

The accelerator instantiates multiple PEs so that independent matrix-output calculations can proceed in parallel.

The number of PEs is configurable:

```
NUM_PE = 1
NUM_PE = 4
NUM_PE = 8
```

This allows the same RTL architecture to be evaluated under different levels of hardware parallelism.

---

## 6. Accelerator Control

The matrix engine uses a simple FSM:

```
             ┌─────────┐
             │  IDLE   │
             └────┬────┘
                  │ start
                  ▼
             ┌─────────┐
             │  CLEAR  │
             └────┬────┘
                  │
                  ▼
             ┌─────────┐
             │ COMPUTE │
             └────┬────┘
                  │
                  ▼
             ┌─────────┐
             │  STORE  │
             └────┬────┘
                  │
                  ├───────────────┐
                  │               │
                  ▼               ▼
               CLEAR             IDLE
                              (operation done)
```

The controller:

1. Receives a start request.
2. Clears the PE accumulators.
3. Performs the required MAC operations.
4. Stores the computed matrix results.
5. Advances through the matrix.
6. Signals completion.

---

## 7. CPU–Accelerator Integration

The accelerator is exposed through a simple memory-mapped register interface.

### Address map

| Address  | Function            |
| -------- | ------------------- |
| `0x1000` | Accelerator CONTROL |
| `0x1004` | Accelerator STATUS  |
| `0x1008` | Accelerator A_DATA  |
| `0x100C` | Accelerator B_DATA  |
| `0x1010` | Accelerator C_DATA  |

The CPU can therefore interact with the accelerator using ordinary load/store instructions.

Conceptually:

```
CPU
 │
 │ write control/data
 ▼
Accelerator
 │
 │ perform matrix multiplication
 ▼
DONE
 │
 │ CPU reads result
 ▼
RAM / Software-visible result
```

The complete CPU-to-accelerator flow has been verified in simulation.

---

## 8. Performance Scaling

The main architectural experiment evaluates the same 8×8 inference workload with different numbers of processing elements.

### Functional verification

All 64 output elements were verified for:

- 1 PE
- 4 PE
- 8 PE

### Measured latency

| Configuration | Cycles | Speedup |
| ------------- | ------ | ------- |
| 1 PE          | 641    | 1.00×   |
| 4 PE          | 161    | 3.98×   |
| 8 PE          | 81     | 7.91×   |

Increasing the number of PEs substantially reduces the number of cycles required for the same workload.

The scaling is not perfectly linear because the architecture contains control, clear, store, and other overheads in addition to the parallel MAC computation.

---

## 9. Synthesis Results

The three configurations were synthesized using Yosys with generic technology mapping.

| PE Configuration | Synthesized Cells | Cell Growth |
| ---------------- | ----------------- | ----------- |
| 1 PE             | 26,971            | 1.00×       |
| 4 PE             | 50,304            | 1.87×       |
| 8 PE             | 81,514            | 3.02×       |

This demonstrates the fundamental hardware trade-off:

```
More parallel PEs
       │
       ├──► Lower inference latency
       │
       └──► Higher hardware cost
```

For the measured workload:

```
1 PE → 8 PE

Latency:
641 → 81 cycles

Speedup:
1.00× → 7.91×

Synthesized cells:
26,971 → 81,514
```

This performance-versus-hardware-cost relationship is the primary architectural observation of the project.

---

## 10. Verification

The project contains dedicated testbenches for the major hardware blocks.

Verified components include:

- Register file
- ALU
- Instruction decoder
- RV32I CPU
- INT8 MAC
- Processing element
- PE array
- 4×4 matrix multiplication engine
- SoC bus
- CPU-to-accelerator SoC integration
- Bias + ReLU
- 8×8 scalable matrix accelerator
- 8×8 inference accelerator

The final 8×8 inference tests verify all 64 output elements against independently calculated expected values.

---

## 11. Tools

The project uses an entirely open-source/local RTL development flow.

### RTL and simulation

- SystemVerilog
- Icarus Verilog
- Verilator

### Synthesis

- Yosys
- ABC technology mapping

### Development environment

- macOS
- VS Code
- Make / shell scripts

No FPGA board or physical ASIC silicon is required for reproducing the RTL simulation and synthesis experiments.

---

## 12. Repository Structure

```
riscv-ai-accelerator/
│
├── rtl/
│   ├── cpu/
│   │   ├── alu.sv
│   │   ├── cpu.sv
│   │   ├── decoder.sv
│   │   └── regfile.sv
│   │
│   ├── accelerator/
│   │   ├── mac.sv
│   │   ├── pe.sv
│   │   ├── pe_array.sv
│   │   ├── matmul_engine.sv
│   │   ├── matmul_scalable.sv
│   │   ├── matmul_scalable_8x8.sv
│   │   ├── bias_relu.sv
│   │   ├── matmul_inference_8x8.sv
│   │   └── accelerator_ctrl.sv
│   │
│   ├── memory/
│   │   └── soc_ram_dual.sv
│   │
│   └── soc/
│       ├── soc_bus.sv
│       └── riscv_ai_soc.sv
│
├── tb/
│   ├── cpu_tb.sv
│   ├── mac_tb.sv
│   ├── pe_tb.sv
│   ├── pe_array_tb.sv
│   ├── matmul_tb.sv
│   ├── matmul_scaling_tb.sv
│   ├── matmul_8x8_scaling_tb.sv
│   ├── matmul_inference_8x8_tb.sv
│   └── ...
│
├── scripts/
│   ├── synthesize_8x8_scaling.sh
│   ├── synthesize_inference_8x8_scaling.sh
│   └── generate_inference_results.sh
│
├── synthesis/
│   └── results/
│
├── results/
│   ├── inference_scaling_results.csv
│   └── inference_scaling_results.md
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── METHODOLOGY.md
│   ├── RESULTS.md
│   └── VERIFICATION.md
│
└── README.md
```

---

## 13. Reproducing the 8×8 Inference Simulation

From the repository root:

### 1 PE

```
iverilog -g2012 \
  -Pmatmul_inference_8x8_tb.NUM_PE_VALUE=1 \
  -o inference_1pe_sim \
  rtl/accelerator/matmul_scalable_8x8.sv \
  rtl/accelerator/matmul_inference_8x8.sv \
  tb/matmul_inference_8x8_tb.sv

vvp inference_1pe_sim
```

Expected result:

```
PE configuration : 1
Measured cycles  : 641
PASS: All 64 inference outputs correct
```

### 4 PE

```
iverilog -g2012 \
  -Pmatmul_inference_8x8_tb.NUM_PE_VALUE=4 \
  -o inference_4pe_sim \
  rtl/accelerator/matmul_scalable_8x8.sv \
  rtl/accelerator/matmul_inference_8x8.sv \
  tb/matmul_inference_8x8_tb.sv

vvp inference_4pe_sim
```

Expected result:

```
PE configuration : 4
Measured cycles  : 161
PASS: All 64 inference outputs correct
```

### 8 PE

```
iverilog -g2012 \
  -Pmatmul_inference_8x8_tb.NUM_PE_VALUE=8 \
  -o inference_8pe_sim \
  rtl/accelerator/matmul_scalable_8x8.sv \
  rtl/accelerator/matmul_inference_8x8.sv \
  tb/matmul_inference_8x8_tb.sv

vvp inference_8pe_sim
```

Expected result:

```
PE configuration : 8
Measured cycles  : 81
PASS: All 64 inference outputs correct
```

Icarus may report a `constant selects in always_* processes` sensitivity warning for the inference wrapper. This is a simulator limitation/warning and does not prevent the functional tests from passing.

---

## 14. Reproducing Synthesis

The 8×8 inference scaling synthesis can be run with:

```
bash scripts/synthesize_inference_8x8_scaling.sh
```

The flow synthesizes:

```
1 PE
4 PE
8 PE
```

and writes the generated synthesis artifacts under:

```
synthesis/results/
```

The measured research results are summarized in:

```
results/inference_scaling_results.csv
results/inference_scaling_results.md
```

---

## 15. Timing Methodology

This project deliberately does **not** report a physical maximum operating frequency.

The current synthesis flow uses generic Yosys/ABC technology mapping without a characterized target standard-cell library and without physical timing constraints.

Therefore, reporting a specific ASIC frequency in MHz would not be scientifically defensible.

The current hardware-cost comparison instead focuses on:

- synthesized cell count
- relative cell growth
- cycle-level latency
- speedup from increased parallelism

A future technology-specific implementation could use a characterized standard-cell library and timing constraints to perform a proper timing analysis.

---

## 16. Limitations

This project is intentionally kept compact.

It does not currently implement:

- pipelined RISC-V execution
- caches
- vector/RVV instructions
- DMA
- AXI or other complex bus protocols
- large external memories
- FPGA deployment
- physical ASIC implementation
- power measurement
- technology-specific timing analysis
- large-scale neural-network models

These limitations are deliberate and keep the architecture understandable and suitable for RTL-level architectural experimentation.

---

## 17. Future Research Directions

Possible extensions include:

- Larger matrix dimensions
- Additional PE configurations
- Pipelined MAC datapaths
- Systolic-array-style architectures
- More detailed memory/buffer architectures
- FPGA implementation
- Technology-specific timing analysis
- Power and energy analysis
- Different quantization formats
- Comparison of different accelerator dataflows

These are potential future directions rather than features currently claimed as implemented.

---

## 18. Research Takeaway

The central result of this project is the relationship between parallel hardware and inference latency.

For the evaluated 8×8 INT8 workload:

```
             More Parallelism
                    │
                    ▼
          ┌────────────────────┐
          │ More Processing    │
          │ Elements           │
          └─────────┬──────────┘
                    │
             Lower Latency
                    │
                    ▼
             Higher Hardware
                  Cost
```

The measured results demonstrate this trade-off quantitatively:

```
             1 PE        4 PE        8 PE
              │           │           │
Cycles       641         161          81
              │           │           │
Speedup      1.00×       3.98×       7.91×
              │           │           │
Cells       26,971      50,304      81,514
```

The project therefore serves as a compact study of how architectural parallelism can be used to accelerate an AI-oriented workload while increasing hardware resources.

---

## 19. Project Status

**RTL implementation:** Complete\
**Functional verification:** Complete\
**CPU/accelerator integration:** Complete\
**1/4/8 PE scaling study:** Complete\
**Synthesis study:** Complete\
**Research documentation:** Complete &#x20;

The RTL architecture is intentionally frozen at this scope. The next stage is project presentation, reproducibility, and deeper understanding of the implemented design.

---

## 20. Author

**Divyam Dixit**\
B.Tech — Electronics & Communication Engineering\
National Institute of Technology Raipur

This project was developed as an RTL/VLSI/SoC research-oriented project focusing on RISC-V, hardware acceleration, parallel architectures, and AI/ML inference.

