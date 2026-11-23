library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
library STD;
use STD.TEXTIO.ALL;
 
library work;
use work.constants.all;
 
entity ctrl_tb is
end entity;
 
architecture sim of ctrl_tb is
 
    constant PERIOD     : time    := 10 ns;
    constant NUM_SAMPLES : integer := 600;
    constant NUM_CLKS   : integer := 2000;
 
    signal clk      : std_logic := '0';
    signal reset    : std_logic := '0';
    signal ref_din  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal err_din  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal ref_push : std_logic := '0';
    signal err_push : std_logic := '0';
    signal audio_out : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    signal expected : integer;
    signal sample   : integer;

begin
 
    clk <= not clk after PERIOD / 2;
 
    dut : entity work.ctrl_wrapper
        port map (
            clk       => clk,
            reset     => reset,
            ref_din   => ref_din,
            ref_push  => ref_push,
            err_din   => err_din,
            err_push  => err_push,
            audio_out => audio_out
        );
 
    process
        -- change path to your .txt files
        file r_file : text open read_mode is "...\r_in.txt";
        file e_file : text open read_mode is "...\e_in.txt";
        file y_file : text open read_mode is "...\y_exp.txt";
 
        variable l      : line;
        variable r_val  : integer;
        variable e_val  : integer;
        variable y_val  : integer;
    begin
        wait for 3*PERIOD;
        reset <= '1';
        wait for 3*PERIOD;
 
        -- history buffer entries set to 0
        ref_din <= (others => '0');
        for i in 1 to M loop
            ref_push <= '1'; wait for PERIOD; ref_push <= '0';
            wait for PERIOD;
        end loop;
 
        for n in 1 to NUM_SAMPLES loop
            -- read files, store in r_val, e_val, y_val
            readline(r_file, l);
            read(l, r_val);
            readline(e_file, l);
            read(l, e_val);
            readline(y_file, l);
            read(l, y_val);
            
            expected <= y_val;
            sample <= n;
 
            ref_din <= std_logic_vector(shift_left(to_signed(r_val, DATA_WIDTH), 6));
            err_din <= std_logic_vector(shift_left(to_signed(e_val, DATA_WIDTH), 6));
            wait for PERIOD;
            
            -- push ref/err values
            ref_push <= '1'; err_push <= '1';
            wait for PERIOD;
            ref_push <= '0'; err_push <= '0';
     
            -- wait for a number of clocks, must be enough clocks for system to finish
            wait for (NUM_CLKS - 2) * PERIOD;

        end loop;
 
        wait;
    end process;
 
end architecture;