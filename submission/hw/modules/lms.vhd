library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lms is
    generic (
        TAPS : integer := 32;
        OUT_BITS : integer := 26
    );
    port (
        clk : in std_logic;
        reset : in std_logic;

        est : in std_logic_vector(17 downto 0);
        err : in std_logic_vector(17 downto 0);
        
        fx_en_shift : in std_logic;
        fx_en_weight : in std_logic;

        lms_done : out std_logic;
        weights_out : out std_logic_vector(TAPS*OUT_BITS-1 downto 0)
    );
end lms;

architecture Behavioral of lms is
    
    type shift_arr_t is array (0 to TAPS-1) of signed(17 downto 0);
    type prod_arr_t is array (0 to TAPS-1) of signed(35 downto 0);
    type weight_arr_t is array (0 to TAPS-1) of signed(OUT_BITS-1 downto 0);

    signal shift_arr : shift_arr_t := (others => (others => '0'));
    signal prod_arr : prod_arr_t := (others => (others => '0'));
    signal weight_arr : weight_arr_t := (others => (others => '0'));

    signal done1 : std_logic := '0';
    signal done2 : std_logic := '0';

    constant step_size : integer := 10;
begin

    shift_reg : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                shift_arr <= (others => (others => '0'));
            else
                if fx_en_shift = '1' then
                    shift_arr(0) <= signed(est);
                    for i in 1 to TAPS-1 loop
                        shift_arr(i) <= shift_arr(i - 1);
                    end loop;
                end if;
            end if;

            for i in 0 to TAPS-1 loop
                prod_arr(i) <= shift_arr(i) * signed(err);
            end loop;
        end if;
    end process;

    weight_reg : process(clk)
        variable shift_res : signed(35 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '0' then
                weight_arr <= (others => (others => '0'));
            else
                if fx_en_weight = '1' then
                    for i in 0 to TAPS-1 loop
                        shift_res := shift_right(prod_arr(i), step_size);
                        weight_arr(i) <= weight_arr(i) - resize(shift_res, OUT_BITS);
                    end loop;
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                done1 <= '0';
                done2 <= '0';
            else
                done1 <= fx_en_shift;
                done2 <= done1;
            end if;
        end if;
    end process;

    lms_done <= done2;

    weight_gen : for i in 0 to TAPS-1 generate
        weights_out((i + 1)*OUT_BITS-1 downto i*OUT_BITS) <= std_logic_vector(weight_arr(i));
    end generate;

end Behavioral;