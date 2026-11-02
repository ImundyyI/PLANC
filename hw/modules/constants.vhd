library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package constants is

    constant DATA_WIDTH        : natural := 32;
    constant PCM_PRECISION     : natural := 18;
    constant SAMPLE_WIDTH      : natural := 24;

    constant M : integer := 1024;
    constant M_BITS : integer := integer(ceil(log2(real(M))));
    constant L : integer := 32;
    constant L_BITS : integer := integer(ceil(log2(real(L))));
    
    
    subtype t_fifo_word  is std_logic_vector(DATA_WIDTH - 1 downto 0);
    subtype t_axi_word   is std_logic_vector(DATA_WIDTH - 1 downto 0);
    subtype t_i2s_sample is std_logic_vector(SAMPLE_WIDTH - 1 downto 0);

    type t_ref_history is array (0 to M - 1) of std_logic_vector(17 downto 0);
    constant ref_default : t_ref_history := (Others => (Others => '0'));

end package;