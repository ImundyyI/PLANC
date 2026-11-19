library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity ctrl_wrapper is
    port (
        clk         : in std_logic;
        reset       : in std_logic;

        ref_din     : in std_logic_vector(DATA_WIDTH-1 downto 0);
        ref_push    : in std_logic;
        err_din     : in std_logic_vector(DATA_WIDTH-1 downto 0);
        err_push    : in std_logic;

        audio_out   : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end ctrl_wrapper;

architecture Behavioral of ctrl_wrapper is
    
    -- history buffer signals
    signal hist_en  : std_logic;
    signal rd_ptr   : std_logic_vector(M_BITS-1 downto 0);
    signal ref_out  : std_logic_vector(PCM_PRECISION-1 downto 0);
    signal ref_ext  : std_logic_vector(PCM_PRECISION-1 downto 0);

    -- static FIR signals
    signal st_en    : std_logic;
    signal filtered : std_logic_vector(PCM_PRECISION-1 downto 0);
    signal st_done  : std_logic;

    -- LMS signals
    signal fx_en_weight : std_logic;
    signal fx_en_shift  : std_logic;
    signal lms_done     : std_logic;
    signal weights_out  : std_logic_vector(32*26-1 downto 0);

    -- err_in register
    signal err_in_reg   : std_logic_vector(PCM_PRECISION-1 downto 0);
    signal err_ext      : std_logic_vector(PCM_PRECISION-1 downto 0);

    -- adaptive FIR signals
    signal adpt_done    : std_logic;
    signal adpt_out     : std_logic_vector(DATA_WIDTH-1 downto 0);

    -- fsm signals
    signal out_en       : std_logic;

    -- output register
    signal out_reg      : std_logic_vector(DATA_WIDTH-1 downto 0);
begin

    extract_18_buf : entity work.extract_sample_18
        port map (
            din => ref_din,
            dout => ref_ext
        );

    hist_buf : entity work.x_history_buffer
        port map (
            clk => clk, 
            reset => reset,
            en => hist_en, 
            rd_ptr => unsigned(rd_ptr),
            ref_in => ref_ext, 
            ref_out => ref_out
        );

    static_FIR : entity work.static_fir_filter
        port map (
            clk => clk, 
            en => st_en, 
            ref_in => ref_out, 
            rd_ptr => rd_ptr,
            filtered => filtered, 
            done => st_done
        );
    
    extract_18_err : entity work.extract_sample_18
        port map (
            din => err_din,
            dout => err_ext
        );

    -- holds err_din for lms
    err_reg : entity work.general_reg
        generic map (
            n => PCM_PRECISION
        )
        port map (
            clk => clk,
            reset => reset,
            en => err_push,
            din => err_ext,
            dout => err_in_reg
        );

    lms_module : entity work.lms
        port map (
            clk => clk,
            reset => reset,
            est => filtered,
            err => err_in_reg,
            fx_en_shift => fx_en_shift,
            fx_en_weight => fx_en_weight,
            lms_done => lms_done,
            weights_out => weights_out
        );

    adaptive_FIR : entity work.adaptive_fir_filter
        port map(
            clk => clk,
            en => st_en,
            done => adpt_done,
            weights => weights_out,
            x => ref_out,
            y => adpt_out
        );

    fsm : entity work.ctrl_fsm
        port map (
            clk => clk,
            reset => reset,
            st_done => st_done,
            err_push => err_push,
            ref_push => ref_push,
            lms_done => lms_done,
            ada_done => adpt_done,

            fx_en_shift => fx_en_shift,
            fx_en_weight => fx_en_weight,
            st_en => st_en,
            reg_en => hist_en,
            out_en => out_en
        );

    output_reg : entity work.general_reg
        generic map (
            n => DATA_WIDTH
        )
        port map (
            clk => clk,
            reset => reset,
            en => out_en,
            din => adpt_out,
            dout => out_reg
        );

    audio_out <= out_reg;

end Behavioral;