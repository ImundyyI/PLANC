library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.constants.all;

entity audio_pipeline_new is
    port (
        clk                 : in std_logic;
        reset               : in std_logic;
        fifo_wr             : in std_logic;
        fifo_full           : out std_logic;
        fifo_din            : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        --------------------------------------------------
        -- AXI4-Stream
        --------------------------------------------------
        axis_tdata      : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        axis_tvalid     : out std_logic;
        axis_tready     : in  std_logic;
        axis_tlast      : out std_logic
    );

end entity;


architecture Behavioral of audio_pipeline_new is
    component fifo is
        generic (
            DATA_WIDTH : positive := 32;
            FIFO_DEPTH : positive := 12
        );
        port (
            clkw    : in  std_logic; -- asynchronous FIFO.
            clkr    : in  std_logic;
            rst     : in  std_logic;
            wr      : in  std_logic;
            rd      : in  std_logic;
            din     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            empty   : out std_logic;
            full    : out std_logic;
            dout    : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;

    signal sig_fifo_rd    : std_logic;
    signal sig_fifo_dout  : t_fifo_word;
    signal sig_fifo_empty : std_logic;
    signal sig_fifo_full  : std_logic;
    signal sig_fifo_wr    : std_logic;
    signal sig_fifo_din   : t_fifo_word;

    signal sig_axis_tvalid : std_logic;
    signal sig_axis_tready : std_logic;
    signal sig_beat_count  : unsigned(7 downto 0) := (Others => '0');
begin
    fifo_full <= sig_fifo_full;
    sig_fifo_din <= fifo_din;
    -- block writes if the fifo is full. the driver for fifo_wr does not check
    -- if fifo is full or not because the din signal is needed for other things aswell,
    -- so the fifo shouldn't block other system operations.
    sig_fifo_wr <= fifo_wr and not sig_fifo_full;

    INST_FIFO : fifo generic map ( DATA_WIDTH => DATA_WIDTH, FIFO_DEPTH => 5) 
                        port map (
                                    clkw => clk,
                                    clkr => clk,
                                    rst => reset,
                                    wr  => sig_fifo_wr,
                                    rd => sig_fifo_rd,
                                    din => sig_fifo_din,
                                    empty => sig_fifo_empty,
                                    full =>  sig_fifo_full,
                                    dout => sig_fifo_dout
                                );

    sig_axis_tvalid <= not sig_fifo_empty;
    axis_tdata <= sig_fifo_dout;
    -- maintain handshake.
    sig_fifo_rd <= sig_axis_tready and sig_axis_tvalid;

    axis_tvalid <= sig_axis_tvalid;
    sig_axis_tready <= axis_tready;

    -- count the beats until reset occurs.
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                sig_beat_count <= (Others => '0');

            elsif ((sig_axis_tvalid and axis_tready) = '1') then
                sig_beat_count <= sig_beat_count + 1;
            end if;


        end if;

    end process;

    -- let slave know that this the last beat.
    axis_tlast <= '1' when (sig_beat_count = 255) else '0';





end architecture;
