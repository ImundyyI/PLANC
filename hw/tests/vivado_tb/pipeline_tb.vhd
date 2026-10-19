----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/12/2026 08:10:14 PM
-- Design Name: 
-- Module Name: pipeline_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pipeline_tb is
--  Port ( );
end pipeline_tb;

architecture Behavioral of pipeline_tb is
    component audio_pipeline is 
        generic(
            PCM_PRECISION : integer := 18;
            PCM_WIDTH : integer := 24;
            DATA_WIDTH : integer := 32;
            FIFO_DEPTH : integer := 12;
            TRANSFER_LEN : integer := 5;
            C_S00_AXI_DATA_WIDTH    : integer	:= 32;
            C_S00_AXI_ADDR_WIDTH	: integer	:= 5
        );
        port(
            clk: in std_logic := '0';
            rst: in std_logic := '0';
    
            --------------------------------------------------
            -- I2S
            --------------------------------------------------
            i2s_bclk        : out std_logic;
            i2s_lrcl        : out std_logic;
            i2s_dout        : in  std_logic;
    
            --------------------------------------------------
            -- AXI4-Stream
            --------------------------------------------------
            axis_tdata      : out std_logic_vector(DATA_WIDTH-1 downto 0);
            axis_tvalid     : out std_logic;
            axis_tready     : in  std_logic;
            axis_tlast      : out std_logic;
            
            --------------------------------------------------
            -- Control interface (AXI4-Lite)
            --------------------------------------------------
            s00_axi_aclk	: in  std_logic;
            s00_axi_aresetn	: in  std_logic;
            s00_axi_awaddr	: in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
            s00_axi_awprot	: in  std_logic_vector(2 downto 0);
            s00_axi_awvalid	: in  std_logic;
            s00_axi_awready	: out std_logic;
            s00_axi_wdata	: in  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
            s00_axi_wstrb	: in  std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
            s00_axi_wvalid	: in  std_logic;
            s00_axi_wready	: out std_logic;
            s00_axi_bresp	: out std_logic_vector(1 downto 0);
            s00_axi_bvalid	: out std_logic;
            s00_axi_bready	: in  std_logic;
            s00_axi_araddr	: in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
            s00_axi_arprot	: in  std_logic_vector(2 downto 0);
            s00_axi_arvalid	: in  std_logic;
            s00_axi_arready	: out std_logic;
            s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
            s00_axi_rresp	: out std_logic_vector(1 downto 0);
            s00_axi_rvalid	: out std_logic;
            s00_axi_rready	: in  std_logic
        );
    
    end component;
    
    constant PCM_PRECISION  : integer := 18;
    constant PCM_WIDTH      : integer := 24;
    constant DATA_WIDTH     : integer := 32;
    constant FIFO_DEPTH     : integer := 12;
    constant TRANSFER_LEN   : integer := 5;
    constant C_S00_AXI_DATA_WIDTH    : integer	:= 32;
    constant C_S00_AXI_ADDR_WIDTH	  : integer	:= 5;
    constant CLK_PERIOD : time := 1ns;
    
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    
    
    -- ////// i2s + microphone process emulation //////
    signal sig_bclk : std_logic;
    signal sig_ws   : std_logic;
    signal sig_dout : std_logic := '0';
    signal sig_count : unsigned(1 downto 0) := (Others => '0');
    -- emulates microphone.
    type arr_t is array(0 to 3) of std_logic_vector(23 downto 0);
    constant left_data : arr_t := (X"123400", X"800040", X"7FFFC0", X"FFFFC0");
    constant right_data : arr_t := (X"000040", X"F00080", X"555500", X"AAAA80");
    
    signal sig_ws_prev : std_logic := '0';
    signal sig_shift    : std_logic_vector(23 downto 0) := left_data(0);
    
    -- axis
    signal sig_axis_tdata  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal sig_axis_tvalid : std_logic;
    signal sig_axis_tready : std_logic := '0';
    signal sig_axis_tlast  : std_logic;
    
    -- ignored axi4lite stuff
    signal sig_awaddr   : std_logic_vector(4 downto 0) := (others => '0');
    signal sig_araddr   : std_logic_vector(4 downto 0) := (others => '0');
    signal sig_wdata    : std_logic_vector(31 downto 0) := (others => '0');
    signal sig_wstrb    : std_logic_vector(3 downto 0) := (others => '0');
    signal sig_prot     : std_logic_vector(2 downto 0) := (others => '0');
    
    

begin
--    UUT : audio_pipeline port map (
    -- setup AXI4-Stream handshake
    -- seutp microhpone from i2s tb
    -- ignore AXI4-Lite?
    -- 
    
    UUT : audio_pipeline port map (clk             => clk,
                                   rst             => rst,
                                   i2s_bclk        => sig_bclk,
                                   i2s_lrcl        => sig_ws,
                                   i2s_dout        => sig_dout,
                                   axis_tdata      => sig_axis_tdata,
                                   axis_tvalid     => sig_axis_tvalid,
                                   axis_tready     => sig_axis_tready,
                                   axis_tlast      => sig_axis_tlast,
                                   s00_axi_aclk    => clk,
                                   s00_axi_aresetn => rst,
                                   s00_axi_awaddr  => sig_awaddr,
                                   s00_axi_awprot  => sig_prot,
                                   s00_axi_awvalid => '0',
                                   s00_axi_awready => open,
                                   s00_axi_wdata   => sig_wdata,
                                   s00_axi_wstrb   => sig_wstrb,
                                   s00_axi_wvalid  => '0',
                                   s00_axi_wready  => open,
                                   s00_axi_bresp   => open,
                                   s00_axi_bvalid  => open,
                                   s00_axi_bready  => '1',
                                   s00_axi_araddr  => sig_araddr,
                                   s00_axi_arprot  => sig_prot,
                                   s00_axi_arvalid => '0',
                                   s00_axi_arready => open,
                                   s00_axi_rdata   => open,
                                   s00_axi_rresp   => open,
                                   s00_axi_rvalid  => open,
                                   s00_axi_rready  => '1' );

    MAIN : process
    begin
        wait for CLK_PERIOD / 2;
        clk <= not clk;
        
    end process;
    -- flip between left and right smaples everytime bclk changes sign.
    MICROPHONE : process (sig_bclk)
        variable v_word : std_logic_vector(23 downto 0);
    begin
        if (rising_edge(sig_bclk)) then
            if (sig_ws /= sig_ws_prev) then
                sig_ws_prev <= sig_ws;
                -- output left channel to the master.
                if (sig_ws = '0') then
                    v_word := left_data(to_integer(sig_count));
                else
                    -- output right channel to the master.
                    -- latch right data, and increment count for the next output of left so 
                    -- we get new values.
                    v_word := right_data(to_integer(sig_count));          
                    sig_count <= sig_count + 1;   
                end if;
                -- ensure first shift is done immediately.
                sig_dout <= v_word(23);
                sig_shift <= v_word(22 downto 0) & '0';
            else
                sig_dout <= sig_shift(23);
                sig_shift <= sig_shift(22 downto 0) & '0';
            end if;     
        end if;    
    end process;
    
    TEST : process
    begin
        wait for CLK_PERIOD * 3;
        rst <= '1';
       
        -- wait for samples to fill up in FIFO, then drain by asserting tready.
        wait for 8000 * CLK_PERIOD;
        sig_axis_tready <= '1';
        wait for 20 * CLK_PERIOD;
        sig_axis_tready <= '0';
        wait;
        
        
        
        
        
        
    
    
    end process;
   

end Behavioral;
