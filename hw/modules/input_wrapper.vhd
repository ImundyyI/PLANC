library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.constants.all;

entity input_wrapper is
    port (
        clk   : in std_logic;
        w_stb : out std_logic;
        din : out std_logic_vector(31 downto 0)

    );
end entity;

architecture Behavioral of input_wrapper is
    component i2s_master_new is
        port (
                clk         : in std_logic;
                ref_full    : in std_logic;
                err_full    : in std_logic;
                debug       : in std_logic;


                ref_din     : out std_logic_vector(DATA_WIDTH - 1 downto 0);
                ref_w_stb   : out std_logic;
                err_din     : out std_logic_vector(DATA_WIDTH - 1 downto 0);
                err_w_stb   : out std_logic;
                
                i2s_dout    : in std_logic;
                i2s_bclk    : out std_logic;
                i2s_lrcl    : out std_logic;
                i2s_count   : out std_logic_vector(4 downto 0)
            );
    end component;

    component sin_input is
        port (  
            bclk : in std_logic;
            lrcl : in std_logic;
            data : out std_logic
        );
    end component;

    signal sig_ref_full         : std_logic := '0';
    signal sig_err_full         : std_logic := '0';
    signal sig_ref_din          : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal sig_ref_w_stb        : std_logic;
    signal sig_err_w_stb        : std_logic;
    signal sig_err_din          : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal sig_i2s_dout         : std_logic;
    signal sig_i2s_bclk         : std_logic;
    signal sig_i2s_lrcl         : std_logic;
    signal sig_i2s_count        : std_logic_vector(4 downto 0);
begin
    IN_INST : sin_input port map (
        bclk => sig_i2s_bclk,
        lrcl => sig_i2s_lrcl,
        data => sig_i2s_dout
    );

    DES_INST : i2s_master_new
    port map (
        clk         => clk,
        debug       => '1',
        ref_full    => sig_ref_full,
        err_full    => sig_err_full,
        ref_din     => sig_ref_din,
        ref_w_stb   => sig_ref_w_stb,
        err_din     => sig_err_din,
        err_w_stb   => sig_err_w_stb,
        i2s_dout    => sig_i2s_dout,
        i2s_bclk    => sig_i2s_bclk,
        i2s_lrcl    => sig_i2s_lrcl,
        i2s_count   => sig_i2s_count
    );

    w_stb <= sig_err_w_stb;
    din <= sig_err_din;

end architecture;

