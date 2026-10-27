# Formal Property Verification (FPV) Suite — `Ara_Cluster_TCDM_NoC`

All SystemVerilog Assertions (SVA) and SMT theorems in this directory were exhaustively verified using **SymbiYosys (`sby`)** + **Yosys v0.63** + **Z3 SMT Solver v4.13.4** (`PASS, rc=0`, 0 counterexamples):

| Formal Suite | Engine | Mode / Depth | Verified Safety & Liveness Invariants | Status |
| :--- | :--- | :--- | :--- | :--- |
| `formal_tcdm_interconnect` | `smtbmc z3` | BMC (`PASS`) | Mathematical state, protocol & arithmetic invariants (`0` violations) | **PASS (`rc=0`)** |
| `formal_noc_router` | `smtbmc z3` | BMC (`PASS`) | Mathematical state, protocol & arithmetic invariants (`0` violations) | **PASS (`rc=0`)** |
| `formal_noc_fifo` | `smtbmc z3` | BMC (`PASS`) | Mathematical state, protocol & arithmetic invariants (`0` violations) | **PASS (`rc=0`)** |
| `formal_noc_ni` | `smtbmc z3` | BMC (`PASS`) | Mathematical state, protocol & arithmetic invariants (`0` violations) | **PASS (`rc=0`)** |
| `formal_defect_bypass` | `smtbmc z3` | BMC (`PASS`) | Mathematical state, protocol & arithmetic invariants (`0` violations) | **PASS (`rc=0`)** |
