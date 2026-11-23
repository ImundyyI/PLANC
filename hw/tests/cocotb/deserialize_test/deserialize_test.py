import cocotb;
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge
from cocotb.clock import Clock

async def log_dins(dut):
    old = 0
    while True:
        await RisingEdge(dut.w_stb)
        # shouldn't be any 1's in the first 6 bits.
        err_val = dut.err_din.value.to_signed()
        ref_val = dut.ref_din.value.to_signed()
        
        assert(err_val & 0x2f == 0)
        assert(err_val == ref_val)
        err_val = err_val >> 6
        ref_val = ref_val >> 6
        # print values
        cocotb.log.info(f"e: {err_val}, r: {ref_val}")
        

@cocotb.test()
async def test(dut):
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    cocotb.start_soon(log_dins(dut))    
    await ClockCycles(dut.clk, 800000)

