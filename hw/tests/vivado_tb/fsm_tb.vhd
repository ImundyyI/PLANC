library ieee;
use ieee.std_logic_1164.all;
 
entity fsm_tb is
end entity;

architecture sim of fsm_tb is

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

    constant PERIOD : time := 10ns;

    signal clk      : std_logic := '0';
    signal reset    : std_logic := '0';
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
    signal out_en   : std_logic;

begin

    clk <= not clk after PERIOD / 2;

    fsm: ctrl_fsm port map (
        clk   => clk,
        reset => reset,
        st_done => st_done,
        err_push => err_push,
        ref_push => ref_push,
        lms_done => lms_done,
        ada_done => ada_done,

        fx_en_shift => fx_en_shift,
        fx_en_weight => fx_en_weight,
        st_en       => st_en,
        reg_en      => reg_en,
        rd_sel      => rd_sel,
        out_en      => out_en
    );

    main: process
    begin
        wait for 3*PERIOD;
        reset <= '1';
        wait for 10*PERIOD;
        
        -- move to CALC_FIR state
        err_push <= '1';
        wait for PERIOD;
        err_push <= '0';
        wait for 10*PERIOD;
        
        -- doesnt change state
        ada_done <= '1';
        wait for PERIOD;
        ada_done <= '0';
        wait for 10*PERIOD;

        -- move to WEIGHT_UPDATE state
        st_done <= '1';
        wait for PERIOD;
        st_done <= '0';
        wait for 10*PERIOD;
        
        -- move to IDLE state
        lms_done <= '1';
        wait for PERIOD;
        lms_done <= '0';

        wait;

    end process;

end architecture;