# Ara_Cluster_TCDM_NoC: 4-Core Vector Cluster & 2D-Mesh NoC Tile
**4.096 TFLOPS FP16 Compute Tile, 32-Bank Conflict-Free TCDM SRAM & 5-Port VC Router**

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Academic Paper](https://img.shields.io/badge/Research_Paper-Read_PAPER.md-blueviolet.svg)](PAPER.md)
[![Compute](https://img.shields.io/badge/Compute_Density-4.096_TFLOPS_FP16-brightgreen.svg)]()
[![Memory](https://img.shields.io/badge/L1_TCDM_BW-256_GB%2Fs-blue.svg)]()
[![NoC](https://img.shields.io/badge/NoC_Router-5--Port_Dual--VC_Wormhole-orange.svg)]()
[![Fault_Tolerance](https://img.shields.io/badge/Defect_Bypass-1--Cycle_Deflection-purple.svg)]()


> 🧭 **Silicon Stack Navigation:** [Architecture Home](https://github.com/ITLABSofficial) &nbsp;•&nbsp; [⬅️ Prev: Ara_Core_TrueFMA_Systolic](https://github.com/ITLABSofficial/Ara_Core_TrueFMA_Systolic) &nbsp;•&nbsp; **Layer 05: `Ara_Cluster_TCDM_NoC`** &nbsp;•&nbsp; [Next: Ara_16Core_2x2_SoC ➡️](https://github.com/ITLABSofficial/Ara_16Core_2x2_SoC)

**Ara_Cluster_TCDM_NoC** is an open-source, fully synthesizable silicon compute tile macro designed for modular multicore AI SoCs and Wafer-Scale Engines. Each tile integrates **4 Ara Vector Processing Units (VPUs)**, a shared **32-bank 512 KB L1 Tightly-Coupled Data Memory (TCDM)** crossbar, a **5-port 2D-Mesh Virtual-Channel NoC Router**, and a **1-cycle Defect Bypass Unit** for silicon fault tolerance.

---

<!-- BEGIN_README_SILICON_UPGRADE -->
## Bare-Silicon Die Micrograph, IEEE RTL Schematic & Formal Verification (`SymbiYosys + Z3`)

- **Main Academic Paper (PDF):** [`PAPER.pdf`](PAPER.pdf) ([Markdown](PAPER.md) | [LaTeX](paper.tex))
- **Standalone Formal Verification Monograph (PDF):** [`PAPER_FORMAL_VERIFICATION.pdf`](PAPER_FORMAL_VERIFICATION.pdf) ([Markdown](PAPER_FORMAL_VERIFICATION.md) | [LaTeX](paper_formal.tex))
- **Executable SymbiYosys + Z3 Proofs:** [`formal/`](formal/) (`100% PASS, rc=0`)

| 2048x2048 Optical-Microscope Bare Silicon Die (`fig0`) | IEEE/ISSCC Synthesizable RTL & Formal Schematic (`fig5`) |
| :---: | :---: |
| ![Bare Silicon Die](figures/fig0_bare_silicon_die_2k.png) | ![IEEE RTL Schematic](figures/fig5_rtl_formal_microarchitecture.png) |

![SymbiYosys + Z3 Formal Verification Convergence](figures/fig6_formal_verification_convergence.png)
<!-- END_README_SILICON_UPGRADE -->




## 1. Architectural Highlights

```
                    North Port (NoC Ingress/Egress)
                                   ▲
                                   │
              West Port ◄──────[ 5-Port NoC ]──────► East Port
                               [   Router   ]
                                   │
                                   ▼
                            Local Egress/Ingress
                                   │
                                   ▼
                   ┌───────────────────────────────┐
                   │  1-Cycle Defect Bypass Unit   │
                   └───────────────┬───────────────┘
                                   │
                                   ▼
                   ┌───────────────────────────────┐
                   │ NoC Network Interface (NI)    │
                   │ (AXI5 <-> 544-bit Flit FIFO)  │
                   └───────────────┬───────────────┘
                                   │
        ┌──────────────────────────┴──────────────────────────┐
        │                                                     │
        ▼                                                     ▼
┌─────────────────────────────────┐           ┌─────────────────────────────────┐
│ 32-Bank 512 KB L1 TCDM SRAM     │           │ Hardware Barrier Tree &         │
│ (256 GB/s, XOR Hash Interconnect│           │ 8-Cycle PDN Inrush Stagger      │
└───────────────┬─────────────────┘           └─────────────────────────────────┘
                │
    ┌───────────┼───────────┬───────────┐
    ▼           ▼           ▼           ▼
┌───────┐   ┌───────┐   ┌───────┐   ┌───────┐
│ Core 0│   │ Core 1│   │ Core 2│   │ Core 3│  (4x Ara VPUs @ 2.0 GHz)
└───────┘   └───────┘   └───────┘   └───────┘
```

1. **4-Core Unified Vector Cluster**:
   - 4 independent Ara VPUs executing IEEE-754 FP16, BF16, FP8, and INT8 instructions.
   - Aggregate compute capability: **4.096 TFLOPS FP16** (or **8.192 TFLOPS FP8**) at 2.0 GHz.
2. **32-Bank Logarithmic L1 TCDM SRAM (`ara_tcdm_bank_interconnect.sv`)**:
   - 512 KB SRAM shared across all 4 cores with **256 GB/s local bandwidth**.
   - XOR-based address hashing eliminates bank conflicts for strided tensor strides and matrix transposes.
3. **5-Port Virtual-Channel 2D-Mesh Router (`ara_noc_mesh_router.sv`)**:
   - Dimension-Order Routing (DOR X-Y) with strict deadlock freedom.
   - Dual Virtual Channels (VC0: Request traffic, VC1: Higher-priority response traffic).
   - Wormhole packet locking with backpressure skid buffers.
4. **1-Cycle Silicon Defect Bypass Unit (`ara_noc_defect_bypass.sv`)**:
   - Enables wafer-scale silicon harvest by electrically isolating dead clusters and deflecting transit flits with a single-cycle latency penalty.

---

## 2. Directory Structure

```
Ara_Cluster_TCDM_NoC/
├── rtl/
│   ├── ara_multicore_cluster.sv        # Top-level 4-core cluster macro
│   ├── ara_tcdm_bank_interconnect.sv   # 32-bank conflict-free logarithmic SRAM crossbar
│   ├── ara_noc_mesh_router.sv          # 5-port 2D-mesh dual-VC router
│   ├── ara_noc_fifo.sv                 # High-speed skid buffer & FIFO
│   ├── ara_noc_ni.sv                   # AXI5 to 544-bit NoC packet network interface
│   ├── ara_noc_defect_bypass.sv        # 1-cycle deflection bypass and retargeting unit
│   ├── ara_multicore_true_fma_6stage.sv# 6-stage 2.0 GHz True-FMA pipeline
│   └── ara_systolic_tensor_unit.sv     # 16x16 systolic array matrix engine
├── tb/
│   ├── tb_ara_noc_mesh_router.sv       # Dimension-order routing & wormhole testbench
│   ├── tb_ara_noc_ni.sv                # AXI5 encapsulation testbench
│   └── tb_ara_noc_defect_bypass.sv     # Defect deflection & retargeting testbench
├── INTEGRATION_GUIDE.md                # Pinout, packet formats, and power distribution
├── BENCHMARKS.md                       # Latency, banking contention, and power benchmarks
├── Makefile                            # Automated build and regression recipes
└── LICENSE                             # Apache 2.0 Open-Source License
```

---

## 3. Quickstart & Verification

```bash
# 1. Clone repository
git clone https://github.com/<YOUR_USERNAME>/Ara_Cluster_TCDM_NoC.git
cd Ara_Cluster_TCDM_NoC

# 2. Run all unit testbenches (Router, NI, Defect Bypass - 100% PASS)
make test

# 3. Check ASIC synthesizability in Yosys
make synth_check
```

---

## 🗺️ Silicon Architecture Stack & Next-Page Navigation

This repository represents **Layer 05** of our 8-layer unified silicon supercomputing stack. You can navigate sequentially through the entire hardware hierarchy:

```
[01: PHY Layer] ➔ [02: Memory Controller] ➔ [03: Near-Memory PIM] ➔ [04: Ara Core True-FMA]
       ➔ [05: Cluster NoC] ➔ [06: 16-Core SoC] ➔ [07: 64-Core PCIe Card] ➔ [08: 16K WSE Wafer]
```

| Layer | Hardware Component | GitHub Repository | Key Architectural Specifications | Status |
|:---:|:---|:---|:---|:---:|
| **01** | **Physical Layer (PHY)** | [**`Open_HBM3_PHY`**](https://github.com/ITLABSofficial/Open_HBM3_PHY) | 1.18 TB/s HBM3E PHY, 8:1 SerDes, DFE/CTLE, 4.6 GHz WCK, DFI 5.0 | Active |
| **02** | **Memory Controller** | [**`Open_HBM3_Controller`**](https://github.com/ITLABSofficial/Open_HBM3_Controller) | 16-Pseudo-Channel DFI 5.0 Controller, SECDED ECC, Bank Interleaving | Active |
| **03** | **Near-Memory PIM** | [**`OpenHBM3_PIM_Subsystem`**](https://github.com/ITLABSofficial/OpenHBM3_PIM_Subsystem) | 3.2 TB/s Base-Die PIM Engine, FlashAttention, RMSNorm, True-FMA | Active |
| **04** | **Compute Core** | [**`Ara_Core_TrueFMA_Systolic`**](https://github.com/ITLABSofficial/Ara_Core_TrueFMA_Systolic) | 16x16 Systolic Array & 6-Stage 2.0 GHz True-FMA (1.024 TFLOPS FP16) | Active |
| **05** | **Cluster Interconnect** | [**`Ara_Cluster_TCDM_NoC` (Current)**](https://github.com/ITLABSofficial/Ara_Cluster_TCDM_NoC) | 4-Core Vector Cluster, 32-Bank TCDM SRAM (256 GB/s), 5-Port VC Router | Active |
| **06** | **Multicore SoC** | [**`Ara_16Core_2x2_SoC`**](https://github.com/ITLABSofficial/Ara_16Core_2x2_SoC) | 16-Core GALS NoC Multicore SoC, 4-Zone PDN Stagger, Linux C Driver | Active |
| **07** | **Board / Accelerator** | [**`Ara_PCIe_AI_Accelerator_64Core`**](https://github.com/ITLABSofficial/Ara_PCIe_AI_Accelerator_64Core) | 64-Core PCIe Gen5 x16 AI Card, 128 GB HBM3e Address Space (229W TDP) | Active |
| **08** | **Wafer-Scale Engine** | [**`WSE_16K_Wafer_Scale_Engine`**](https://github.com/ITLABSofficial/WSE_16K_Wafer_Scale_Engine) | 300mm Monolithic 16,384-Core Wafer Engine, 48x HBM3 (1.15 TB), 15 kW | Active |

<div align="center">

| ⬅️ **Previous Component** | 🏠 **Architecture Ecosystem** | ➡️ **Next Component** |
|:---:|:---:|:---:|
| [**⬅️ Ara_Core_TrueFMA_Systolic**](https://github.com/ITLABSofficial/Ara_Core_TrueFMA_Systolic) | [**ITLABSofficial Profile**](https://github.com/ITLABSofficial) | [**Ara_16Core_2x2_SoC ➔**](https://github.com/ITLABSofficial/Ara_16Core_2x2_SoC) |

</div>

---

## License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.
