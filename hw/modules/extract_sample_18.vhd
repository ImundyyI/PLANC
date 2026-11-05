-- this just extracts the 18-bit sample from a 32-bit value generated as a FIFO word. 
-- used when bridging output from i2s_master into the control system.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity extract_sample_18 is
    port (
        din : in std_logic_vector(31 downto 0);
        dout : out std_logic_vector(17 downto 0)
    );
end entity;

architecture Behavioral of extract_sample_18 is
begin
    -- top 8 bits are sign-extension. bottom 6 bits are just padded with 0.
    dout <= din(23 downto 6);
end architecture;