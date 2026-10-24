----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.10.2026 10:58:53
-- Design Name: 
-- Module Name: sine_gen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sine_gen is

  Port ( 
    clk             : in std_logic;
    start           : in std_logic;
    
    dout            : out std_logic_vector(15 downto 0)
    
  );
end sine_gen;

architecture Behavioral of sine_gen is
    -- one cycle of a sine, 104 samples (300 Hz at 31.25 kHz), 16-bit signed
    -- assuming LRCLK of amps is 31.25kHz
    type memory_type is array (0 to 103) of integer range -32768 to 32767;
    constant sine : memory_type := (
             0,   1978,   3950,   5906,   7842,   9748,  11619,  13448,
         15228,  16952,  18614,  20208,  21729,  23170,  24526,  25794,
         26967,  28041,  29014,  29880,  30638,  31283,  31815,  32230,
         32528,  32707,  32767,  32707,  32528,  32230,  31815,  31283,
         30638,  29880,  29014,  28041,  26967,  25794,  24526,  23170,
         21729,  20208,  18614,  16952,  15228,  13448,  11619,   9748,
          7842,   5906,   3950,   1978,      0,  -1978,  -3950,  -5906,
         -7842,  -9748, -11619, -13448, -15228, -16952, -18614, -20208,
        -21729, -23170, -24526, -25794, -26967, -28041, -29014, -29880,
        -30638, -31283, -31815, -32230, -32528, -32707, -32767, -32707,
        -32528, -32230, -31815, -31283, -30638, -29880, -29014, -28041,
        -26967, -25794, -24526, -23170, -21729, -20208, -18614, -16952,
        -15228, -13448, -11619,  -9748,  -7842,  -5906,  -3950,  -1978
    );
    
    signal i : integer range 0 to 103 := 0;
begin
     process(clk)
    begin
        if rising_edge(clk) then
            if start = '1' then        
                if i = 103 then
                    i <= 0;
                else
                    i <= i + 1;
                end if;
            end if;
        end if;
    end process;

    -- change the shift to divide the magnitude if we want louder or quierter since wave
    dout <= std_logic_vector(shift_right(to_signed(sine(i), 16), 5));

end Behavioral;
