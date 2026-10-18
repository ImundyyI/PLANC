library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity simple is 
    port (clk   : in std_logic;
          val   : in std_logic;
          led   : out std_logic);

end simple;


architecture simple of simple is
begin
    simple_ff: process(clk)
    begin
        if (rising_edge(clk)) then
            led <= val;
        end if;
    end process simple_ff;
end simple;








