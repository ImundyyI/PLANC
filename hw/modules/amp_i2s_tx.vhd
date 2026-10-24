----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.10.2026 11:12:23
-- Design Name: 
-- Module Name: amp_i2s_tx - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity amp_i2s_tx is
    port (
        clk       : in  std_logic;                      -- 100 MHz

        -- (to/from sine_gen)
        din       : in  std_logic_vector(15 downto 0);  
        start     : out std_logic;                      -- 1-tick pulse per frame

        -- I2S interface to the amp
        i2s_bclk  : out std_logic;
        i2s_lrcl  : out std_logic;
        amp_din   : out std_logic
    );
end amp_i2s_tx;

architecture Behavioral of amp_i2s_tx is
    signal sig_bclk_count, sig_ws_count : integer := 0;
    signal sig_bclk, sig_ws             : std_logic := '0';

    signal tx_reg   : std_logic_vector(31 downto 0) := (others => '0');
    signal sig_din  : std_logic := '0';
    signal ws_prev  : std_logic := '0';
begin

    -- BCLK generation
    i2s_bclk <= sig_bclk;
    process(clk)
    begin
        if rising_edge(clk) then
            sig_bclk_count <= sig_bclk_count + 1;
            if (sig_bclk_count = 24) then
                sig_bclk_count <= 0;
                sig_bclk <= not sig_bclk;
            end if;
        end if;
    end process;
    
    -- LRCLK generation
    i2s_lrcl <= sig_ws;
    process(sig_bclk)
    begin
        if falling_edge(sig_bclk) then
            sig_ws_count <= sig_ws_count + 1;
            if (sig_ws_count = 31) then
                sig_ws_count <= 0;
                sig_ws <= not sig_ws;
            end if;
        end if;
    end process;
    
    -- din for the amps generation process
    amp_din <= sig_din;
    process(sig_bclk)
    begin
        if (falling_edge(sig_bclk)) then 
            if (sig_ws_count = 0) then
                sig_din <= din(15);
                tx_reg <= din(14 downto 0) & x"0000" & '0';
            else
                sig_din <= tx_reg(31);                        
                tx_reg  <= tx_reg(30 downto 0) & '0';
            end if;
        
        
        end if;
    end process;
    
    
    
    
    -- start pulse generation process
    process(clk)
    begin
        if rising_edge(clk) then
            ws_prev <= sig_ws;
            if (ws_prev = '1' and sig_ws = '0') then
                start <= '1';
            else
                start <= '0';
            end if;
        end if;
    end process;
end Behavioral;
