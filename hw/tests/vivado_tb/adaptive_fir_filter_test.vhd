----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.11.2026 02:16:35
-- Design Name: 
-- Module Name: adaptive_fir_filter_test - Behavioral
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
 
entity tb_adaptive_fir_filter is
--  Port ( );
end tb_adaptive_fir_filter;
 
architecture Behavioral of tb_adaptive_fir_filter is
 
    COMPONENT adaptive_fir_filter
    GENERIC (
        NUM_TAPS : integer := 32;
        MAX_VAL_BITS : integer := 49
    );
    PORT (
        clk     : IN STD_LOGIC;
        en      : IN STD_LOGIC;
        done    : OUT STD_LOGIC;
        weights : IN STD_LOGIC_VECTOR(26*32 - 1 DOWNTO 0);
        x       : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
        y       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    END COMPONENT;
 
    constant CLK_PERIOD : time := 10 ns;   -- 100 MHz
    constant NUM_TAPS   : integer := 32;
 
    signal clk_sig     : std_logic := '0';
    signal en_sig      : std_logic := '0';
    signal done_sig    : std_logic;
    signal weights_sig : std_logic_vector(26*NUM_TAPS - 1 downto 0) := (others => '0');
    signal x_sig       : std_logic_vector(17 downto 0) := (others => '0');
    signal y_sig       : std_logic_vector(31 downto 0);
begin
 
    clk_sig <= not clk_sig after CLK_PERIOD / 2;
 
    uut : adaptive_fir_filter
    port map (
        clk     => clk_sig,
        en      => en_sig,
        done    => done_sig,
        weights => weights_sig,
        x       => x_sig,
        y       => y_sig
    );


    adaptive_sim : process
    begin
        for i in 0 to NUM_TAPS - 1 loop
            weights_sig(26 * i + 25 downto 26 * i) <= std_logic_vector(to_signed(i + 1, 26));
        end loop;

        -- simple test 1 + 2 + 3 + 4 + 5 + ..... = 528
        wait until rising_edge(clk_sig);
        en_sig <= '1';
        x_sig <= std_logic_vector(to_signed(1, 18));
        wait until rising_edge(clk_sig);
        en_sig <= '0'; -- the convolution should have started running (like a trigger) anyways
        wait until done_sig = '1';
        wait for 1 ns;  -- can't wait for 10ns bcuz its 100 MHz
        assert(signed(y_sig) = 528) report "Test 1 FAILED!" severity error;

        -- negative number test
        wait until rising_edge(clk_sig);
        en_sig <= '1';
        x_sig <= std_logic_vector(to_signed(-1, 18));
        wait until rising_edge(clk_sig);
        en_sig <= '0'; -- the convolution should have started running (like a trigger) anyways
        wait until done_sig = '1';
        wait for 1 ns;  -- can't wait for 10ns bcuz its 100 MHz
        assert(signed(y_sig) = -528) report "Test 2 FAILED!" severity error;

        -- neagtive weights test
        for i in 0 to NUM_TAPS - 1 loop
            weights_sig(26 * i + 25 downto 26 * i) <= std_logic_vector(to_signed(-(i + 1), 26));
        end loop;

        -- test 1 but with negative weights this time:
        wait until rising_edge(clk_sig);
        en_sig <= '1';
        x_sig <= std_logic_vector(to_signed(1, 18));
        wait until rising_edge(clk_sig);
        en_sig <= '0'; -- the convolution should have started running (like a trigger) anyways
        wait until done_sig = '1';
        wait for 1 ns;  -- can't wait for 10ns bcuz its 100 MHz
        assert(signed(y_sig) = -528) report "Test 3 FAILED!" severity error;

        -- max clipping test 
        for i in 0 to NUM_TAPS - 1 loop
            weights_sig(26 * i + 25 downto 26 * i) <= std_logic_vector(to_signed(2**25 - 1, 26));
        end loop;

        wait until rising_edge(clk_sig);
        en_sig <= '1';
        x_sig <= std_logic_vector(to_signed(131071, 18));
        wait until rising_edge(clk_sig);
        en_sig <= '0'; -- the convolution should have started running (like a trigger) anyways
        wait until done_sig = '1';
        wait for 1 ns;  -- can't wait for 10ns bcuz its 100 MHz
        assert(signed(y_sig) = x"7FFFFFFF") report "Test 4 FAILED!" severity error;

        wait;
    end process;
 
end Behavioral;

