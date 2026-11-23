SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl

MODULES := $(abspath $(CURDIR)/../../../modules)

# Packages first, then the files that use them, GHDL doesn't sort for you
VHDL_SOURCES += $(MODULES)/extract_sample_18.vhd


COCOTB_TOPLEVEL = extract_sample_18
COCOTB_TEST_MODULES = concat_test

EXTRA_ARGS += --std=08
SIM_ARGS += --wave=$(CURDIR)/wave.ghw

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: custom_clean
custom_clean:
	rm -rf *.o
	rm -rf *.vcd
	rm -rf *.ghw
	rm -rf *.xml
	rm -rf __pycache__/
	find . -maxdepth 1 -type f ! -name "*.*" ! -name "Makefile" ! -name "README*" -executable -delete
	
clean:: custom_clean


