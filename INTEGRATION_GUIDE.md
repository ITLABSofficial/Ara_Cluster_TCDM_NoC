# Ara_Cluster_TCDM_NoC: Hardware Integration & Pinout Guide
**4-Core Compute Tile, Multi-Banked TCDM Crossbar, and 2D-Mesh Router**

---

## 1. Top-Level Module Instantiation

The compute tile macro `ara_multicore_cluster` encapsulates 4 Ara VPUs, the 32-bank TCDM memory subsystem, and connects to the mesh router via the network interface.

### SystemVerilog Instantiation Template

```systemverilog
ara_multicore_cluster #(
    .CLUSTER_ID      (4'd0),   // Unique tile ID in mesh
    .NUM_CORES       (4),      // 4 Ara VPUs per cluster
    .TCDM_BANKS      (32),     // 32-bank interleaved SRAM
    .TCDM_SIZE_KB    (512)     // 512 KB total L1 TCDM
) u_cluster_tile (
    // Clock & Synchronous Reset
    .clk_i           (clk_core_2000mhz),    // 2.0 GHz cluster compute clock
    .rst_n           (sys_rst_n),           // Active-low synchronous reset

    // Power Distribution & Stagger Control
    .pdn_tile_en_i   (pdn_cluster_en),      // Staggered power enable strobe
    .pdn_stable_o    (pdn_cluster_stable),  // Rail voltage within +/-2%
    .pdn_abort_i     (emergency_abort),     // 1-cycle power dump abort

    // Network Interface AXI5 Slave (Traffic from NoC)
    .ni_axi_awaddr_i (ni_cluster_awaddr),
    .ni_axi_awvalid_i(ni_cluster_awvalid),
    .ni_axi_awready_o(ni_cluster_awready),
    .ni_axi_wdata_i  (ni_cluster_wdata),
    .ni_axi_wvalid_i (ni_cluster_wvalid),
    .ni_axi_wready_o (ni_cluster_wready),
    .ni_axi_bvalid_o (ni_cluster_bvalid),
    .ni_axi_bready_i (ni_cluster_bready),
    .ni_axi_araddr_i (ni_cluster_araddr),
    .ni_axi_arvalid_i(ni_cluster_arvalid),
    .ni_axi_arready_o(ni_cluster_arready),
    .ni_axi_rdata_o  (ni_cluster_rdata),
    .ni_axi_rvalid_o (ni_cluster_rvalid),
    .ni_axi_rready_i (ni_cluster_rready),

    // 5-Port Mesh Router Connections
    .noc_port_north_i(noc_mesh_north_in),
    .noc_port_north_o(noc_mesh_north_out),
    .noc_port_east_i (noc_mesh_east_in),
    .noc_port_east_o (noc_mesh_east_out),
    .noc_port_south_i(noc_mesh_south_in),
    .noc_port_south_o(noc_mesh_south_out),
    .noc_port_west_i (noc_mesh_west_in),
    .noc_port_west_o (noc_mesh_west_out),

    // Hardware Defect Bypass Control
    .defect_en_i     (cluster_defect_isolate),// Isolate dead silicon tile
    .spare_coord_x_i (spare_target_x[3:0]),   // Retargeting X coordinate
    .spare_coord_y_i (spare_target_y[3:0])    // Retargeting Y coordinate
);
```

---

## 2. NoC Packet & Flit Protocol (544-bit)

All inter-cluster communication uses a unified 544-bit wormhole packet format:

```
+─────────────────────────────────────────────────────────────────────────────+
|                          544-BIT NOC FLIT STRUCTURE                         |
|                                                                             |
|  [543:542]   [541:538]   [537:534]   [533:530]   [529:526]   [525:512]   [511:0]  |
| Flit Type    Dest X      Dest Y      Src X       Src Y       Cmd & Txn   Payload  |
| (HEAD/BODY/  (4 bits)    (4 bits)    (4 bits)    (4 bits)    ID (14 b)  (512-bit) |
|  TAIL/SINGLE)                                                                         |
+─────────────────────────────────────────────────────────────────────────────+
```

### Virtual Channel Routing Rules
- **VC0 (Low Priority - Requests)**: Carries memory write payloads and read requests. Can be backpressured by downstream FIFOs.
- **VC1 (High Priority - Responses)**: Carries memory read responses and barrier synchronization tokens. Strictly prioritized at router arbiters to guarantee protocol deadlock freedom.

---

## 3. Voltage Regulator Specifications & Power Supply Network

A single compute tile draws up to $8.50\text{ W}$ under full 4-core systolic contraction. Power delivery must suppress high di/dt transients.

| Power Supply Rail | Nominal Voltage | Tolerance | Maximum Ripple | Transient Step Limit | Function |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`VDD_TILE`** | **0.75 V** | **$\pm 3.0\%$ ($\pm 22.5\text{ mV}$)** | **$< 15\text{ mV}$** | **$< 15\text{ ns}$ (1A to 11.3A)** | 4x Ara VPUs, TCDM SRAM arrays. |
| **`VDD_NOC`** | **0.75 V** | **$\pm 3.5\%$ ($\pm 26.0\text{ mV}$)** | **$< 12\text{ mV}$** | **$< 20\text{ ns}$** | 5-Port router crossbar and buffers. |
| **`VDD_IVR`** | **1.80 V** | **$\pm 5.0\%$ ($\pm 90.0\text{ mV}$)** | **$< 30\text{ mV}$** | **$< 50\text{ ns}$** | Input to localized buck power stages. |

### Decoupling & Inrush Current Staggering
1. **8-Cycle Staggered Power-Up**: The tile controller waits 8 clock cycles ($4.0\text{ ns}$) between enabling Core 0, Core 1, Core 2, and Core 3. This reduces the peak inrush di/dt by $75\%$ compared to simultaneous turn-on.
2. **On-Tile Decoupling Capacitor Grid**: A dense metal-insulator-metal (MIM) capacitor mesh is routed on metal layers M7-M9 directly above the TCDM SRAM arrays ($120\text{ nF/mm}^2$).
3. **Emergency Power Abort (`pdn_abort_i`)**: Asserting this line engages a hardware clamp that disconnects all arithmetic functional units within **1 clock cycle** ($500\text{ ps}$), preventing catastrophic thermal runaway.
