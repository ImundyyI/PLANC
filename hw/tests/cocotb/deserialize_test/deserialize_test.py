import cocotb;
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge
from cocotb.clock import Clock

async def log_dins(dut):
    old = 0
    while True:
        await RisingEdge(dut.w_stb)
        val = int(dut.din.value)
        #assert(val > old)
        cocotb.log.info(f"the sig value is {val >> 6}")
        old = val

@cocotb.test()
async def test(dut):
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    cocotb.start_soon(log_dins(dut))    
    await ClockCycles(dut.clk, 800000)

