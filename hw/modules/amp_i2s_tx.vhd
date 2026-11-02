library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;                                -- DC: now needed for the maths

entity amp_i2s_tx is
    port (
        clk       : in std_logic; 
        i2s_bclk  : in std_logic;
        i2s_lrcl  : in std_logic;

        -- (to/from sine_gen)
        din       : in  std_logic_vector(31 downto 0);
        din_stb   : in  std_logic;  

        -- I2S interface to the amp
        amp_din   : out std_logic
    );
end amp_i2s_tx;

architecture Behavioral of amp_i2s_tx is
    constant GAIN      : natural := 0;                   -- 0 = x1, 1 = x2, 2 = x4, 3 = x8
    
--    constant DC_OFFSET : integer := -403000;           -- use if we playing directly from mic
    constant DC_OFFSET : integer := 0;                   -- other wise nmo need

    signal sample   : std_logic_vector(31 downto 0) := (others => '0');
    signal tx_reg   : std_logic_vector(31 downto 0) := (others => '0');
    signal sig_din  : std_logic := '0';
    signal ws_prev  : std_logic := '0';
    signal ws_rise  : std_logic := '0';
begin

    -- DC: remove offset, apply gain, clip
    process(clk)
        variable v : signed(39 downto 0);
    begin
        if rising_edge(clk) then
            if din_stb = '1' then
                v := resize(signed(din(23 downto 0)), 40) - DC_OFFSET;   -- remove DC
                v := shift_left(v, GAIN);                                -- louder
                if v > 8388607 then                                      -- clip to 24-bit range
                    v := to_signed(8388607, 40);
                elsif v < -8388608 then
                    v := to_signed(-8388608, 40);
                end if;
                sample <= std_logic_vector(v(23 downto 0)) & x"00";
            end if;
        end if;
    end process;

    -- read LRCLK in the middle of the bit, when it's stable
    process(i2s_bclk)
    begin
        if rising_edge(i2s_bclk) then
            ws_rise <= i2s_lrcl;
        end if;
    end process;

    amp_din <= sig_din;
    process(i2s_bclk)
    begin
        if falling_edge(i2s_bclk) then
            ws_prev <= ws_rise;
            if (ws_rise /= ws_prev) then
                sig_din <= sample(31);
                tx_reg  <= sample(30 downto 0) & '0';
            else
                sig_din <= tx_reg(31);
                tx_reg  <= tx_reg(30 downto 0) & '0';
            end if;
        end if;
    end process;

end Behavioral;