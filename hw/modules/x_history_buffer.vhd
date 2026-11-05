-- maintains x[n], x[n - 1], ..., x[n - M - 1]. i.e the past M samples.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.constants.all;

entity x_history_buffer is
    generic (
        -- THESE MUST BE CORRECT OTHERWISE THE MODULE WILL THROW AN ERROR.
        M : integer := M;
        M_BITS : integer := M_BITS
    );

    port (
        clk     : in std_logic;
        reset   : in std_logic;
        en      : in std_logic;
        rd_ptr  : in unsigned(M_BITS - 1 downto 0);
        ref_in  : in std_logic_vector(17 downto 0);
        ref_out : out std_logic_vector(17 downto 0)
    );
end entity;


architecture Behavioral of x_history_buffer is
    type t_ref_history is array (0 to M - 1) of std_logic_vector(17 downto 0);
    constant ref_default : t_ref_history := (Others => (Others => '0'));
    signal ref_history : t_ref_history := ref_default;

    constant NUM_BITS : integer := integer(ceil(log2(real(M))));
    -- start at maximum value.
    signal sig_wr_ptr : unsigned(NUM_BITS - 1 downto 0) := to_unsigned(M - 1, NUM_BITS);
    signal sig_rd_ptr : unsigned(NUM_BITS - 1 downto 0);
    signal sig_offset : unsigned(NUM_BITS - 1 downto 0) := to_unsigned(M - 1, NUM_BITS);
    signal sig_index : unsigned(NUM_BITS - 1 downto 0);
    signal sig_ref_out : std_logic_vector(17 downto 0);
begin
    -- check that bit widths align and warn if we dont have enough entries in the history.
    assert 2**NUM_BITS = M report "M must be a power of 2, otherwise underflow mechanism will not work" severity FAILURE;
    assert M_BITS = NUM_BITS report "M_BITS mismatch with actual width" severity FAILURE;
    assert M > 1 report "M should be more than 1 entry" severity ERROR;

    sig_rd_ptr <= rd_ptr;
    ref_out <= sig_ref_out;
    -- this denotes the current delay element wanting to be accesssed based on hte index of the most recent value,
    -- and the rd_ptr for selecting older elements.
    -- for example, sig_offset denotes the index of hte most up to date sample x[n]. lets say this is 100.
    -- a rd_ptr of 10 would then give an index of 110, providing x[n - 10].
    sig_index <= sig_rd_ptr + sig_offset;

    -- when we perform a write, we want to select the next slot to write to. we want to decrement
    -- such that older values occur in higher indexes, so we can process x[n], x[n - 1], x[n - 2] as
    -- rd_ptr = 0, 1, 2 etc (i.e incrementally)
    PTR_HANDLER : process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                sig_wr_ptr <= to_unsigned(M - 1, NUM_BITS);
                sig_offset <= to_unsigned(M - 1, NUM_BITS);
            elsif (en = '1') then
                sig_offset <= sig_wr_ptr;
                sig_wr_ptr <= sig_wr_ptr - 1;
            end if;
        end if;
    
    end process;

    -- on a rising edge when en is asserted, this will update the buffer to contain the new 
    -- x[n] provided in ref_in by writing x[n] to wr_ptr. 

    -- NOTE THAT BECAUSE UPDATES AND A NEW REF_OUT OCCUR SIMULTANEOUSLY, CHANGES TO THIS BUFFER
    -- TAKE ONE CYCLE DELAY TO BE REFLECTED IN REF_OUT. IF YOU USE THE VALUE FROM REF_OUT ON
    -- THE SAME RISING EDGE OF EN = '1', IT WILL BE STALE.
    HISTORY_OUTPUT_INPUT : process (clk)
    begin
        if rising_edge(clk) then
            if (en = '1') then
                ref_history(to_integer(sig_wr_ptr)) <= ref_in;
            end if;
            sig_ref_out <= ref_history(to_integer(sig_index));
        end if;
    end process;
end architecture;