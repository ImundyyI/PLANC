library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.constants.all;

entity i2s_master_new is
    port (
        clk         : in std_logic;
        debug       : in std_logic;
        ref_full    : in std_logic;
        err_full    : in std_logic;


        ref_din     : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        ref_w_stb   : out std_logic;
        err_din     : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        err_w_stb   : out std_logic;
        
        i2s_dout    : in std_logic;
        i2s_bclk    : out std_logic;
        i2s_lrcl    : out std_logic;
        i2s_count  : out std_logic_vector(4 downto 0)
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
    signal shift_data       : t_i2s_sample := shift_default;
    signal shift_data_xtend : t_fifo_word;

    -- runs a counter that mimics a ramp signal.
    signal debug_cnt : unsigned(DATA_WIDTH - 1 downto 0) := (Others => '0');

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
                shift_data <= shift_data(22 downto 0) & i2s_dout;
--                ref_data <= ref_data(22 downto 0) & i2s_dout;
--                err_data <= err_data(22 downto 0) & i2s_dout;
                if (bit_count = 24) then
                    if (ws = '0') then
                        err_push <= '1';
                        if (debug = '1') then
                            err_din <= std_logic_vector(debug_cnt);
                        else
                            err_din <= shift_data_xtend;


                        end if;
                    else
                        ref_push <= '1';
                        if (debug = '1') then
                            ref_din <= std_logic_vector(debug_cnt);
                        else
                            ref_din <= shift_data_xtend;
                        end if;
                    end if;

                elsif (bit_count = 31) then
                    shift_data <= shift_default;
                end if;  
            end if;
        end if;
    end process;

    COUNTER : process (clk) 
    begin
        if (rising_edge(clk)) then
            if (err_push = '1' or ref_push = '1') then 
                debug_cnt <= debug_cnt + 1; 
            end if; 
        end if;
    end process;
    -- activate write strobe if the FIFOs are not full AND we have a valid sample.
    err_w_stb <= err_push and not err_full;
    ref_w_stb <= ref_push and not ref_full;
    
    shift_data_xtend <= (DATA_WIDTH - 1 downto 24 => shift_data(23)) & shift_data;
--    err_din <= shift_data_xtend when (debug = '0') else std_logic_vector(debug_cnt);
--    ref_din <= shift_data_xtend when (debug = '0') else std_logic_vector(debug_cnt);
    i2s_count <= std_logic_vector(bit_count);
end Behavioral;

