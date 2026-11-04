import cocotb;
from cocotb.triggers import RisingEdge, ClockCycles, Timer;
from cocotb.clock import Clock;
from cocotb.types import LogicArray, Range;

@cocotb.test()
async def run(dut):
    binary = "00ffffc0"
    vector = LogicArray(int(binary, 16), Range(31, 'downto', 0));
    dut.input.value = vector
    await Timer(10, units="ns")
    # should only extract 1's.
    assert(dut.output.value == LogicArray("1" * 18))

