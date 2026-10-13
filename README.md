# ⚡ 5-Tap 2D FIR Digital Differentiator for Image Edge Detection
> **Dual-Flow Synthesis & PPA Analysis:** Cadence Genus (ASIC GPDK 180nm) & Xilinx Vivado 2024.2 (FPGA Kintex-7)

[![Language](https://img.shields.io/badge/Language-Verilog_2001-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Tool](https://img.shields.io/badge/ASIC_Tool-Cadence_Genus_21.14-orange.svg)](https://www.cadence.com)
[![Tool](https://img.shields.io/badge/FPGA_Tool-Xilinx_Vivado_2024.2-red.svg)](https://www.xilinx.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Timing_Status-PASSED_(Slack_+5.22ns)-brightgreen.svg)]()

---

## 📌 Executive Summary

This repository contains the complete Verilog RTL implementation, testbench verification, and dual synthesis flow (ASIC + FPGA) for a **5-Tap Separable 2D FIR Digital Differentiator Accelerator** designed for real-time image edge detection in computer vision, robotics, and Advanced Driver Assistance Systems (ADAS).

The digital differentiator highlights high-frequency spatial transitions (edges) by approximating first-order derivatives. To evaluate real-world silicon trade-offs, two architecture variants were realized and synthesized:
1. **Pipelined Architecture (`fir_2d_edge_pipeline.v`)**: A 3-stage fine-grained pipeline achieving a high throughput of **1 output pixel per clock cycle**.
2. **Non-Pipelined Architecture (`fir_2d_edge_nopipeline.v`)**: A single-cycle combinational datapath optimized for minimal area footprint.

---

## 👨‍💻 Team & Academic Metadata

- **Course:** BEVD311L — VLSI Digital Signal Processing Systems
- **Faculty Guide:** Dr. REENA MONICA P
- **Department:** Department of SENSE, VIT Chennai
- **Team FIR Members:**
  - **Vinayak Salunke** (23BVD1062) — RTL Design & Synthesis Flow
  - **A Sanjay** (23BVD1012)
  - **Subham Prasad Gupta** (23BVD1039)
  - **Jairus Solomon** (23BVD1040)
  - **Akhil Kumar** (23BVD1042)

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

<p align="center">
  <img width="95%" alt="Top-Level 2D FIR Differentiator Architecture" src="https://github.com/user-attachments/assets/21a8be7a-fd2b-4837-8cde-02be8cdcaec9" />
</p>

<p align="center">
  <img width="95%" alt="1D FIR Pipelined Datapath" src="https://github.com/user-attachments/assets/07096205-98f7-4d76-9ffe-33b2efb14eae" />
</p>

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

## 📊 ASIC Synthesis & PPA Trade-Off Analysis (GPDK 180nm)

Both designs were synthesized targeting the **GPDK 180nm standard-cell library** using **Cadence Genus 21.14** at a 100 MHz target clock frequency (10 ns period) under Slow Corner operating conditions.

| Metric | Pipelined (3-Stage) | Non-Pipelined (Combinational) | Trade-Off Impact |
| :--- | :---: | :---: | :--- |
| **Cell Count** | **407 cells** | 204 cells | $\uparrow 2.0 \times$ register overhead |
| **Cell Area** | **13,601.65 $\mu m^2$** | 6,243.65 $\mu m^2$ | $2.18\times$ Area Overhead |
| **Total Power** | **1.297 mW** | 0.607 mW | $2.14\times$ Power Overhead |
| ├── *Register Power* | 898.1 $\mu W$ (69.3%) | 434.1 $\mu W$ (71.5%) | Flip-flop clocking dominant |
| ├── *Logic Power* | 307.4 $\mu W$ (23.7%) | 131.8 $\mu W$ (21.7%) | Combinational gates |
| ├── *Clock Power* | 91.3 $\mu W$ (7.0%) | 41.2 $\mu W$ (6.8%) | Tree distribution |
| └── *Leakage Power*| 467.6 nW | 198.9 nW | Static dissipation |
| **Critical Path** | **4,489 ps** | 4,672 ps | **4% shorter critical path** |
| **Setup Slack** | **+5,220 ps (MET)** | +4,362 ps (MET) | Both easily met 100 MHz target |
| **Throughput** | **1 pixel / cycle** | Variable | **Essential for real-time video** |

### Cadence Genus Schematic Views

#### 1. Pipelined Architecture Schematic
<p align="center">
  <img width="95%" alt="Cadence Genus Synthesis - Pipelined Architecture" src="https://github.com/user-attachments/assets/952ff72c-8c42-4c49-a6e3-99c9a7db1c8e" />
</p>

#### 2. Non-Pipelined Architecture Schematic
<p align="center">
  <img width="95%" alt="Cadence Genus Synthesis - Non-Pipelined Architecture" src="https://github.com/user-attachments/assets/4f3ecab8-29cc-4303-9208-47577ed04edf" />
</p>

---

## 📟 FPGA Implementation (Xilinx Kintex-7)

The pipelined design was fully implemented on a **Xilinx Kintex-7 (`xc7k70tfbv676-1`)** device using **Vivado 2024.2**:
- **Routing Closure:** Achieved 0 failed routes during the `route_design` phase.
- **Resource Utilization:** 30 Leaf Cells, 51 Nets, 20 IO ports.
- **Total On-Chip Power:** Estimated at **7.095 W** (Dynamic: 6.997 W heavily driven by I/O termination; Device Static: 0.098 W).
- **Thermal Margin:** Junction temperature measured at **38.4 °C** (46.6 °C safe thermal headroom).

<p align="center">
  <img width="95%" alt="Vivado Kintex-7 Device Implementation Layout" src="https://github.com/user-attachments/assets/ad2dacd7-e963-49a4-8176-4aee17d4b80d" />
</p>

<p align="center">
  <img width="95%" alt="Vivado Power and Timing Utilization Reports" src="https://github.com/user-attachments/assets/a114e8cc-a1e3-407f-8b2d-66ef992813b9" />
</p>

---

## 🧪 Functional Verification & Simulation

Functional correctness, pipeline latency, and saturation arithmetic were thoroughly verified using self-checking Verilog testbenches across 4 distinct spatial scenarios:
1. **Flat Region Test (Uniform Intensity):** Constant pixel input of `100` $\rightarrow$ Confirmed `edge_out = 0`.
2. **Step Edge Test (0 $\rightarrow$ 200):** Sharp intensity transition $\rightarrow$ Immediate derivative detection and magnitude scaling.
3. **Ramp Signal Test (0, 10, 20, ..., 90):** Linear intensity variation $\rightarrow$ Stable constant derivative in steady state.
4. **Impulse Test (Value 8 at $n=0$):** Verified the exact impulse response profile of the $[-1, -2, 0, 2, 1]$ kernel.

<p align="center">
  <img width="95%" alt="GTKWave Waveform Verification" src="https://github.com/user-attachments/assets/30e8a0e6-72a9-473d-8989-775b414ae336" />
</p>

---

## 🚀 How to Run Local Simulation

You can simulate the design using [Icarus Verilog](http://iverilog.icarus.com/) and view the execution waveforms in [GTKWave](http://gtkwave.sourceforge.net/):

```bash
# 1. Compile the pipelined design and testbench
iverilog -o sim.vvp fir_1d_pipeline.v fir_2d_edge_pipeline.v tb_fir_2d_edge_pipeline.v

# 2. Execute the simulation and dump VCD
vvp sim.vvp

# 3. View the simulation waveform
gtkwave tb_fir_2d_edge_pipeline.vcd
```

---

## 📁 Repository Structure

```
.
├── README.md                     # Comprehensive Architecture & Synthesis Report
├── fir_1d_nopipeline.v           # 1D FIR Differentiator (Combinational Datapath)
├── fir_1d_pipeline.v             # 1D FIR Differentiator (3-Stage Pipelined)
├── fir_2d_edge_nopipeline.v      # Top-Level 2D Edge Detector (Non-Pipelined)
├── fir_2d_edge_pipeline.v        # Top-Level 2D Edge Detector (Pipelined)
├── tb_fir_2d_edge_pipeline.v     # Self-Checking Verilog Testbench
└── tb_fir_2d_edge_pipeline.vcd   # VCD Waveform Trace File
```

---

## 📚 References

1. R. Matei and D. F. Chiper, *"Analytical Design and Polyphase Implementation Technique for 2D Digital FIR Differentiators,"* Sensors, vol. 24, no. 23, Article 7870, 2024. [DOI: 10.3390/s24237870](https://doi.org/10.3390/s24237870)
2. Cadence Design Systems, *Genus Synthesis Solution 21.14 User Guide*, 2026.
3. Xilinx Inc., *Vivado Design Suite User Guide: Synthesis (UG901)*, 2024.
