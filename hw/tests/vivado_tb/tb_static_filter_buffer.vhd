library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants.all;

entity tb_fir_with_buffer is
end tb_fir_with_buffer;

architecture sim of tb_fir_with_buffer is
    signal clk      : std_logic := '0';
    signal buf_en   : std_logic := '0';
    signal fir_en   : std_logic := '0';
    signal ref_in   : std_logic_vector(17 downto 0) := (others => '0');
    signal ref_out  : std_logic_vector(17 downto 0);
    signal rd_ptr   : std_logic_vector(M_BITS-1 downto 0);
    signal filtered : std_logic_vector(17 downto 0);
    signal done     : std_logic;
begin
    clk <= not clk after 5 ns;

    buf: entity work.x_history_buffer
        port map (clk => clk, reset => '1', en => buf_en, rd_ptr => unsigned(rd_ptr),
                  ref_in => ref_in, ref_out => ref_out);

    fir: entity work.static_fir_filter
        port map (clk => clk, en => fir_en, ref => ref_out, rd_ptr => rd_ptr,
                  filtered => filtered, done => done);

    process
    begin
        wait for 20 ns;

        -- put 99 in the buffer
        ref_in <= std_logic_vector(to_signed(99, 18));
        buf_en <= '1'; wait for 10 ns; buf_en <= '0'; 
        wait for 10 ns;

        -- put 111 zeros after it, so 99 ends up 111 samples old
        ref_in <= (others => '0');
        for i in 1 to 111 loop
            buf_en <= '1'; wait for 10 ns; buf_en <= '0'; 
            wait for 10 ns;
        end loop;

        -- start the FIR                     -> expect filtered = 6
        fir_en <= '1'; 
        wait for 10 ns; 
        fir_en <= '0';

        wait;
    end process;
end sim;