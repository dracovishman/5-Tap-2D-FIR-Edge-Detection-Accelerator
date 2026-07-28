# ⚡ 5-Tap 2D FIR Digital Differentiator for Image Edge Detection
> **Dual-Flow Synthesis & PPA Analysis:** Cadence Genus (ASIC GPDK 180nm) & Xilinx Vivado 2024.2 (FPGA Kintex-7)

[![Language](https://img.shields.io/badge/Language-Verilog_2001-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Tool](https://img.shields.io/badge/ASIC_Tool-Cadence_Genus_21.14-orange.svg)](https://www.cadence.com)
[![Tool](https://img.shields.io/badge/FPGA_Tool-Xilinx_Vivado_2024.2-red.svg)](https://www.xilinx.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Timing_Status-PASSED_(Slack_+5.22ns)-brightgreen.svg)]()

---

## 📌 Executive Summary

This repository contains the Verilog RTL implementation, testbench verification, and dual synthesis flow (ASIC + FPGA) for a **5-Tap Separable 2D FIR Digital Differentiator Accelerator** designed for real-time image edge detection in computer vision and ADAS applications.

The digital differentiator highlights high-frequency spatial transitions (edges) by approximating first-order derivatives. To evaluate hardware trade-offs, two architecture variants were realized and synthesized:
1. **Pipelined Architecture (`fir_2d_edge_pipeline.v`)**: A 3-stage fine-grained pipeline achieving a high throughput of **1 output pixel per clock cycle**.
2. **Non-Pipelined Architecture (`fir_2d_edge_nopipeline.v`)**: A single-cycle combinational datapath optimized for minimal area footprint.

---

## 👨‍💻 Team & Academic Metadata

- **Course:** BEVD311L — VLSI Digital Signal Processing Systems
- **Faculty Guide:** Dr. REENA MONICA P
- **Department:** Department of SENSE, VIT Chennai
- **Team FIR Members:**
  - **A Sanjay** (23BVD1012)
  - **Subham Prasad Gupta** (23BVD1039)
  - **Jairus Solomon** (23BVD1040)
  - **Akhil Kumar** (23BVD1042)
  - **Vinayak Salunke** (23BVD1062)

---

## 📐 Mathematical Formulation

### 1. 1D FIR Differentiator Kernel
The 5-tap differentiator impulse response employs odd-symmetric impulse coefficients with zero DC gain:

$$\mathbf{h} = \frac{1}{8} \begin{bmatrix} -1 & -2 & 0 & 2 & 1 \end{bmatrix}$$

- **Odd Symmetry Requirement:** $h[-n] = -h[n]$, ensuring pure imaginary frequency response proportional to $\omega$.
- **Zero DC Gain:** $\sum h[n] = 0$, completely suppressing constant and slowly varying pixel intensities (low frequencies).

### 2. Separable 2D Edge Detection
Rather than implementing a full $5 \times 5$ 2D matrix multiplication ($25$ MAC operations), a **separable 2D FIR** approach is adopted:
- **Horizontal Gradient ($G_x$):** Filtering applied across rows.
- **Vertical Gradient ($G_y$):** Filtering applied across columns in parallel.

### 3. Magnitude Approximation
To avoid hardware-intensive square root and squaring operations ($\sqrt{G_x^2 + G_y^2}$), the edge magnitude is approximated using the L1 Manhattan norm with 8-bit saturation arithmetic:

$$|G(i, j)| = \min\Big(|G_x(i, j)| + |G_y(i, j)|, \, 255\Big)$$

---

## 🏗️ Hardware Architecture & Datapath

```
                       ┌──────────────────────────────┐
                       │  8-bit Pixel Input x(i,j)    │
                       └──────────────┬───────────────┘
                                      │
               ┌──────────────────────┴──────────────────────┐
               ▼                                             ▼
┌─────────────────────────────┐               ┌─────────────────────────────┐
│ 5-Tap FIR Row Differentiator│               │5-Tap FIR Col Differentiator │
│       (Computes Gx)         │               │       (Computes Gy)         │
└──────────────┬──────────────┘               └──────────────┬──────────────┘
               │ Gx(8-bit)                                   │ Gy(8-bit)
               └──────────────────────┬──────────────────────┘
                                      ▼
                      ┌───────────────────────────────┐
                      │    L1 Edge Magnitude &        │
                      │ 8-Bit Saturation (|Gx| + |Gy|) │
                      └───────────────┬───────────────┘
                                      ▼
                      ┌───────────────────────────────┐
                      │    8-Bit Edge Output y(i,j)   │
                      └───────────────────────────────┘
```

### 3-Stage Pipeline Breakdown (`fir_1d_pipeline.v`)
- **Stage 1 (Tapped Delay Line):** 5-register shift register buffer storing $x[n], x[n-1], \dots, x[n-4]$.
- **Stage 2 (Coefficient Multiplication):** Parallel scaling by coefficients $\{-1, -2, 0, +2, +1\}$ producing 12-bit signed partial products ($p_0 \dots p_4$).
- **Stage 3 (Accumulation & Scaling):** Carry-Save Adder (CSA) summation, arithmetic shift right by 3 ($\gg 3$), absolute value computation, and 8-bit output clamping.

---

## 📊 Synthesis & PPA Benchmarks

### 1. ASIC Synthesis — Cadence Genus 21.14 (GPDK 180nm)
Target Clock Frequency: **100 MHz** (10 ns period) | Operating Condition: **Slow Corner**

| Metric | Pipelined (3-Stage) | Non-Pipelined | Impact / Trade-off |
| :--- | :---: | :---: | :--- |
| **Cell Count** | **407 cells** | 204 cells | $\uparrow 2.0 \times$ register overhead |
| **Cell Area** | **13,601.65 $\mu m^2$** | 6,243.65 $\mu m^2$ | $\uparrow 2.18 \times$ area |
| **Data Path Delay** | **4,489 ps** | 4,672 ps | **4% shorter critical path** |
| **Setup Slack** | **+5,220 ps (MET)** | +4,362 ps (MET) | Timing met comfortably |
| **Total Power** | **1.297 mW** | 0.607 mW | $\uparrow 2.14 \times$ dynamic power |
| ├── *Register Power* | 898.1 $\mu W$ (69.3%) | 434.1 $\mu W$ (71.5%) | Flip-flop clocking dominant |
| ├── *Logic Power* | 307.4 $\mu W$ (23.7%) | 131.8 $\mu W$ (21.7%) | Combinational gates |
| ├── *Clock Power* | 91.3 $\mu W$ (7.0%) | 41.2 $\mu W$ (6.8%) | Tree distribution |
| └── *Leakage Power*| 467.6 nW | 198.9 nW | Static dissipation |
| **Throughput** | **1 pixel / cycle** | Variable | Essential for real-time video |

---

### 2. FPGA Synthesis & Implementation — Xilinx Vivado 2024.2
Target Device: **Xilinx Kintex-7 (`xc7k70tfbv676-1`)**

| Metric | Vivado Result | Note |
| :--- | :---: | :--- |
| **Status** | **Implementation Complete** | 0 Failed Routes |
| **Leaf Cells** | **30** | Compact Kintex-7 footprint |
| **Nets / IO Ports** | **51 / 20** | 8-bit in, 8-bit out + control |
| **Total On-Chip Power** | **7.095 W** | Vectorless estimation |
| ├── *Dynamic Power* | **6.997 W (99%)** | I/O dominant (5.985 W) |
| └── *Device Static* | **0.098 W (1%)** | Base static draw |
| **Junction Temp.** | **38.4 °C** | **46.6 °C thermal margin** |

---

## 📁 Repository Structure

```
.
├── README.md                     # Project Documentation & Synthesis Report
├── fir_1d_nopipeline.v           # 1D FIR Differentiator (Combinational)
├── fir_1d_pipeline.v             # 1D FIR Differentiator (3-Stage Pipelined)
├── fir_2d_edge_nopipeline.v      # Top-Level 2D Edge Detector (Non-Pipelined)
├── fir_2d_edge_pipeline.v        # Top-Level 2D Edge Detector (Pipelined)
├── tb_fir_2d_edge_pipeline.v     # Verilog Testbench with Automated Test Vectors
└── tb_fir_2d_edge_pipeline.vcd   # VCD Waveform Trace File
```

---

## 🚀 How to Run Local Simulation

You can simulate the design using [Icarus Verilog](http://iverilog.icarus.com/) and view the execution waveforms in [GTKWave](http://gtkwave.sourceforge.net/).

### Step 1: Compile the Verilog RTL & Testbench
```bash
iverilog -o sim.vvp fir_1d_pipeline.v fir_2d_edge_pipeline.v tb_fir_2d_edge_pipeline.v
```

### Step 2: Run Simulation & Generate VCD
```bash
vvp sim.vvp
```

### Step 3: View Simulation Waveform
```bash
gtkwave tb_fir_2d_edge_pipeline.vcd
```

---

## 🧪 Testbench Verification Scenarios

The testbench (`tb_fir_2d_edge_pipeline.v`) evaluates 4 critical functional test cases:
1. **Flat Region Test (Uniform Intensity):** Feeds pixels with constant value `100`. Expects `edge_out = 0`.
2. **Step Edge Test (0 $\rightarrow$ 200):** Simulates a sharp intensity transition. Confirms immediate derivative detection and magnitude scaling.
3. **Ramp Signal Test (0, 10, 20, ..., 90):** Verifies constant derivative output in steady state.
4. **Impulse Test (Value 8 at $n=0$):** Verifies the discrete impulse response profile of the $[-1, -2, 0, 2, 1]$ kernel.

---

## 📚 References

1. R. Matei and D. F. Chiper, *"Analytical Design and Polyphase Implementation Technique for 2D Digital FIR Differentiators,"* Sensors, vol. 24, no. 23, Article 7870, 2024. [DOI: 10.3390/s24237870](https://doi.org/10.3390/s24237870)
2. Cadence Design Systems, *Genus Synthesis Solution 21.14 User Guide*, 2026.
3. Xilinx Inc., *Vivado Design Suite User Guide: Synthesis (UG901)*, 2024.
