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
        MAX_VAL_BITS : integer := 49
    );

    port (
        clk     : in std_logic;
        en      : in std_logic;
        done    : out std_logic;
        weights : in std_logic_vector(26*NUM_TAPS - 1 downto 0);
        x       : in std_logic_vector(18 - 1 downto 0); -- Note: please check in the diagram whether x is meant to sample 32 or 64
        y       : out std_logic_vector(31 downto 0)
        -- Note: I am aware the system is limited to 32 bits reads for the speaker
        -- Just for reference, sum of 32, 18 x 26 bit multiplications would require at most 49 bits (32 * (2^18 - 1)(2^26 -1) is our MAX)
        -- This means on average we want the weight values and what not to hopefully remain under 13 and 22 bits (although this is largely unexpected)
    );
end adaptive_fir_filter;

architecture Behavioral of adaptive_fir_filter is
    
    COMPONENT mult_gen_1
    PORT (
        CLK : IN STD_LOGIC;
        A : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
        B : IN STD_LOGIC_VECTOR(25 DOWNTO 0);
        CE : IN STD_LOGIC;
        P : OUT STD_LOGIC_VECTOR(43 DOWNTO 0) 
    );
    END COMPONENT;

    type weights_sig_t is array (0 to NUM_TAPS - 1) of signed (25 downto 0);
    -- type x_sig_t      is array (0 to NUM_TAPS - 1) of signed (17 downto 0);
    -- type convol_mult_sig_t is array (0 to NUM_TAPS - 1) of signed (43 downto 0);
    constant MAX_VAL : signed(MAX_VAL_BITS - 1 downto 0) := resize(signed'(x"7FFFFFFF"), MAX_VAL_BITS);  -- +2^31 - 1
    constant MIN_VAL : signed(MAX_VAL_BITS - 1 downto 0) := resize(signed'(x"80000000"), MAX_VAL_BITS);  -- -2^31
    constant MULT_DELAY : integer := 3;

    signal y_sig : std_logic_vector(31 downto 0) := (others => '0');
    signal weights_sig : weights_sig_t;
    signal curr_weight : std_logic_vector(25 downto 0);
    signal x_sig      : std_logic_vector(17 downto 0);  -- x_sig_t
    signal en_sig     : std_logic;
    signal mult_sig   : std_logic_vector(43 downto 0); -- convol_mult_sig_t;
    signal tap_count  : integer range 0 to NUM_TAPS + MULT_DELAY := 0;
    signal running    : std_logic := '0';
    signal sum        : signed(48 downto 0); -- see earlier NOTE in port listing
    signal weight_index : integer range 0 to NUM_TAPS - 1 := 0;
begin
    en_sig <= en;
    x_sig <= x;

    gen_signed_signals : for i in 0 to NUM_TAPS - 1 generate
        -- x_sig(i) <= signed(x((18 * i + 17) downto (18 * i)));  --- Synchronous loading into signed arrays
        weights_sig(i) <= signed(weights(26 * i + 25 downto 26 * i));
    end generate;
    
    curr_weight <= std_logic_vector(weights_sig(weight_index));

    -- gen_convolv_mults: for i in 0 to NUM_TAPS - 1 generate
    dsp_slice_multiplier : mult_gen_1
    port map (
        CLK => clk,
        A => x_sig,
        B => curr_weight,
        CE => '1',   -- just have it always on, we don't count the garbage outputs anyways
        P => mult_sig
    );
    -- end generate;

    FIR_convolve : process (clk)
    begin
        if (rising_edge(clk)) then 
            done <= '0';
            -- Weights is passed in already so multiply them and sum (NOTE will configure multiplier block soon)
            --  for i in 0 to NUM_TAPS - 1 loop
            --    sum := sum + resize(x_sig(NUM_TAPS - 1 - i) * weights_sig(i), 41); -- Allegedly multiplier block is used already in operand multipplication
            -- end loop;
            if running = '0' then  -- We have 3 delay cycles so on the 
                sum <= (others => '0');
                tap_count <= 0;
                weight_index <= 0;
                if en = '1' then
                    running <= '1';
                    tap_count <= 1;
                    weight_index <= 1;
                end if;
            else
                if (weight_index < NUM_TAPS - 1) then
                    weight_index <= weight_index + 1;
                end if;

                if (tap_count >= MULT_DELAY AND tap_count < NUM_TAPS + MULT_DELAY) then
                    sum <= sum + resize(signed(mult_sig), 49);
                end if;

                if tap_count = NUM_TAPS + MULT_DELAY then
                    if (sum >= MAX_VAL) then
                        y_sig <= std_logic_vector(MAX_VAL(31 downto 0));  -- If the sum is larger than 32 bit max we will just peak it
                    elsif (sum <= MIN_VAL) then                           -- yes this will peak the speakers but we shouldn't see this happen too often
                        y_sig <= std_logic_vector(MIN_VAL(31 downto 0));
                    else
                        y_sig <= std_logic_vector(sum(31 downto 0));
                    end if;
                    running <=  '0';
                    done <= '1';
                else
                    tap_count <= tap_count + 1;
                end if;
            end if;
        end if;
    end process;

    y <= y_sig;
        
end Behavioral;
