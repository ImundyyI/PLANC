SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl

MODULES := $(abspath $(CURDIR)/../../../modules)

# Packages first, then the files that use them, GHDL doesn't sort for you
VHDL_SOURCES += $(MODULES)/constants.vhd
VHDL_SOURCES += $(MODULES)/x_history_buffer.vhd


COCOTB_TOPLEVEL = x_history_buffer
COCOTB_TEST_MODULES = shift_register_test

EXTRA_ARGS += --std=08
SIM_ARGS += --wave=$(CURDIR)/wave.ghw

include $(shell cocotb-config --makefiles)/Makefile.sim

