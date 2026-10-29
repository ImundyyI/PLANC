SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl

MODULES := $(abspath $(CURDIR)/../../../modules)

# Packages first, then the files that use them, GHDL doesn't sort for you
VHDL_SOURCES += $(MODULES)/sin_input.vhd

COCOTB_TOPLEVEL = sin_input
COCOTB_TEST_MODULES = sin_input_test

EXTRA_ARGS += --std=08
SIM_ARGS += --vcd=$(CURDIR)/wave.vcd

include $(shell cocotb-config --makefiles)/Makefile.sim

