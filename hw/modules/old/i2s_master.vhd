library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;


-- I2S master interface for the SPH0645LM4H MEMs mic
-- Links:
--   - https://diyi0t.com/i2s-sound-tutorial-for-esp32/
--   - https://cdn-learn.adafruit.com/downloads/pdf/adafruit-i2s-mems-microphone-breakout.pdf
--   - https://cdn-shop.adafruit.com/product-files/3421/i2S+Datasheet.PDF

entity i2s_master is
    generic (
        DATA_WIDTH : natural := 32;
        PCM_PRECISION : natural := 18
    );
    port (
        clk             : in  std_logic;

        -- I2S interface to MEMs mic
        i2s_lrcl        : out std_logic;    -- left/riight clk (word sel): 0 = left, 1 = right
        i2s_dout        : in  std_logic;    -- serial data: payload, msb first
        i2s_bclk        : out std_logic;    -- Bit clock: freq = sample rate * bits per channel * number of channels
                                            -- (should run at 2-4MHz). Changes when the next bit is ready.
        -- FIFO interface to MEMs mic
        fifo_din        : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        fifo_w_stb      : out std_logic;    -- Write strobe: 1 = ready to write, 0 = busy
        fifo_full       : in  std_logic     -- 1 = not full, 0 = full
    );


    
end i2s_master;

architecture Behavioral of i2s_master is
    signal bclk_div     : unsigned(3 downto 0) := (Others => '0');
    signal ws_div       : unsigned(4 downto 0) := (Others => '0');
    signal bclk         : std_logic := '0';
    signal ws           : std_logic := '0';
    -- put your signals here
    constant shift_default : std_logic_vector(23 downto 0) := (Others => '0');
    signal bclk_rise    : std_logic;
    signal bclk_fall    : std_logic;
    signal bit_count    : unsigned(4 downto 0) := (Others => '0');
    signal push_to_f    : std_logic := '0';
    signal shift_data   : std_logic_vector(23 downto 0) := shift_default;   
    
    
begin
    -----------------------------------------------------------------------
    -- hint: write code for bclk clock generator:
    -----------------------------------------------------------------------
    --implementation...:
    -- input clock = 100MHz.
    -- BCLK = 100MHZ / 32 = 3.125MHz.
    -- WS = BCLK / 64 = 48.828 kHz.
    i2s_bclk <= bclk;
    BCLK_GEN : process (clk)
    begin
        if (rising_edge(clk)) then
            bclk_div <= bclk_div + 1;
            if (bclk_div = 15) then
                bclk <= not bclk;
            end if; 
        end if;

    end process;
    
    ------------------------------------------------------------------------
    -- hint: write code for lrcl/ws clock generator:
    ------------------------------------------------------------------------
    --implementation...:
    i2s_lrcl <= ws;
    WS_GEN : process(clk)
    begin   
        if (rising_edge(clk)) then
            -- falling edge of BCLK.
            if (bclk_div = 15 and bclk = '1') then
                ws_div <= ws_div + 1;
                if (ws_div = 31) then
                    ws <= not ws;
                end if;
                
            end if;
        end if;
    end process;
    ------------------------------------------------------------------------
    -- hint: write code for I2S FSM
    ------------------------------------------------------------------------
    --implementation...:
    
    -- count to 24
    -- when it hits 24, upload to the FIFO?
    -- wait another 8, and then restart the process. this will give an interleaved buffer.
    --
    
    bclk_rise <= '1' when (bclk_div = 15 and bclk = '0') else '0';
    bclk_fall <= '1' when (bclk_div = 15 and bclk = '1') else '0';
    
    I2S_FSM : process (clk)
    begin

        -- this shoudl count on the falling edge, since data changes on the rising edge.
        if (rising_edge(clk)) then
            push_to_f <= '0';
            if (bclk_fall = '1') then
                bit_count <= bit_count + 1;
                shift_data <= shift_data(22 downto 0) & i2s_dout;   
                if (bit_count = 23) then
                    push_to_f <= '1';
                elsif (bit_count = 31) then
                    shift_data <= shift_default;
                end if;
            end if; 
        end if;
    
    end process;
    
    fifo_w_stb <= '1' when (push_to_f = '1' and fifo_full = '0') else '0';
    -- sign extend to the M.S.B since the data width is 32 bit.
    fifo_din <= (DATA_WIDTH - 1 downto 24 => shift_data(23))  & shift_data;

    --------------------------------------------------
    -- hint: write code for FIFO data handshake
    --------------------------------------------------
    -- hint: Useful link: https://encyclopedia2.thefreedictionary.com/Hand+shake+signal
    --implementation...:

end Behavioral;
