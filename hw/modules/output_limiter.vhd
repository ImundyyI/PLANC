library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity output_limiter is
    generic (
        max_val : integer := 110000;
        min_val : integer := -110000
    );
    port (
        clk : in std_logic;
        
        din : in std_logic_vector(31 downto 0);
        dout    : out std_logic_vector(31 downto 0)
    );
end output_limiter;

architecture Behavioral of output_limiter is
    
begin

    process(clk)
    begin
        dout <= din;
        if to_integer(signed(din)) > max_val then
            dout <= std_logic_vector(to_signed(max_val, 32));
        elsif to_integer(signed(din)) < min_val then
            dout <= std_logic_vector(to_signed(min_val, 32));
        end if;
    end process;

end Behavioral;