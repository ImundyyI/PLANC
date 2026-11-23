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
        alt             : in std_logic_vector(31 downto 0);
        err_din         : in std_logic_vector(31 downto 0);
        ref_din         : in std_logic_vector(31 downto 0);
        sel             : in std_logic_vector(2 downto 0);
        dout            : out std_logic_vector(31 downto 0)
    );
end entity;

architecture Behavioral of audio_mux is
    signal err_noise_concat : std_logic_vector(31 downto 0);
    signal ref_noise_concat : std_logic_vector(31 downto 0);
begin
    -- This scales down the err_noise and ref_noise values, by default they start to saturate
    -- the speaker output and sound bad.
    err_noise_concat <= std_logic_vector(shift_right(signed(err_din), 1));
    ref_noise_concat <= std_logic_vector(shift_right(signed(ref_din), 1));
    -- MUX to select output. dout wires directly to amp_i2s_tx.
    dout <= anti_noise      when (sel = ANTI_N)     else
            white_noise     when (sel = WHITE_N)    else
            err_noise_concat         when (sel = ERR_MIC)       else
            ref_noise_concat         when (sel = REF_MIC)       else
            alt;
end architecture;