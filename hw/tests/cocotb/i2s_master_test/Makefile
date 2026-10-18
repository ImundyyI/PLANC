SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl

MODULES := $(abspath $(CURDIR)/../../../modules)

# Packages first, then the files that use them, GHDL doesn't sort for you
VHDL_SOURCES += $(MODULES)/i2s_master.vhd

COCOTB_TOPLEVEL = i2s_master
COCOTB_TEST_MODULES = i2s_master_test

EXTRA_ARGS += --std=08
SIM_ARGS += --vcd=$(CURDIR)/wave.vcd

include $(shell cocotb-config --makefiles)/Makefile.sim