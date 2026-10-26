# ==============================================================================
# ARA COMPUTE TILE (CLUSTER + TCDM + NoC + DEFECT BYPASS) MAKEFILE
# ==============================================================================

IVERILOG = iverilog -g2012
VVP = vvp
YOSYS = yosys

RTL_ROUTER = rtl/ara_noc_fifo.sv rtl/ara_noc_mesh_router.sv
RTL_NI = rtl/ara_noc_fifo.sv rtl/ara_noc_ni.sv
RTL_DEFECT = rtl/ara_noc_fifo.sv rtl/ara_noc_defect_bypass.sv

TB_ROUTER = tb/tb_ara_noc_mesh_router.sv
TB_NI = tb/tb_ara_noc_ni.sv
TB_DEFECT = tb/tb_ara_noc_defect_bypass.sv

.PHONY: all sim_router sim_ni sim_defect test synth clean

all: sim_router sim_ni sim_defect

sim_router: $(RTL_ROUTER) $(TB_ROUTER)
	$(IVERILOG) -o sim_router $(RTL_ROUTER) $(TB_ROUTER)

sim_ni: $(RTL_NI) $(TB_NI)
	$(IVERILOG) -o sim_ni $(RTL_NI) $(TB_NI)

sim_defect: $(RTL_DEFECT) $(TB_DEFECT)
	$(IVERILOG) -o sim_defect $(RTL_DEFECT) $(TB_DEFECT)

test: all
	@echo "=== [1/3] RUNNING NoC MESH ROUTER TEST ==="
	$(VVP) sim_router
	@echo "=== [2/3] RUNNING NETWORK INTERFACE (NI) TEST ==="
	$(VVP) sim_ni
	@echo "=== [3/3] RUNNING 1-CYCLE DEFECT BYPASS TEST ==="
	$(VVP) sim_defect

synth:
	$(YOSYS) -p "read_verilog -sv rtl/ara_tcdm_bank_interconnect.sv rtl/ara_noc_mesh_router.sv rtl/ara_noc_fifo.sv rtl/ara_noc_defect_bypass.sv; hierarchy -check -top ara_noc_mesh_router; proc; opt; check -assert"

clean:
	rm -f sim_router sim_ni sim_defect *.vcd
