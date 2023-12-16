# Init directory
WAVE_DIR=./wave
VSRC_DIR=../../vsrc
CASE_DIR = ../../software/case
VINC_DIR = ../../vsrc/include

# Verilator flags
VERILATOR_FLAGS = --timing -Wno-fatal -Wall -cc -exe -build --trace --sv 

# Verilog srcs
VERILOG_VSRCS := $(VSRC_DIR)/*.v
VERILOG_VSRCS += $(VSRC_DIR)/*/*.sv
VERILOG_VSRCS += $(VSRC_DIR)/*/*.v
# Verilog top module
VERILOG_TOP := soc_top
VERILATOR_FLAGS += --top-module $(VERILOG_TOP) 
# Verilator include
VERILATOR_INC := -I$(VINC_DIR)
VERILATOR_FLAGS += $(VERILATOR_INC)
# Verilator macros
VERILATOR_MACROS := -D__VERILATOR__ -D__LOG_ENABLE__
VERILATOR_FLAGS += $(VERILATOR_MACROS)
# Verilator wrapper file
VERILATOR_CSRCS := main.cc
VERILATOR_CFLAGS := -CFLAGS "$(INC_PATH) -L$(lib_dir) -l$(lib_name) -g"

# Reference repo
REPO_PATH = ./spike-diff/repo
DEPS = fesvr riscv disasm customext fdt softfloat spike_main spike_dasm build
INC_PATH += -I$(REPO_PATH) $(addprefix -I$(REPO_PATH)/, $(DEPS))
# INC_PATH += -I$(NEMU_HOME)/include

lib_dir = ./spike-diff/build
lib_name = riscv32-spike-so

ifeq ($(CASE),)
CASES := $(notdir $(wildcard $(CASE_DIR)/*))
else
CASES := $(notdir $(CASE_DIR)/$(CASE))
endif
# $(foreach file,$(CASES),$(eval VERILATOR_CFLAGS += $(CFLAG_TO_ADD)))

# ------------------------------
.PHONY: all lib gdb
all: $(CASES)

$(CASES): lib
	@echo "Compiling test case $@..."
	@$(MAKE) -C $(CASE_DIR)/$@

	@echo "Simulating test case $@..."
	verilator $(VERILATOR_FLAGS) $(VERILOG_VSRCS) $(VERILATOR_CSRCS) $(VERILATOR_CFLAGS)

	@echo "\n\n\tSimulation Begin!\n\n"

	./obj_dir/V$(VERILOG_TOP) $@ | tee log.txt
	mkdir -p $(WAVE_DIR)
	mv -i -v *.vcd $(WAVE_DIR)

	@echo "\nSimulation log has been stored in log.txt."
	@echo "Simulation waveform has been stored in $(WAVE_DIR)."
	@echo "\n\n\tSimulation Finished!\n\n"

lib:
	make -s -C ./spike-diff GUEST_ISA=riscv32 SHARE=1 ENGINE=interpreter

gdb: all
	gdb ./obj_dir/V$(VERILOG_TOP)
