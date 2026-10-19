library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_pipeline is
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
        clk: in std_logic;
        rst: in std_logic;

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
end audio_pipeline;

architecture Behavioural of audio_pipeline is
    component i2s_master is
        generic (
        DATA_WIDTH : natural := 32;
        PCM_PRECISION : natural := 18
    );
    port (
        clk             : in  std_logic;

        -- I2S interface to MEMs mic
        i2s_lrcl        : out std_logic;    -- left/riight clk (word sel): 0 = left, 1 = right
        i2s_dout        : in  std_logic;    -- serial data: payload, msb first
        i2s_bclk        : out std_logic;    -- Bit clock: freq = sample rate * bits per channel * number of channels
                                            -- (should run at 2-4MHz). Changes when the next bit is ready.
        -- FIFO interface to MEMs mic
        fifo_din        : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        fifo_w_stb      : out std_logic;    -- Write strobe: 1 = ready to write, 0 = busy
        fifo_full       : in  std_logic     -- 1 = not full, 0 = full
    );

    end component;

    component fifo is 
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

    end component;

    component ctrl_bus is
        generic (
        ------------------------------------------------
        -- AXI4-Lite parameters
        ------------------------------------------------

        -- Width of the AXI data bus.
        -- This implementation requires a 32-bit data bus.
        C_S_AXI_DATA_WIDTH : integer := 32;

        -- Width of the AXI address bus
        C_S_AXI_ADDR_WIDTH : integer := 5
    );
    port (
        ------------------------------------------------
        -- Control-bus register interfaces
        ------------------------------------------------

        -- Control register output to the application logic
        cb_control_reg : out std_logic_vector(
            C_S_AXI_DATA_WIDTH - 1 downto 0
        );

        -- Status register input from the application logic
        cb_status_reg : in std_logic_vector(
            C_S_AXI_DATA_WIDTH - 1 downto 0
        );

        -- Gain register output to the application logic
        cb_gain_reg : out std_logic_vector(
            C_S_AXI_DATA_WIDTH - 1 downto 0
        );

        ------------------------------------------------
        -- AXI4-Lite interface
        ------------------------------------------------

        -- Global AXI clock
        S_AXI_ACLK : in std_logic;

        -- Global active-low AXI reset
        S_AXI_ARESETN : in std_logic;

        -- Write address issued by the AXI master
        S_AXI_AWADDR : in std_logic_vector(
            C_S_AXI_ADDR_WIDTH - 1 downto 0
        );

        -- Write-channel protection attributes
        S_AXI_AWPROT : in std_logic_vector(2 downto 0);

        -- Indicates that the write address is valid
        S_AXI_AWVALID : in std_logic;

        -- Indicates that the slave is ready to accept the write address
        S_AXI_AWREADY : out std_logic;

        -- Write data issued by the AXI master
        S_AXI_WDATA : in std_logic_vector(
            C_S_AXI_DATA_WIDTH - 1 downto 0
        );

        -- Write strobes indicating which byte lanes contain valid data
        S_AXI_WSTRB : in std_logic_vector(
            (C_S_AXI_DATA_WIDTH / 8) - 1 downto 0
        );

        -- Indicates that the write data is valid
        S_AXI_WVALID : in std_logic;

        -- Indicates that the slave is ready to accept the write data
        S_AXI_WREADY : out std_logic;

        -- Write-response status
        S_AXI_BRESP : out std_logic_vector(1 downto 0);

        -- Indicates that the write response is valid
        S_AXI_BVALID : out std_logic;

        -- Indicates that the master is ready to accept the write response
        S_AXI_BREADY : in std_logic;

        -- Read address issued by the AXI master
        S_AXI_ARADDR : in std_logic_vector(
            C_S_AXI_ADDR_WIDTH - 1 downto 0
        );

        -- Read-channel protection attributes
        S_AXI_ARPROT : in std_logic_vector(2 downto 0);

        -- Indicates that the read address is valid
        S_AXI_ARVALID : in std_logic;

        -- Indicates that the slave is ready to accept the read address
        S_AXI_ARREADY : out std_logic;

        -- Read data returned by the AXI slave
        S_AXI_RDATA : out std_logic_vector(
            C_S_AXI_DATA_WIDTH - 1 downto 0
        );

        -- Read-response status
        S_AXI_RRESP : out std_logic_vector(1 downto 0);

        -- Indicates that the read data and response are valid
        S_AXI_RVALID : out std_logic;

        -- Indicates that the master is ready to accept the read response
        S_AXI_RREADY : in std_logic
    );


    end component;
    --------------------------------------------------
    -- FIFO
    --------------------------------------------------
    signal sig_fifo_rst             : std_logic;
    signal sig_fifo_wr              : std_logic;
    signal sig_fifo_rd              : std_logic;
    signal sig_fifo_full            : std_logic;
    signal sig_fifo_empty           : std_logic;
    signal sig_fifo_data_w          : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sig_fifo_data_r          : std_logic_vector(DATA_WIDTH-1 downto 0);

    --------------------------------------------------
    -- AXI4-Stream
    --------------------------------------------------
    signal sig_axis_tdata           : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sig_axis_tvalid          : std_logic;
    signal sig_axis_tready          : std_logic;
    signal sig_axis_tlast           : std_logic;

    --------------------------------------------------
    -- Control interface (AXI4-Lite)
    --------------------------------------------------
    signal sig_control_reg          : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sig_status_reg           : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sig_gain_reg             : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    sig_status_reg <= x"0ca7cafe";
    --------------------------------------------------
    -- Control bus
    --------------------------------------------------
    inst_ctrl_bus : ctrl_bus
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
        cb_control_reg  => sig_control_reg,
        cb_status_reg   => sig_status_reg,
        cb_gain_reg     => sig_gain_reg,

		S_AXI_ACLK	    => s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	    => s00_axi_wdata,
		S_AXI_WSTRB	    => s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	    => s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	    => s00_axi_rdata,
		S_AXI_RRESP	    => s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

    -- active low.
    sig_fifo_rst <= rst;

    --------------------------------------------------
    -- I2S Master
    --------------------------------------------------
    inst_i2s_master : i2s_master
    generic map (
        DATA_WIDTH      => DATA_WIDTH,
        PCM_PRECISION   => PCM_PRECISION
    )
    port map (
        clk             => clk,

        i2s_lrcl        => i2s_lrcl,
        i2s_dout        => i2s_dout,
        i2s_bclk        => i2s_bclk,

        fifo_din        => sig_fifo_data_w,
        fifo_w_stb      => sig_fifo_wr,
        fifo_full       => sig_fifo_full
    );

    --------------------------------------------------
    -- FIFO
    --------------------------------------------------
    inst_fifo : fifo 
    generic map (
        data_width => DATA_WIDTH,
        fifo_depth => FIFO_DEPTH
    ) port map (
        clkw            => clk,
        clkr            => clk,
        rst             => sig_fifo_rst,

        wr              => sig_fifo_wr,
        din             => sig_fifo_data_w,
        full            => sig_fifo_full,

        rd              => sig_fifo_rd,
        dout            => sig_fifo_data_r,
        empty           => sig_fifo_empty
    );

    --------------------------------------------------
    -- FIFO-to-AXI4-Stream interface
    --------------------------------------------------
    -- Assert TVALID whenever the FIFO contains at least one audio sample.
    sig_axis_tvalid <= '1' when sig_fifo_empty = '0' else '0';
    -- FIFO read
    sig_fifo_rd <= sig_axis_tvalid and axis_tready;

    axis_tvalid <= sig_axis_tvalid;
    
    -- Assert TLAST on every 256th successful AXI4-Stream transfer.
    -- The counter advances only when both TVALID and TREADY are asserted.
    process (clk)
        variable v_cnt : integer := 0;
    begin
        if (rst = '0') then
            v_cnt := 0;
        elsif rising_edge(clk) then
            if ((sig_axis_tvalid and axis_tready) = '1') then
                v_cnt := v_cnt + 1;
                
                if (v_cnt = 256) then
                    axis_tlast <= '1';
                    v_cnt := 0;
                else
                    axis_tlast <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Continuously present the current FIFO output on TDATA.
    -- The value is transferred only when both TVALID and TREADY are high.
    axis_tdata <= sig_fifo_data_r;
    

end Behavioural;