----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 31.10.2026 09:31:25
-- Design Name: 
-- Module Name: Leap_Forward_LFSR - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity leap_forward_LFSR is
  Port ( 
    clk:      in std_logic;
    step:     in std_logic;
    err_din:   in  std_logic_vector(31 downto 0);
        
    dout:       out std_logic_vector(31 downto 0); 
    fifo_word: out std_logic_vector(31 downto 0)
  );
end leap_forward_LFSR;

architecture Behavioral of leap_forward_LFSR is
    signal seed:      std_logic_vector(30 downto 0) := "1010011110011011110011100010101";  
    signal new_bits:  std_logic_vector(15 downto 0);
    signal sign_bits: std_logic_vector(10 downto 0);
begin

    gen: for i in 0 to 15 generate
        new_bits(i) <= seed(i) xor seed(i + 3);
    end generate;

    process(clk)
    begin
        if rising_edge(clk) then
            if step = '1' then
                seed <= new_bits & seed(30 downto 16);    
            end if;
        end if;
    end process;
    
    sign_bits <= (others => seed(30));
    dout      <= sign_bits & seed(30 downto 15) & "00000";

    fifo_word <= err_din(23 downto 8) & seed(30 downto 15);
end Behavioral;
