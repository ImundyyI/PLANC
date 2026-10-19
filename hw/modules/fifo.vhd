library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
    generic (
        DATA_WIDTH : positive := 32;
        FIFO_DEPTH : positive := 5
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
end fifo;

architecture arch of fifo is

    type fifo_t is array (0 to 2**FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mem : fifo_t;

    signal rdp, wrp : unsigned(FIFO_DEPTH downto 0) := (others => '0');
    signal int_rdp : unsigned(FIFO_DEPTH-1 downto 0) := (Others => '0');
    signal int_wrp : unsigned(FIFO_DEPTH-1 downto 0) := (Others => '0');
    -- tracks how many slots in the FIFO are currently being used. need extra bit s.t we can count when it is full.
    signal sig_count : unsigned(FIFO_DEPTH downto 0);
    
    signal sig_full : std_logic;
    signal sig_empty : std_logic;
    
begin

    -- NOTE: THIS IS NOT A TRUE ASYNCHRONOUS FIFO, WE WILL NEED TO ADD GRAY ENCODING 
    -- AND SYNCHRONISATION. THIS IS FINE FOR THE SAME CLOCK DOMAIN THO.
    
    -- count how many slots are being used. (write pointer - read pointer).
    sig_count <= wrp - rdp;
    -- when nothing is in it, 
    sig_empty <= '1' when (sig_count = 0) else '0';
    empty <= sig_empty;
    -- when we have hit capacity, assert full.
    sig_full <= '1' when (sig_count = 2**FIFO_DEPTH) else '0';
    full <= sig_full;
    
    dout <= mem(to_integer(int_rdp));
    
    
    -- write synchronoyusly with clkw.
    process (clkw, rst)
    begin
        if (rst = '0') then
            int_wrp <= (Others => '0');
            wrp <= (Others => '0');
        elsif (rising_edge(clkw)) then
            if (wr = '1' and sig_full = '0') then
                mem(to_integer(int_wrp)) <= din;
                -- this should naturally overflow.
                int_wrp <= int_wrp + 1;
                wrp <= wrp + 1;
            end if;
        end if;
    end process;
    
    -- incr rdp synchronously.
    process (clkr, rst)
    begin
        if (rst = '0') then
            int_rdp <= (Others => '0');
            rdp <= (Others => '0');
        elsif (rising_edge(clkr)) then
            if (rd = '1' and sig_empty = '0') then
                int_rdp <= int_rdp + 1;
                rdp <= rdp + 1;     
            end if;
        end if;
    end process;
    
    
   
    
    
    
    
end arch;
