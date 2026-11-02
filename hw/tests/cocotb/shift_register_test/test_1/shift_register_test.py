import cocotb;
from cocotb.triggers import RisingEdge, Timer, ClockCycles, FallingEdge;
from cocotb.clock import Clock;
from cocotb.types import LogicArray;
from cocotb.types import Range;

async def check_values(dut):
    values = list(range(530, 0, -1))
    vectors = [LogicArray(val, Range(17, "downto", 0)) for val in values]
    i = 0
    for i in range(len(values)):
        dut.en.value = 1
        dut.ref_in.value = vectors[i]
        dut.rd_ptr.value = 0
        await RisingEdge(dut.clk)
        dut.en.value = 0
        while (dut.ref_out.value != values[i]):
                await RisingEdge(dut.clk)

        # read out all the values.
        for j in range(512):
            dut.rd_ptr.value = j
            await RisingEdge(dut.clk)



    
@cocotb.test()
async def run(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.reset.value = 0
    rd_ptr = 0;
    dut.rd_ptr.value = rd_ptr
    await ClockCycles(dut.clk, 4)
    dut.reset.value = 1
    cocotb.start_soon(check_values(dut))

    await ClockCycles(dut.clk, 40000);