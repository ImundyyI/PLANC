SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl

MODULES := $(abspath $(CURDIR)/../../../../modules)

# Packages first, then the files that use them, GHDL doesn't sort for you
VHDL_SOURCES += $(MODULES)/constants.vhd
VHDL_SOURCES += $(MODULES)/x_history_buffer.vhd
VHDL_SOURCES += $(MODULES)/wrappers/x_history_wrapper.vhd


COCOTB_TOPLEVEL = x_history_wrapper
COCOTB_TEST_MODULES = history_test_wrapped

EXTRA_ARGS += --std=08
SIM_ARGS += --wave=$(CURDIR)/wave.ghw

include $(shell cocotb-config --makefiles)/Makefile.sim

