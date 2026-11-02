----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.11.2026 23:14:47
-- Design Name: 
-- Module Name: adaptive_fir_filter - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adaptive_fir_filter is
    generic (
        NUM_TAPS : integer := 32;
        NUM_X    : integer := 64
    );

    port (
        clk     : in std_logic;
        weights : in std_logic_vector(18*NUM_TAPS - 1 downto 0);
        x       : in std_logic_vector(18*NUM_X - 1 downto 0); -- Note: please check in the diagram whether x is meant to sample 32 or 64
        y       : out std_logic_vector(31 downto 0)
        -- Note: I am aware the system is limited to 32 bits reads for the speaker
        -- Just for reference, sum of 32, 18 x 18 bit multiplications would require at most 41 bits (32 * (2^18 - 1)^2)
        -- For no truncation to happen in any case, the bit widths must sum to 27 bits
        -- This means on average we want the weight values and what not to hopefully remain under 13 bits (although this is largely unexpected)
    );
end adaptive_fir_filter;

architecture Behavioral of adaptive_fir_filter is
    type weights_sig_t is array (0 to NUM_TAPS - 1) of signed (17 downto 0);
    type x_sig_t      is array (0 to NUM_TAPS - 1) of signed (17 downto 0);

    constant MAX_VAL : signed(40 downto 0) := (40 downto 31 => '0', others => '1');  -- +2^31 - 1
    constant MIN_VAL : signed(40 downto 0) := (40 downto 31 => '1', others => '0');  -- -2^31 

    signal y_sig : std_logic_vector(31 downto 0) := (others => '0');
    signal weights_sig : weights_sig_t;
    signal x_sig      : x_sig_t;
begin

    gen_signed_signals : for i in 0 to NUM_TAPS - 1 generate
        x_sig(i) <= signed(x((18 * i + 17) downto (18 * i)));  --- Synchronous loading into signed arrays
        weights_sig(i) <= signed(weights(18 * i + 17 downto 18 * i));
    end generate;

    FIR_convolve : process (clk)
        variable sum : signed(40 downto 0); -- see earlier NOTE in port listing
    begin
        sum := (others => '0');
        if (rising_edge(clk)) then
            -- Weights is passed in already so multiply them and sum (NOTE will configure multiplier block soon)
            for i in 0 to NUM_TAPS - 1 loop
                sum := sum + resize(x_sig(NUM_TAPS - 1 - i) * weights_sig(i), 41); -- Allegedly multiplier block is used already in operand multipplication
            end loop;
            
            if (sum >= MAX_VAL) then
                y_sig <= std_logic_vector(MAX_VAL(31 downto 0));  -- If the sum is larger than 32 bit max we will just peak it
            elsif (sum <= MIN_VAL) then                           -- yes this will peak the speakers but we shouldn't see this happen too often
                y_sig <= std_logic_vector(MIN_VAL(31 downto 0));
            else
                y_sig <= std_logic_vector(sum(31 downto 0));
            end if;

        end if; 
    end process;

    y <= y_sig;
        
end Behavioral;
