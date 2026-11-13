library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity output_limiter is
    generic (
        max_val : integer := 110000;
        min_val : integer := -110000
    );
    port (
        din : in std_logic_vector(31 downto 0);
        dout    : out std_logic_vector(31 downto 0);
        sat     : out std_logic
    );
end output_limiter;

architecture Behavioral of output_limiter is
    
begin

    -- acts as a MUX based on comparator result of din. prevents it from getting too big and potentially blowing
    -- out the speakers.
    dout <= std_logic_vector(to_signed(max_val, 32)) when (to_integer(signed(din)) > max_val) else
            std_logic_vector(to_signed(min_val, 32)) when (to_integer(signed(din)) < min_val) else
            din;
    sat <= '1' when ((to_integer(signed(din)) > max_val) or (to_integer(signed(din)) < min_val)) else '0';
    -- process(clk)
    -- begin
    --     dout <= din;
    --     if to_integer(signed(din)) > max_val then
    --         dout <= std_logic_vector(to_signed(max_val, 32));
    --     elsif to_integer(signed(din)) < min_val then
    --         dout <= std_logic_vector(to_signed(min_val, 32));
    --     end if;
    -- end process;

end Behavioral;