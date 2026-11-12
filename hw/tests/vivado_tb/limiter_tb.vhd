library ieee;
use ieee.std_logic_1164.all;
 
entity limiter_tb is
end entity;

architecture sim of limiter_tb is

    constant PERIOD : time := 10ns;

    component output_limiter is
        port (
            clk : in std_logic;
            
            din : in std_logic_vector(31 downto 0);
            dout    : out std_logic_vector(31 downto 0)
        );
    end component;

    signal clk  : std_logic := '0';

    signal din  : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
    signal dout  : std_logic_vector(31 downto 0);

begin

    clk <= not clk after PERIOD / 2;

    limit: output_limiter port map (
        clk => clk,
        
        din => din,
        dout => dout
    );

    main: process
    begin
        wait for 3*PERIOD;

        din <= "00000000000000000000000000000000";

        wait for 3*PERIOD;

        -- 64
        din <= "00000000000000000000000001000000";

        wait for 3*PERIOD;

        -- 110,001
        din <= "00000000000000011010110110110001";

        wait for 3*PERIOD;

        -- 300,000
        din <= "00000000000000110000110101000000";

        wait for 3*PERIOD;

        -- -64
        din <= "11111111111111111111111111000000";

        wait for 3*PERIOD;

        -- -110,001
        din <= "11111111111111100101001001001111";

        wait for 3*PERIOD;

        -- -300,000
        din <= "11111111111110110110110000100000";
        
        wait;
    end process;

end architecture;