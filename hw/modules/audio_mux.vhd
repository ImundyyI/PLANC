library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.constants.all;

entity audio_mux is
    port (
        anti_noise      : in std_logic_vector(31 downto 0);
        white_noise     : in std_logic_vector(31 downto 0);
        sel             : in std_logic_vector(1 downto 0);
        dout            : out std_logic_vector(31 downto 0)
    );
end entity;

architecture Behavioral of audio_mux is
begin
    dout <= anti_noise  when (sel = ANTI_NOISE)     else
            white_noise when (sel = WHITE_NOISE)    else
            (Others => '0');
end architecture;