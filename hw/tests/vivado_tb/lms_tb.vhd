library ieee;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;
 
entity lms_tb is
end entity;

architecture sim of lms_tb is
    constant PERIOD : time := 10ns;
    constant TAPS : integer := 32;
    constant STEP : integer := 8;

    component lms is
        generic (
            TAPS : integer := 32
        );
        port (
            clk : in std_logic;
            reset : in std_logic;

            est : in std_logic_vector(17 downto 0);
            err : in std_logic_vector(17 downto 0);
            
            fx_en_shift : in std_logic;
            fx_en_weight : in std_logic;

            lms_done : out std_logic;
            weights_out : out std_logic_vector(TAPS*32-1 downto 0)
        );
    end component;

    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal est          : std_logic_vector(17 downto 0) := (others => '0');
    signal err          : std_logic_vector(17 downto 0) := (others => '0');
    signal fx_en_shift  : std_logic := '0';
    signal fx_en_weight : std_logic;

    signal lms_done     : std_logic;
    signal weights_out  : std_logic_vector(TAPS*32-1 downto 0);

    signal w0, w1, w2, w3 : signed(31 downto 0);

begin

    clk <= not clk after PERIOD / 2;

    fx_en_weight <= lms_done;

    lms_sim : lms 
        generic map (TAPS => TAPS)
        port map (
        clk => clk,
        reset   => reset,
        est => est,
        err => err,
        fx_en_shift => fx_en_shift,
        fx_en_weight    => fx_en_weight,
        lms_done    => lms_done,
        weights_out => weights_out
    );

    w0 <= signed(weights_out(31 downto 0));
    w1 <= signed(weights_out(63 downto 32));
    w2 <= signed(weights_out(95 downto 64));
    w3 <= signed(weights_out(127 downto 96));

    main : process
    begin
        wait for 3*PERIOD;
        reset <= '1';

        wait for 3*PERIOD;

        est <= std_logic_vector(to_signed(1000, 18));
        err <= std_logic_vector(to_signed(2000, 18));
        wait for PERIOD;

        fx_en_shift <= '1';
        wait for PERIOD;
        fx_en_shift <= '0';
        wait for 5*PERIOD;

        est <= std_logic_vector(to_signed(-500, 18));
        err <= std_logic_vector(to_signed(1000, 18));
        wait for PERIOD;

        fx_en_shift <= '1';
        wait for PERIOD;
        fx_en_shift <= '0';
        wait for 5*PERIOD;

        est <= std_logic_vector(to_signed(300, 18));
        err <= std_logic_vector(to_signed(-400, 18));
        wait for PERIOD;

        fx_en_shift <= '1';
        wait for PERIOD;
        fx_en_shift <= '0';
        wait for 5*PERIOD;


        wait;
    end process;

end architecture;