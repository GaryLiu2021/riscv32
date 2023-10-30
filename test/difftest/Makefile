# Init directory
wave_dir=./wave/
src_dir=../../vsrc

# Verilog srcs
VERILOG_VSRCS = $(src_dir)/*.v
VERILOG_TOP = sim

# Verilator flags
VERILATOR_FLAGS = --timing -Wno-fatal -Wall -cc -exe -build --trace

# Verilator include
VERILATOR_INC = -I$(src_dir)

# Verilator wrapper file
VERILATOR_CSRCS = main.cc

# C compiler flags
REPO_PATH = ./spike-diff/repo
inc_dependencies = fesvr riscv disasm customext fdt softfloat spike_main spike_dasm build
INC_PATH = -I$(REPO_PATH) $(addprefix -I$(REPO_PATH)/, $(inc_dependencies))
# INC_PATH += -I$(NEMU_HOME)/include

lib_dir = ./spike-diff/build
lib_name = riscv32-spike-so

CFLAGS = -CFLAGS "$(INC_PATH) -L$(lib_dir) -l$(lib_name) -g"

TESTCASE_DIR = ../case

.PHONY: sim lib gdb

sim: lib

	@$(MAKE) -C $(TESTCASE_DIR) -f test.mk

	verilator $(VERILATOR_FLAGS) $(VERILATOR_INC) $(VERILOG_VSRCS) --top-module $(VERILOG_TOP) $(VERILATOR_CSRCS) $(CFLAGS)
	@echo "\n\n\tSimulation Begin!\n\n"
	./obj_dir/V$(VERILOG_TOP) > log.txt
	@echo "\n\n\tSimulation Finished!\n\n"
	mkdir -p $(wave_dir)
	mv -i -v *.vcd $(wave_dir)

lib:
	make -s -C ./spike-diff GUEST_ISA=riscv32 SHARE=1 ENGINE=interpreter

gdb: sim
	gdb ./obj_dir/V$(VERILOG_TOP)
