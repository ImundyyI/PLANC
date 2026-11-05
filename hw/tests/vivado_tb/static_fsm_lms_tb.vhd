library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants.all;

entity static_fsm_lms_tb is
end static_fsm_lms_tb;

architecture sim of static_fsm_lms_tb is

    constant PERIOD : time := 10ns;
    constant num_bits_out : integer := 26;

    component lms is
        port (
            clk : in std_logic;
            reset : in std_logic;

            est : in std_logic_vector(17 downto 0);
            err : in std_logic_vector(17 downto 0);
            
            fx_en_shift : in std_logic;
            fx_en_weight : in std_logic;

            lms_done : out std_logic;
            weights_out : out std_logic_vector(32*num_bits_out-1 downto 0)
        );
    end component;

    component ctrl_fsm is
        port (
            clk   : in std_logic;
            reset : in std_logic;
            st_done : in std_logic;
            err_push : in std_logic;
            ref_push : in std_logic;
            lms_done : in std_logic;
            ada_done : in std_logic;

            fx_en_shift : out std_logic;
            fx_en_weight : out std_logic;
            st_en       : out std_logic;
            reg_en      : out std_logic;
            rd_sel      : out std_logic;
            out_en      : out std_logic
        );
    end component;

    signal clk      : std_logic := '0';
    signal buf_en   : std_logic := '0';
    signal fir_en   : std_logic := '0';
    signal ref_in   : std_logic_vector(17 downto 0) := (others => '0');
    signal ref_out  : std_logic_vector(17 downto 0);
    signal rd_ptr   : std_logic_vector(M_BITS-1 downto 0);
    signal filtered : std_logic_vector(17 downto 0);
    signal done     : std_logic;

    signal err_in          : std_logic_vector(17 downto 0) := (others => '0');

    signal weights_out  : std_logic_vector(32*num_bits_out-1 downto 0);

    signal st_done  : std_logic := '0';
    signal err_push : std_logic := '0';
    signal ref_push : std_logic := '0';
    signal lms_done : std_logic := '0';
    signal ada_done : std_logic := '0';

    signal fx_en_weight : std_logic;
    signal fx_en_shift  : std_logic;
    signal st_en        : std_logic;
    signal reg_en       : std_logic;
    signal rd_sel       : std_logic;
    signal out_en       : std_logic;

    signal reset        : std_logic := '0';

    signal w0, w1, w2, w3 : signed(25 downto 0);
begin
    clk <= not clk after PERIOD / 2;

    buf: entity work.x_history_buffer
        port map (clk => clk, reset => '1', en => reg_en, rd_ptr => unsigned(rd_ptr),
                  ref_in => ref_in, ref_out => ref_out);

    fir: entity work.static_fir_filter
        port map (clk => clk, en => st_en, ref => ref_out, rd_ptr => rd_ptr,
                  filtered => filtered, done => done);

    fxlms: lms
        port map (
            clk => clk,
            reset   => reset,
            est => filtered,
            err => err_in,
            fx_en_shift => fx_en_shift,
            fx_en_weight    => fx_en_weight,
            lms_done    => lms_done,
            weights_out => weights_out
        );

    fsm: ctrl_fsm
        port map (
            clk => clk,
            reset => reset,
            st_done => done,
            err_push => err_push,
            ref_push => ref_push,
            lms_done => lms_done,
            ada_done => ada_done,

            fx_en_shift => fx_en_shift,
            fx_en_weight => fx_en_weight,
            st_en => st_en,
            reg_en => reg_en,
            rd_sel => rd_sel,
            out_en => out_en
        );

    w0 <= signed(weights_out(num_bits_out-1 downto 0));
    w1 <= signed(weights_out(2*num_bits_out-1 downto num_bits_out));
    w2 <= signed(weights_out(3*num_bits_out-1 downto 2*num_bits_out));
    w3 <= signed(weights_out(4*num_bits_out-1 downto 3*num_bits_out));

    process
    begin
        wait for 3*PERIOD;
        reset <= '1';
        wait for 3*PERIOD;

        -- put 99 in the buffer
        ref_in <= std_logic_vector(to_signed(99, 18));
        ref_push <= '1'; wait for PERIOD; ref_push <= '0'; 
        wait for PERIOD;

        -- put 110 zeros after it, so 99 ends up 110 samples old
        ref_in <= (others => '0');
        for i in 1 to 110 loop
            ref_push <= '1'; wait for PERIOD; ref_push <= '0'; 
            wait for PERIOD;
        end loop;
        
        -- sample 1         w0 = -117
        err_in <= std_logic_vector(to_signed(20000, 18));
        wait for PERIOD;

        err_push <= '1'; ref_push <= '1';
        wait for PERIOD; 
        err_push <= '0'; ref_push <= '0';

        wait until lms_done = '1';
        wait for 5*PERIOD;
        
        -- sample 2         w0 = -156   w1 = -58
        err_in <= std_logic_vector(to_signed(10000, 18));
        wait for PERIOD;
        err_push <= '1'; ref_push <= '1';
        wait for PERIOD; 
        err_push <= '0'; ref_push <= '0';
        
        wait until lms_done = '1';
        wait for 5*PERIOD;
        
        -- sample 3         w0 = -148   w1 = -89    w2 = -46
        err_in <= std_logic_vector(to_signed(8000, 18));
        wait for PERIOD;
        err_push <= '1'; ref_push <= '1';
        wait for PERIOD; 
        err_push <= '0'; ref_push <= '0';
        
        wait until lms_done = '1';
        wait for 5*PERIOD;
        
        -- sample 4         w0 = -130   w1 = -94    w2 = -22    w3 = 36
        -- 99 now 116 old
        for i in 1 to 2 loop
            ref_push <= '1'; wait for PERIOD; ref_push <= '0'; 
            wait for PERIOD;
        end loop;
        
        err_in <= std_logic_vector(to_signed(-6000, 18));
        wait for PERIOD;
        err_push <= '1'; ref_push <= '1';
        wait for PERIOD; 
        err_push <= '0'; ref_push <= '0';

        wait;
    end process;
end sim;