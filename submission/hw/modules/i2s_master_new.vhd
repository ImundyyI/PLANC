library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.constants.all;

entity i2s_master_new is
    port (
        clk             : in std_logic;
        ref_full        : in std_logic;
        err_full        : in std_logic;


        ref_din         : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        ref_w_stb       : out std_logic;
        err_din         : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        err_w_stb       : out std_logic;
        
        i2s_ref_dout    : in std_logic;
        i2s_err_dout    : in std_logic;
        i2s_bclk        : out std_logic;
        i2s_lrcl        : out std_logic
    );
end entity;

architecture Behavioral of i2s_master_new is
    
    signal bclk_div         : unsigned(3 downto 0) := (Others => '0');
    signal ws_div           : unsigned(4 downto 0) := (Others => '0');
    signal bclk             : std_logic := '0';
    signal ws               : std_logic := '0';

    -- detects rising and falling edge of bclk signal.
    signal bclk_rise        : std_logic;
    signal bclk_fall        : std_logic;
    signal bit_count        : unsigned(4 downto 0) := (Others => '0');
    signal ref_push         : std_logic := '0';
    signal err_push         : std_logic := '0';

    constant shift_default  : t_i2s_sample := (Others => '0');
    signal err_shift_data   : t_i2s_sample := shift_default;
    signal ref_shift_data   : t_i2s_sample := shift_default;
    signal err_shift_data_xtend : t_fifo_word;
    signal ref_shift_data_xtend : t_fifo_word;



begin
    i2s_bclk <= bclk;
    bclk_rise <= '1' when (bclk_div = 15 and bclk = '0') else '0';
    bclk_fall <= '1' when (bclk_div = 15 and bclk = '1') else '0';

    BCLK_GEN : process (clk)
    begin
        -- used to divide the input clk frequency by 32 to give 3.125MHz.
        if (rising_edge(clk)) then
            bclk_div <= bclk_div + 1;
            if (bclk_div = 15) then
                bclk <= not bclk;
            end if; 
        end if;

    end process;

    -- ws = bclk / 64. invert ws halfway through at count 31.
    i2s_lrcl <= ws;
    WS_GEN : process(clk)
    begin   
        if (rising_edge(clk)) then
            -- falling edge of BCLK.
            if (bclk_fall = '1') then
                ws_div <= ws_div + 1;
                if (ws_div = 31) then
                    ws <= not ws;
                end if;
                
            end if;
        end if;
    end process;



    FSM : process (clk)
    begin
        if (rising_edge(clk)) then
            err_push <= '0'; ref_push <= '0';
            -- sample both microphones on falling edge of bclk.
            if (bclk_fall = '1') then
                bit_count <= bit_count + 1;
                -- shift_data <= shift_data(22 downto 0) & i2s_dout;
                err_shift_data <= err_shift_data(22 downto 0) & i2s_err_dout;
                ref_shift_data <= ref_shift_data(22 downto 0) & i2s_ref_dout;

                -- have to latch on 25th bit count bcuz the final
                -- sign extended state happens on the rising edge producing
                -- the 24th. if we did that on the 24th it would see the old value.
                if (bit_count = 25) then
                    if (ws = '0') then
                        err_push <= '1';
                        ref_push <= '1';
                        err_din <= err_shift_data_xtend;
                        ref_din <= ref_shift_data_xtend;
                    end if;
                -- when we get to the last BCLk, clear vector so
                -- we cna shift the next samples bits in.
                elsif (bit_count = 31) then
                    ref_shift_data <= shift_default;
                    err_shift_data <= shift_default;
                end if;  
            end if;
        end if;
    end process;

    -- activate write strobe if the FIFOs are not full AND we have a valid sample.
    err_w_stb <= err_push;
    ref_w_stb <= ref_push;
    
    -- shift_data_xtend <= (DATA_WIDTH - 1 downto 24 => shift_data(23)) & shift_data;
    err_shift_data_xtend <= (DATA_WIDTH - 1 downto 24 => err_shift_data(23)) & err_shift_data;
    ref_shift_data_xtend <= (DATA_WIDTH - 1 downto 24 => ref_shift_data(23)) & ref_shift_data;
end Behavioral;

