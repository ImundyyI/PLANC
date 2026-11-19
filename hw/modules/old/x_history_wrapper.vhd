
-- THIS IS JUST A WRAPPER FOR COCOTB TO TEST WITH M = 16 INSTEAD OF M = 512 CUZ ITS CHUNKY AND HARDER TO READ OTHERWISE.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.constants.all;

entity x_history_wrapper is
    port (
        clk     : in std_logic;
        reset   : in std_logic;
        en      : in std_logic;
        -- this needs to be updated to work with generics.
        rd_ptr  : in unsigned(3 downto 0);
        ref_in  : in std_logic_vector(17 downto 0);
        ref_out : out std_logic_vector(17 downto 0)
    );
end entity;

architecture Behavioral of x_history_wrapper is
    component x_history_buffer is
        generic (
            M : integer := M;
            M_BITS : integer := M_BITS
        );

        port (
            clk     : in std_logic;
            reset   : in std_logic;
            en      : in std_logic;
            -- this needs to be updated to work with generics.
            rd_ptr  : in unsigned(M_BITS - 1 downto 0);
            ref_in  : in std_logic_vector(17 downto 0);
            ref_out : out std_logic_vector(17 downto 0)
        );
    end component;
begin
    INST : x_history_buffer
    generic map (
        M => 16,
        M_BITS => 4
    )
    port map (
        clk => clk,
        reset => reset,
        en => en,
        rd_ptr => rd_ptr,
        ref_in => ref_in,
        ref_out => ref_out
    );

    

end architecture;