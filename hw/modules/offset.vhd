library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity offset is
    port (
        din     : in std_logic_vector(31 downto 0);
        offset  : in std_logic_vector(31 downto 0);
        dout    : out std_logic_vector(31 downto 0)
        
    );
end entity;


architecture Behavioral of offset is
begin
    dout <= std_logic_vector(unsigned(din) + unsigned(offset));
end architecture;