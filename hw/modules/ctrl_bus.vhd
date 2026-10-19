library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl_bus is
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
end ctrl_bus;


architecture arch_imp of ctrl_bus is

    ------------------------------------------------
    -- Internal AXI4-Lite signals
    ------------------------------------------------

    signal axi_awaddr : std_logic_vector(
        C_S_AXI_ADDR_WIDTH - 1 downto 0
    );

    signal axi_awready : std_logic;
    signal axi_wready  : std_logic;

    signal axi_bresp  : std_logic_vector(1 downto 0);
    signal axi_bvalid : std_logic;

    signal axi_araddr : std_logic_vector(
        C_S_AXI_ADDR_WIDTH - 1 downto 0
    );

    signal axi_arready : std_logic;

    signal axi_rdata : std_logic_vector(
        C_S_AXI_DATA_WIDTH - 1 downto 0
    );

    signal axi_rresp  : std_logic_vector(1 downto 0);
    signal axi_rvalid : std_logic;

    ------------------------------------------------
    -- Register-space addressing parameters
    ------------------------------------------------

    -- Byte-address offset for a 32-bit AXI data width.
    --
    -- For a 32-bit data bus, address bits 1 downto 0 select
    -- individual bytes. Register selection therefore begins at bit 2.
    constant ADDR_LSB : integer :=
        (C_S_AXI_DATA_WIDTH / 32) + 1;

    -- Three register-address bits provide eight register addresses.
    constant OPT_MEM_ADDR_BITS : integer := 2;

    ------------------------------------------------
    -- Control-bus register space
    ------------------------------------------------

    signal slv_reg0 : std_logic_vector(
        C_S_AXI_DATA_WIDTH - 1 downto 0
    ); -- Control register, offset 0x00

    signal slv_reg1 : std_logic_vector(
        C_S_AXI_DATA_WIDTH - 1 downto 0
    ); -- Status register, offset 0x04

    signal slv_reg2 : std_logic_vector(
        C_S_AXI_DATA_WIDTH - 1 downto 0
    ); -- Key register, offset 0x08

    signal slv_reg3 : std_logic_vector(
        C_S_AXI_DATA_WIDTH - 1 downto 0
    ); -- Gain register, offset 0x0C

    signal slv_reg4 : std_logic_vector(
        C_S_AXI_DATA_WIDTH - 1 downto 0
    ); -- Reserved register, offset 0x10

    signal slv_reg5 : std_logic_vector(
        C_S_AXI_DATA_WIDTH - 1 downto 0
    ); -- Reserved register, offset 0x14

    signal slv_reg6 : std_logic_vector(
        C_S_AXI_DATA_WIDTH - 1 downto 0
    ); -- Reserved register, offset 0x18

    signal slv_reg7 : std_logic_vector(
        C_S_AXI_DATA_WIDTH - 1 downto 0
    ); -- Reserved register, offset 0x1C

    signal slv_reg_rden : std_logic;
    signal slv_reg_wren : std_logic;

    signal reg_data_out : std_logic_vector(
        C_S_AXI_DATA_WIDTH - 1 downto 0
    );

    -- Enables acceptance of a new write transaction.
    signal aw_en : std_logic;

begin

    ------------------------------------------------
    -- Configuration checks
    ------------------------------------------------

    -- The fixed key value and register implementation currently
    -- require a 32-bit AXI4-Lite data bus.
    assert C_S_AXI_DATA_WIDTH = 32
        report "ctrl_bus requires C_S_AXI_DATA_WIDTH = 32"
        severity failure;

    ------------------------------------------------
    -- AXI interface output assignments
    ------------------------------------------------

    S_AXI_AWREADY <= axi_awready;
    S_AXI_WREADY  <= axi_wready;
    S_AXI_BRESP   <= axi_bresp;
    S_AXI_BVALID  <= axi_bvalid;

    S_AXI_ARREADY <= axi_arready;
    S_AXI_RDATA   <= axi_rdata;
    S_AXI_RRESP   <= axi_rresp;
    S_AXI_RVALID  <= axi_rvalid;

    ------------------------------------------------
    -- Control-bus register assignments
    ------------------------------------------------

    -- Control and gain are written by the AXI master and presented
    -- to the application logic.
    cb_control_reg <= slv_reg0;
    cb_gain_reg    <= slv_reg3;

    -- Status is generated by the application logic and is read-only
    -- from the AXI4-Lite interface.
    slv_reg1 <= cb_status_reg;

    -- Fixed read-only peripheral identification value.
    slv_reg2 <= x"0CA7CAFE";

    ------------------------------------------------
    -- Write-address ready generation
    ------------------------------------------------

    -- This implementation accepts one outstanding write transaction.
    --
    -- The write address is accepted when both the write-address
    -- channel and write-data channel are valid.
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_awready <= '0';
                aw_en       <= '1';

            else
                if (
                    axi_awready = '0' and
                    S_AXI_AWVALID = '1' and
                    S_AXI_WVALID = '1' and
                    aw_en = '1'
                ) then
                    -- Accept a new write transaction.
                    axi_awready <= '1';
                    aw_en       <= '0';

                elsif (
                    S_AXI_BREADY = '1' and
                    axi_bvalid = '1'
                ) then
                    -- The previous write response has been accepted.
                    -- Allow the next write transaction.
                    axi_awready <= '0';
                    aw_en       <= '1';

                else
                    axi_awready <= '0';
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------
    -- Write-address latching
    ------------------------------------------------

    -- Latch the write address when the slave accepts a new write
    -- transaction.
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_awaddr <= (others => '0');

            else
                if (
                    axi_awready = '0' and
                    S_AXI_AWVALID = '1' and
                    S_AXI_WVALID = '1' and
                    aw_en = '1'
                ) then
                    axi_awaddr <= S_AXI_AWADDR;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------
    -- Write-data ready generation
    ------------------------------------------------

    -- Assert axi_wready for one clock cycle when valid write data
    -- and a valid write address are available.
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_wready <= '0';

            else
                if (
                    axi_wready = '0' and
                    S_AXI_WVALID = '1' and
                    S_AXI_AWVALID = '1' and
                    aw_en = '1'
                ) then
                    axi_wready <= '1';
                else
                    axi_wready <= '0';
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------
    -- Slave-register write enable
    ------------------------------------------------

    -- A register write occurs when both the write-address and
    -- write-data handshakes complete.
    slv_reg_wren <=
        axi_wready and
        S_AXI_WVALID and
        axi_awready and
        S_AXI_AWVALID;

    ------------------------------------------------
    -- Memory-mapped register write logic
    ------------------------------------------------

    -- Register map:
    --
    --   0x00: Control register, read/write
    --   0x04: Status register, read-only
    --   0x08: Key register, read-only
    --   0x0C: Gain register, read/write
    --   0x10: Reserved register 0, read/write
    --   0x14: Reserved register 1, read/write
    --   0x18: Reserved register 2, read/write
    --   0x1C: Reserved register 3, read/write
    --
    -- S_AXI_WSTRB controls which byte lanes are updated.
    process (S_AXI_ACLK)
        variable loc_addr :
            std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                slv_reg0 <= (others => '0');
                slv_reg3 <= (others => '0');
                slv_reg4 <= (others => '0');
                slv_reg5 <= (others => '0');
                slv_reg6 <= (others => '0');
                slv_reg7 <= (others => '0');

            else
                loc_addr := axi_awaddr(
                    ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB
                );

                if slv_reg_wren = '1' then
                    case loc_addr is

                        when "000" =>
                            -- Control register, offset 0x00
                            for byte_index in
                                0 to (C_S_AXI_DATA_WIDTH / 8) - 1
                            loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg0(
                                        byte_index * 8 + 7
                                        downto
                                        byte_index * 8
                                    ) <= S_AXI_WDATA(
                                        byte_index * 8 + 7
                                        downto
                                        byte_index * 8
                                    );
                                end if;
                            end loop;

                        when "001" =>
                            -- Status register, offset 0x04.
                            -- Ignore writes because it is read-only.
                            null;

                        when "010" =>
                            -- Key register, offset 0x08.
                            -- Ignore writes because it is read-only.
                            null;

                        when "011" =>
                            -- Gain register, offset 0x0C
                            for byte_index in
                                0 to (C_S_AXI_DATA_WIDTH / 8) - 1
                            loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg3(
                                        byte_index * 8 + 7
                                        downto
                                        byte_index * 8
                                    ) <= S_AXI_WDATA(
                                        byte_index * 8 + 7
                                        downto
                                        byte_index * 8
                                    );
                                end if;
                            end loop;

                        when "100" =>
                            -- Reserved register 0, offset 0x10
                            for byte_index in
                                0 to (C_S_AXI_DATA_WIDTH / 8) - 1
                            loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg4(
                                        byte_index * 8 + 7
                                        downto
                                        byte_index * 8
                                    ) <= S_AXI_WDATA(
                                        byte_index * 8 + 7
                                        downto
                                        byte_index * 8
                                    );
                                end if;
                            end loop;

                        when "101" =>
                            -- Reserved register 1, offset 0x14
                            for byte_index in
                                0 to (C_S_AXI_DATA_WIDTH / 8) - 1
                            loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg5(
                                        byte_index * 8 + 7
                                        downto
                                        byte_index * 8
                                    ) <= S_AXI_WDATA(
                                        byte_index * 8 + 7
                                        downto
                                        byte_index * 8
                                    );
                                end if;
                            end loop;

                        when "110" =>
                            -- Reserved register 2, offset 0x18
                            for byte_index in
                                0 to (C_S_AXI_DATA_WIDTH / 8) - 1
                            loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg6(
                                        byte_index * 8 + 7
                                        downto
                                        byte_index * 8
                                    ) <= S_AXI_WDATA(
                                        byte_index * 8 + 7
                                        downto
                                        byte_index * 8
                                    );
                                end if;
                            end loop;

                        when "111" =>
                            -- Reserved register 3, offset 0x1C
                            for byte_index in
                                0 to (C_S_AXI_DATA_WIDTH / 8) - 1
                            loop
                                if S_AXI_WSTRB(byte_index) = '1' then
                                    slv_reg7(
                                        byte_index * 8 + 7
                                        downto
                                        byte_index * 8
                                    ) <= S_AXI_WDATA(
                                        byte_index * 8 + 7
                                        downto
                                        byte_index * 8
                                    );
                                end if;
                            end loop;

                        when others =>
                            -- No register is selected.
                            -- Clocked registers retain their current values
                            -- when no assignment is made.
                            null;

                    end case;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------
    -- Write-response generation
    ------------------------------------------------

    -- Generate an AXI write response after the write-address and
    -- write-data handshakes complete.
    --
    -- axi_bvalid remains asserted until the master accepts the
    -- response by asserting S_AXI_BREADY.
    --
    -- All writes return the AXI OKAY response.
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_bvalid <= '0';
                axi_bresp  <= "00";

            else
                if (
                    axi_awready = '1' and
                    S_AXI_AWVALID = '1' and
                    axi_wready = '1' and
                    S_AXI_WVALID = '1' and
                    axi_bvalid = '0'
                ) then
                    -- Generate an OKAY write response.
                    axi_bvalid <= '1';
                    axi_bresp  <= "00";

                elsif (
                    axi_bvalid = '1' and
                    S_AXI_BREADY = '1'
                ) then
                    -- Complete the write-response handshake.
                    axi_bvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------
    -- Read-address ready generation and latching
    ------------------------------------------------

    -- Accept one read address only when no previous read response
    -- is pending.
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_arready <= '0';
                axi_araddr  <= (others => '0');

            else
                if (
                    axi_arready = '0' and
                    S_AXI_ARVALID = '1' and
                    axi_rvalid = '0'
                ) then
                    -- Accept and latch the read address.
                    axi_arready <= '1';
                    axi_araddr  <= S_AXI_ARADDR;
                else
                    axi_arready <= '0';
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------
    -- Read-response valid generation
    ------------------------------------------------

    -- Assert axi_rvalid after a read address is accepted.
    --
    -- axi_rvalid remains asserted until the master accepts the
    -- response by asserting S_AXI_RREADY.
    --
    -- All reads return the AXI OKAY response.
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_rvalid <= '0';
                axi_rresp  <= "00";

            else
                if (
                    axi_arready = '1' and
                    S_AXI_ARVALID = '1' and
                    axi_rvalid = '0'
                ) then
                    -- Valid read data and an OKAY response are available.
                    axi_rvalid <= '1';
                    axi_rresp  <= "00";

                elsif (
                    axi_rvalid = '1' and
                    S_AXI_RREADY = '1'
                ) then
                    -- Complete the read-response handshake.
                    axi_rvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------
    -- Slave-register read enable
    ------------------------------------------------

    -- Read the selected register when the read address is accepted
    -- and no previous read response is pending.
    slv_reg_rden <=
        axi_arready and
        S_AXI_ARVALID and
        (not axi_rvalid);

    ------------------------------------------------
    -- Read-address decoder
    ------------------------------------------------

    -- Select the register corresponding to the latched read address.
    process (
        slv_reg0,
        slv_reg1,
        slv_reg2,
        slv_reg3,
        slv_reg4,
        slv_reg5,
        slv_reg6,
        slv_reg7,
        axi_araddr
    )
        variable loc_addr :
            std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
    begin
        loc_addr := axi_araddr(
            ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB
        );

        case loc_addr is
            when "000" =>
                -- Control register, offset 0x00
                reg_data_out <= slv_reg0;

            when "001" =>
                -- Status register, offset 0x04
                reg_data_out <= slv_reg1;

            when "010" =>
                -- Key register, offset 0x08
                reg_data_out <= slv_reg2;

            when "011" =>
                -- Gain register, offset 0x0C
                reg_data_out <= slv_reg3;

            when "100" =>
                -- Reserved register 0, offset 0x10
                reg_data_out <= slv_reg4;

            when "101" =>
                -- Reserved register 1, offset 0x14
                reg_data_out <= slv_reg5;

            when "110" =>
                -- Reserved register 2, offset 0x18
                reg_data_out <= slv_reg6;

            when "111" =>
                -- Reserved register 3, offset 0x1C
                reg_data_out <= slv_reg7;

            when others =>
                reg_data_out <= (others => '0');
        end case;
    end process;

    ------------------------------------------------
    -- Read-data output register
    ------------------------------------------------

    -- Capture the selected register value when a valid read address
    -- is accepted.
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                axi_rdata <= (others => '0');

            else
                if slv_reg_rden = '1' then
                    axi_rdata <= reg_data_out;
                end if;
            end if;
        end if;
    end process;

end arch_imp;
