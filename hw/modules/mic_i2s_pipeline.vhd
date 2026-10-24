library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity amp_pipeline is
    port (
        clk       : in  std_logic;     -- 100 MHz from Zynq pl_clk0

        -- I2S interface to the amp
        i2s_bclk  : out std_logic;
        i2s_lrcl  : out std_logic;
        amp_din   : out std_logic
    );
end amp_pipeline;

architecture Behavioral of amp_pipeline is

    component sine_gen is
        port (
            clk   : in  std_logic;
            start : in  std_logic;
            dout  : out std_logic_vector(15 downto 0)
        );
    end component;

    component amp_i2s_tx is
        port (
            clk      : in  std_logic;
            din      : in  std_logic_vector(15 downto 0);
            start    : out std_logic;
            i2s_bclk : out std_logic;
            i2s_lrcl : out std_logic;
            amp_din  : out std_logic
        );
    end component;

    -- internal wires between the two blocks
    signal sig_start  : std_logic;
    signal sig_sample : std_logic_vector(15 downto 0);

begin

    inst_sine_gen : sine_gen
        port map (
            clk   => clk,
            start => sig_start,      
            dout  => sig_sample      
        );

    inst_amp_i2s_tx : amp_i2s_tx
        port map (
            clk      => clk,
            din      => sig_sample,  
            start    => sig_start,   
            i2s_bclk => i2s_bclk,
            i2s_lrcl => i2s_lrcl,
            amp_din  => amp_din
        );

end Behavioral;