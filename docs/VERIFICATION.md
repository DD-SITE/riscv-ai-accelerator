# Verification

## 1. Verification Strategy

The project uses layered RTL verification.

Individual components are verified first, followed by subsystem-level verification and finally complete inference-path verification.

The major verification layers are:

1. CPU
2. INT8 MAC
3. Processing element
4. PE array
5. Matrix multiplication engine
6. SoC bus
7. CPU-integrated SoC
8. Bias + ReLU
9. 8x8 scalable inference accelerator

---

## 2. CPU Verification

The RV32I CPU was tested using a dedicated testbench.

The CPU verification completed successfully with:

    RV32I CPU TEST PASSED

The CPU testbench covers the implemented arithmetic, logical, memory, branch, and jump functionality.

The CPU RTL was subsequently lint-checked using Verilator.

---

## 3. MAC Verification

The signed INT8 MAC unit was independently tested.

Test result:

    INT8 MAC TEST PASSED

The test verifies signed multiplication and accumulation into the 32-bit accumulator.

---

## 4. Processing Element Verification

The processing element was tested independently after integration of the MAC unit.

Test result:

    PROCESSING ELEMENT TEST PASSED

---

## 5. PE Array Verification

A four-PE array was tested using independent inputs and verified outputs.

Test result:

    4-PE ARRAY TEST PASSED

---

## 6. Matrix Multiplication Verification

The 4x4 matrix engine was verified using:

- Identity matrix multiplication
- Signed non-trivial matrix multiplication

The non-trivial test included both positive and negative INT8 values.

Expected output:

    [  4    8   13   11 ]
    [ 12   24   29   27 ]
    [ -4    4    7   -3 ]
    [  2  -24  -15    1 ]

Verification result:

    PASS: Identity matrix test
    PASS: Signed non-trivial matrix test
    4x4 MATRIX MULTIPLICATION ALL TESTS PASSED

The matrix engine was also lint-checked with Verilator.

---

## 7. SoC Bus Verification

The memory-mapped SoC bus was tested for:

- RAM write/read
- Multiple RAM locations
- Accelerator control routing
- Accelerator status routing
- Accelerator A-data routing
- Accelerator B-data routing
- Accelerator C-data routing
- Invalid address handling

Result:

    PASS: RAM write/read
    PASS: Multiple RAM locations
    PASS: Accelerator CONTROL routing
    PASS: Accelerator STATUS read routing
    PASS: Accelerator A_DATA routing
    PASS: Accelerator B_DATA routing
    PASS: Accelerator C_DATA read routing
    PASS: Invalid address handling
    SOC BUS TEST PASSED

---

## 8. CPU-to-Accelerator SoC Verification

The CPU-integrated SoC was verified end-to-end.

The CPU:

1. Loaded accelerator input data
2. Started the accelerator
3. Polled accelerator status
4. Waited for completion
5. Read the output matrix
6. Transferred the results into RAM

The final result was verified against the expected 4x4 matrix.

Result:

    PASS: CPU reached halt loop
    PASS: Accelerator completed
    PASS: Accelerator C[0][0] correct
    PASS: 4x4 matrix result correctly transferred to RAM

The 16 output values in RAM matched the expected matrix.

---

## 9. Bias + ReLU Verification

The bias and ReLU datapath was tested independently using positive, negative, zero, and mixed-sign values.

Test result:

    BIAS + RELU TEST PASSED

The tested operation was:

    output = max(input + bias, 0)

---

## 10. 8x8 Inference Verification

The complete inference datapath was tested for three PE configurations:

    NUM_PE = 1
    NUM_PE = 4
    NUM_PE = 8

The operation was:

    Y = ReLU(A x B + Bias)

Each configuration was tested against a software-generated expected result.

All 64 output elements were checked.

### 1 PE

    PE configuration : 1
    Measured cycles  : 641
    PASS: All 64 inference outputs correct

### 4 PE

    PE configuration : 4
    Measured cycles  : 161
    PASS: All 64 inference outputs correct

### 8 PE

    PE configuration : 8
    Measured cycles  : 81
    PASS: All 64 inference outputs correct

Therefore:

    1 PE : 64/64 correct
    4 PE : 64/64 correct
    8 PE : 64/64 correct

---

## 11. Simulation Tools

The primary RTL simulation tool is:

    Icarus Verilog 13.0

Verilator is used for linting and additional RTL validation.

The design was developed and tested on an Apple Silicon MacBook Air environment.

---

## 12. Known Tool Warning

Icarus Verilog reports messages of the form:

    sorry: constant selects in always_* processes are not fully supported

These messages are related to Icarus sensitivity analysis for SystemVerilog always_comb blocks.

The simulations still produce the expected results.

The affected RTL has also been checked using Verilator without corresponding functional errors.

These messages are therefore treated as simulator limitations rather than design failures.
