library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity general_reg is
    generic (
        N : integer := 32
    );
    port (
        clk   : in std_logic;
        reset : in std_logic;
        en    : in std_logic;
        din   : in std_logic_vector(N - 1 downto 0);
        dout  : out std_logic_vector(N - 1 downto 0)
    );
end entity;

architecture Behavioral of general_reg is
begin
    process(clk, reset)
    begin
        if (reset = '0') then
            dout <= (Others => '0');
        elsif (rising_edge(clk)) then
            if (en = '1') then
                dout <= din;
            end if;
        end if;
    end process;

end architecture;