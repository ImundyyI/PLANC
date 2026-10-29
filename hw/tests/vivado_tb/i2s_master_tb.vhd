library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.constants.all;

entity i2s_master_tb is
end entity;

architecture Behavioral of i2s_master_tb is
    component input_wrapper is 
        port (
            clk   : in std_logic;
            w_stb : out std_logic;
            err_din : out std_logic_vector(31 downto 0);
            ref_din : out std_logic_vector(31 downto 0)
        );

    end component;

    constant PERIOD : TIME := 1ns;
    signal sig_clk : std_logic := '0';
    signal sig_w_stb : std_logic;
    signal sig_err_din : std_logic_vector(31 downto 0);
    signal sig_ref_din : std_logic_vector(31 downto 0);
    signal sig_value   : std_logic_vector(17 downto 0);
begin
    input_wrapper_inst: input_wrapper
     port map(
        clk => sig_clk,
        w_stb => sig_w_stb,
        err_din => sig_err_din,
        ref_din => sig_ref_din
    );

    CLK_GEN: process
    begin
        wait for PERIOD / 2;
        sig_clk <= not sig_clk;
    end process;
    
    sig_value <= sig_err_din(23 downto 6);


end architecture;