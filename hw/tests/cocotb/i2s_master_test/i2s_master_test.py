import cocotb;
from cocotb.clock import Clock;
from cocotb.triggers import ClockCycles, FallingEdge, Timer, RisingEdge, ValueChange;
from cocotb.utils import get_sim_time

async def check_ws(dut):
    arr = [int("ffffffff", 16), int("11111111", 16), int("44444444", 16), int("22222222", 16)]
    index = 0
    for i in range(8):
        await ValueChange(dut.i2s_lrcl)
        index += 1
        val = arr[i % len(arr)]
        for j in range(32):
            await RisingEdge(dut.i2s_bclk)
            dut.i2s_dout.value = (val >> (31 - j)) & 1

        dut.i2s_dout.value
        dut._log.info(f"Sent {val:#010x} @ time {get_sim_time('ns')} @ index {index}")
    

@cocotb.test()
async def run(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start());
    checker = cocotb.start_soon(check_ws(dut))
    await ClockCycles(dut.clk, 1000)

    await checker
