# RISC-V AI Accelerator — Architecture

## 1. Project Overview

This project implements and evaluates a RISC-V based AI acceleration architecture for INT8 neural-network inference.

The architecture combines:

- A simple 32-bit RV32I-compatible RISC-V CPU
- Memory-mapped accelerator control
- Parallel INT8 multiply-accumulate processing elements
- An 8x8 matrix multiplication engine
- INT32 accumulation
- Bias addition
- ReLU activation
- Configurable 1-PE, 4-PE, and 8-PE compute configurations
- RTL simulation and synthesis-based architectural evaluation

The primary neural-network operation evaluated by the scalable accelerator is:

    Y = ReLU(A x B + Bias)

where:

- A is an 8x8 INT8 matrix
- B is an 8x8 INT8 matrix
- Bias contains 64 INT32 values
- Y contains 64 INT32 output values

---

## 2. High-Level Architecture

The project contains two related demonstrations.

### 2.1 CPU-integrated SoC

The first architecture demonstrates end-to-end CPU-to-accelerator interaction:

    +----------------------+
    |      RV32I CPU       |
    +----------+-----------+
               |
               | Memory-mapped access
               |
    +----------v-----------+
    | Accelerator Control  |
    +----------+-----------+
               |
               v
    +----------------------+
    | 4x4 Matrix Accelerator|
    +----------------------+

The CPU communicates with the accelerator through memory-mapped registers.

The verified address map is:

    0x0000 - 0x0FFF : SoC RAM
    0x1000          : Accelerator CONTROL
    0x1004          : Accelerator STATUS
    0x1008          : Accelerator A_DATA
    0x100C          : Accelerator B_DATA
    0x1010          : Accelerator C_DATA

The complete CPU-integrated 4x4 path has been functionally verified.

---

## 3. Scalable AI Accelerator

The main architectural research component is the scalable 8x8 accelerator.

    A[8x8] INT8
          |
          v
    +------------------+
    | Parallel PE Array|
    | 1 / 4 / 8 PEs    |
    +--------+---------+
             |
             v
       INT32 Accumulators
             |
             v
       Matrix C = A x B
             |
             +------ Bias
                     |
                     v
                   ReLU
                     |
                     v
               Y[8x8] INT32

The number of processing elements is a compile-time parameter:

    NUM_PE = 1
    NUM_PE = 4
    NUM_PE = 8

This allows the same RTL architecture to be evaluated at different levels of parallelism.

---

## 4. Processing Element

Each processing element contains a signed INT8 multiply-accumulate datapath.

The basic operation is:

    accumulator = accumulator + A * B

The operands are:

    A : signed INT8
    B : signed INT8

The multiplication produces a signed 16-bit product.

The product is sign-extended and accumulated into a signed 32-bit accumulator.

This avoids overflow for the small 8x8 workload used in the experiments.

---

## 5. Parallelism

For each matrix output element:

    C[i][j] = sum(A[i][k] * B[k][j])

The accelerator processes multiple output columns in parallel.

For an 8-PE configuration, up to eight output columns can be computed simultaneously.

For a 4-PE configuration, four output columns are processed at a time.

For a 1-PE configuration, one output element is processed at a time.

The same computation is therefore mapped onto different hardware parallelism levels without changing the mathematical workload.

---

## 6. Matrix Engine

The matrix engine uses a finite-state machine with the following major states:

    IDLE
    CLEAR
    COMPUTE
    STORE

### IDLE

Waits for the start signal.

### CLEAR

Clears the PE accumulators before a new computation.

### COMPUTE

Processes one value of k per clock cycle.

For an 8x8 matrix:

    k = 0 ... 7

Therefore each output accumulation requires eight MAC iterations.

### STORE

Transfers the PE accumulator results into the corresponding positions of the output matrix.

The engine then advances to the next group of output columns or the next row.

---

## 7. Bias and ReLU

After matrix multiplication:

    C = A x B

the inference datapath performs:

    Z = C + Bias

followed by:

    Y = ReLU(Z)

The ReLU operation is:

    ReLU(x) = x       if x >= 0
              0       otherwise

The implementation performs bias addition and ReLU combinationally after the matrix engine.

Consequently, the measured inference latency remains equal to the matrix-computation latency in the current architecture.

---

## 8. CPU Architecture

The CPU is a simple single-cycle RV32I implementation.

Implemented instruction classes include:

- R-type ALU operations
- I-type ALU operations
- Loads
- Stores
- Conditional branches
- JAL
- JALR
- LUI
- AUIPC

The CPU exposes separate instruction-memory and data-memory interfaces.

This separation is preserved in the SoC using dual-port RAM.

The CPU-integrated SoC was verified independently from the larger 8x8 accelerator scaling experiment.

---

## 9. Design Philosophy

The architecture intentionally avoids unnecessary complexity.

The project does not attempt to implement:

- A superscalar CPU
- A pipelined CPU
- Cache hierarchy
- Linux support
- RVV vector extensions
- Physical FPGA implementation
- Physical silicon implementation

The objective is instead to study a clear architectural question:

> How does increasing parallel INT8 compute resources affect inference latency and synthesized hardware cost?

The 1-PE, 4-PE, and 8-PE configurations provide controlled experiments for answering this question.
