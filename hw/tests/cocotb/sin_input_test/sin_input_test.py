import cocotb;

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, ReadOnly

# async def bclk_gen(ref_clk, out_clk, psc):
#     # must switch halfway through its period (to scale by a certain value)
#     val = 0
#     out_clk.value = val
#     # integer divide the prescalar to maintain int type.
#     switch_at_cycle = psc // 2
#     while True:
#         await ClockCycles(ref_clk, switch_at_cycle)
#         # XOR with 1 to invert the clk signal.
#         val ^= 1
#         out_clk.value = val

async def lrcl_gen(ref_clk, out_clk, psc):
    val = 0
    out_clk.value = val
    switch = psc // 2
    while True:
        for i in range(32):
            await FallingEdge(ref_clk)
        val ^= 1
        out_clk.value = val
@cocotb.test()
async def run(dut):
    cocotb.start_soon(Clock(dut.bclk, 320, unit="ns").start())
    cocotb.start_soon(lrcl_gen(dut.bclk, dut.lrcl, 64))
    for i in range(31):
        await FallingEdge(dut.bclk)
    # checks it toggles every 32 falling edges of BCLK.
    assert(dut.lrcl.value == 0), f"expected 32 cycles"
    await FallingEdge(dut.bclk)
    await ReadOnly()
    assert(dut.lrcl.value == 1), f"expected 32 cycles"
    await ClockCycles(dut.bclk, 128)