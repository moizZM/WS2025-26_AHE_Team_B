library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_master is
    Port (
        iclk     : in  STD_LOGIC;                       -- 4 MHz input clock
        miso     : in  STD_LOGIC;                       -- Master In Slave Out
        sclk     : out STD_LOGIC;                       -- SPI clock (1 MHz)
        mosi     : out STD_LOGIC;                       -- Master Out Slave In
        cs       : out STD_LOGIC;                       -- Chip Select
        acl_data : out STD_LOGIC_VECTOR(14 downto 0)    -- 15-bit accelerometer data
    );
end spi_master;

architecture Behavioral of spi_master is

    --------------------------------------------------------------------
    -- Internal signals
    --------------------------------------------------------------------
    signal sclk_control : STD_LOGIC := '0';

    signal clk_counter  : STD_LOGIC := '0';
    signal clk_reg      : STD_LOGIC := '1';

    -- SPI parameters
    signal write_instr   : STD_LOGIC_VECTOR(7 downto 0) := x"0A";
    signal mode_reg_addr : STD_LOGIC_VECTOR(7 downto 0) := x"2D";
    signal mode_wr_data  : STD_LOGIC_VECTOR(7 downto 0) := x"02";
    signal read_instr    : STD_LOGIC_VECTOR(7 downto 0) := x"0B";
    signal x_LSB_addr    : STD_LOGIC_VECTOR(7 downto 0) := x"0E";

    signal temp_DATA : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
    signal X, Y, Z   : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

    signal counter   : UNSIGNED(31 downto 0) := (others => '0');

    signal latch_data : STD_LOGIC;

    -- State machine type
    type state_type is (
        POWER_UP,
        BEGIN_SPIW,
        SEND_WCMD7, SEND_WCMD6, SEND_WCMD5, SEND_WCMD4,
        SEND_WCMD3, SEND_WCMD2, SEND_WCMD1, SEND_WCMD0,
        SEND_WADDR7, SEND_WADDR6, SEND_WADDR5, SEND_WADDR4,
        SEND_WADDR3, SEND_WADDR2, SEND_WADDR1, SEND_WADDR0,
        SEND_BYTE7, SEND_BYTE6, SEND_BYTE5, SEND_BYTE4,
        SEND_BYTE3, SEND_BYTE2, SEND_BYTE1, SEND_BYTE0,
        X_WAIT,
        BEGIN_SPIR,
        SEND_RCMD7, SEND_RCMD6, SEND_RCMD5, SEND_RCMD4,
        SEND_RCMD3, SEND_RCMD2, SEND_RCMD1, SEND_RCMD0,
        SEND_RADDR7, SEND_RADDR6, SEND_RADDR5, SEND_RADDR4,
        SEND_RADDR3, SEND_RADDR2, SEND_RADDR1, SEND_RADDR0,
        REC_XLSB7, REC_XLSB6, REC_XLSB5, REC_XLSB4,
        REC_XLSB3, REC_XLSB2, REC_XLSB1, REC_XLSB0,
        REC_XMSB7, REC_XMSB6, REC_XMSB5, REC_XMSB4,
        REC_XMSB3, REC_XMSB2, REC_XMSB1, REC_XMSB0,
        REC_YLSB7, REC_YLSB6, REC_YLSB5, REC_YLSB4,
        REC_YLSB3, REC_YLSB2, REC_YLSB1, REC_YLSB0,
        REC_YMSB7, REC_YMSB6, REC_YMSB5, REC_YMSB4,
        REC_YMSB3, REC_YMSB2, REC_YMSB1, REC_YMSB0,
        REC_ZLSB7, REC_ZLSB6, REC_ZLSB5, REC_ZLSB4,
        REC_ZLSB3, REC_ZLSB2, REC_ZLSB1, REC_ZLSB0,
        REC_ZMSB7, REC_ZMSB6, REC_ZMSB5, REC_ZMSB4,
        REC_ZMSB3, REC_ZMSB2, REC_ZMSB1, REC_ZMSB0,
        END_SPI
    );

    signal state_reg : state_type := POWER_UP;

    -- registered outputs
    signal mosi_reg : STD_LOGIC := '0';
    signal cs_reg   : STD_LOGIC := '1';

begin

    mosi <= mosi_reg;
    cs   <= cs_reg;

    -- Output accelerometer data
    acl_data <= temp_DATA;

    --------------------------------------------------------------------
    -- Clock division: 4 MHz -> 1 MHz (CPOL as in original)
    --------------------------------------------------------------------
    clk_div : process(iclk)
    begin
        if rising_edge(iclk) then
            clk_counter <= not clk_counter;
            if clk_counter = '1' then
                clk_reg <= not clk_reg;
            end if;
        end if;
    end process;

    -- sclk generation
    sclk <= clk_reg when sclk_control = '1' else '0';

    --------------------------------------------------------------------
    -- latch_data combinational logic
    --------------------------------------------------------------------
    latch_data <= '1' when (state_reg = END_SPI and
                            counter = to_unsigned(258, counter'length))
                  else '0';

    --------------------------------------------------------------------
    -- Main state machine (posedge iclk)
    --------------------------------------------------------------------
    fsm_proc : process(iclk)
    begin
        if rising_edge(iclk) then
            -- default: increment counter
            counter <= counter + 1;

            case state_reg is

                ----------------------------------------------------------------
                when POWER_UP =>
                    if counter = to_unsigned(23999, counter'length) then  -- 6 ms
                        state_reg <= BEGIN_SPIW;
                    end if;

                ----------------------------------------------------------------
                when BEGIN_SPIW =>
                    if counter = to_unsigned(24001, counter'length) then
                        state_reg <= SEND_WCMD7;
                        cs_reg    <= '0';   -- CS active
                    end if;

                ----------------------------------------------------------------
                -- Write command
                ----------------------------------------------------------------
                when SEND_WCMD7 =>
                    sclk_control <= '1';
                    mosi_reg     <= write_instr(7);
                    if counter = to_unsigned(24005, counter'length) then
                        state_reg <= SEND_WCMD6;
                    end if;

                when SEND_WCMD6 =>
                    mosi_reg <= write_instr(6);
                    if counter = to_unsigned(24009, counter'length) then
                        state_reg <= SEND_WCMD5;
                    end if;

                when SEND_WCMD5 =>
                    mosi_reg <= write_instr(5);
                    if counter = to_unsigned(24013, counter'length) then
                        state_reg <= SEND_WCMD4;
                    end if;

                when SEND_WCMD4 =>
                    mosi_reg <= write_instr(4);
                    if counter = to_unsigned(24017, counter'length) then
                        state_reg <= SEND_WCMD3;
                    end if;

                when SEND_WCMD3 =>
                    mosi_reg <= write_instr(3);
                    if counter = to_unsigned(24021, counter'length) then
                        state_reg <= SEND_WCMD2;
                    end if;

                when SEND_WCMD2 =>
                    mosi_reg <= write_instr(2);
                    if counter = to_unsigned(24025, counter'length) then
                        state_reg <= SEND_WCMD1;
                    end if;

                when SEND_WCMD1 =>
                    mosi_reg <= write_instr(1);
                    if counter = to_unsigned(24029, counter'length) then
                        state_reg <= SEND_WCMD0;
                    end if;

                when SEND_WCMD0 =>
                    mosi_reg <= write_instr(0);
                    if counter = to_unsigned(24033, counter'length) then
                        state_reg <= SEND_WADDR7;
                    end if;

                ----------------------------------------------------------------
                -- Write address
                ----------------------------------------------------------------
                when SEND_WADDR7 =>
                    mosi_reg <= mode_reg_addr(7);
                    if counter = to_unsigned(24037, counter'length) then
                        state_reg <= SEND_WADDR6;
                    end if;

                when SEND_WADDR6 =>
                    mosi_reg <= mode_reg_addr(6);
                    if counter = to_unsigned(24041, counter'length) then
                        state_reg <= SEND_WADDR5;
                    end if;

                when SEND_WADDR5 =>
                    mosi_reg <= mode_reg_addr(5);
                    if counter = to_unsigned(24045, counter'length) then
                        state_reg <= SEND_WADDR4;
                    end if;

                when SEND_WADDR4 =>
                    mosi_reg <= mode_reg_addr(4);
                    if counter = to_unsigned(24049, counter'length) then
                        state_reg <= SEND_WADDR3;
                    end if;

                when SEND_WADDR3 =>
                    mosi_reg <= mode_reg_addr(3);
                    if counter = to_unsigned(24053, counter'length) then
                        state_reg <= SEND_WADDR2;
                    end if;

                when SEND_WADDR2 =>
                    mosi_reg <= mode_reg_addr(2);
                    if counter = to_unsigned(24057, counter'length) then
                        state_reg <= SEND_WADDR1;
                    end if;

                when SEND_WADDR1 =>
                    mosi_reg <= mode_reg_addr(1);
                    if counter = to_unsigned(24061, counter'length) then
                        state_reg <= SEND_WADDR0;
                    end if;

                when SEND_WADDR0 =>
                    mosi_reg <= mode_reg_addr(0);
                    if counter = to_unsigned(24065, counter'length) then
                        state_reg <= SEND_BYTE7;
                    end if;

                ----------------------------------------------------------------
                -- Write data (mode)
                ----------------------------------------------------------------
                when SEND_BYTE7 =>
                    mosi_reg <= mode_wr_data(7);
                    if counter = to_unsigned(24069, counter'length) then
                        state_reg <= SEND_BYTE6;
                    end if;

                when SEND_BYTE6 =>
                    mosi_reg <= mode_wr_data(6);
                    if counter = to_unsigned(24073, counter'length) then
                        state_reg <= SEND_BYTE5;
                    end if;

                when SEND_BYTE5 =>
                    mosi_reg <= mode_wr_data(5);
                    if counter = to_unsigned(24077, counter'length) then
                        state_reg <= SEND_BYTE4;
                    end if;

                when SEND_BYTE4 =>
                    mosi_reg <= mode_wr_data(4);
                    if counter = to_unsigned(24081, counter'length) then
                        state_reg <= SEND_BYTE3;
                    end if;

                when SEND_BYTE3 =>
                    mosi_reg <= mode_wr_data(3);
                    if counter = to_unsigned(24085, counter'length) then
                        state_reg <= SEND_BYTE2;
                    end if;

                when SEND_BYTE2 =>
                    mosi_reg <= mode_wr_data(2);
                    if counter = to_unsigned(24089, counter'length) then
                        state_reg <= SEND_BYTE1;
                    end if;

                when SEND_BYTE1 =>
                    mosi_reg <= mode_wr_data(1);
                    if counter = to_unsigned(24093, counter'length) then
                        state_reg <= SEND_BYTE0;
                    end if;

                when SEND_BYTE0 =>
                    mosi_reg <= mode_wr_data(0);
                    if counter = to_unsigned(24097, counter'length) then
                        state_reg    <= X_WAIT;
                        counter      <= (others => '0');
                        cs_reg       <= '1';
                        sclk_control <= '0';
                    end if;

                ----------------------------------------------------------------
                -- Wait 40ms
                ----------------------------------------------------------------
                when X_WAIT =>
                    if counter = to_unsigned(160002, counter'length) then
                        counter   <= (others => '0');
                        state_reg <= BEGIN_SPIR;
                    end if;

                ----------------------------------------------------------------
                -- Begin read
                ----------------------------------------------------------------
                when BEGIN_SPIR =>
                    if counter = to_unsigned(1, counter'length) then
                        state_reg    <= SEND_RCMD7;
                        cs_reg       <= '0';
                        sclk_control <= '1';
                    end if;

                ----------------------------------------------------------------
                -- Read command
                ----------------------------------------------------------------
                when SEND_RCMD7 =>
                    mosi_reg <= read_instr(7);
                    if counter = to_unsigned(4, counter'length) then
                        state_reg <= SEND_RCMD6;
                    end if;

                when SEND_RCMD6 =>
                    mosi_reg <= read_instr(6);
                    if counter = to_unsigned(8, counter'length) then
                        state_reg <= SEND_RCMD5;
                    end if;

                when SEND_RCMD5 =>
                    mosi_reg <= read_instr(5);
                    if counter = to_unsigned(12, counter'length) then
                        state_reg <= SEND_RCMD4;
                    end if;

                when SEND_RCMD4 =>
                    mosi_reg <= read_instr(4);
                    if counter = to_unsigned(16, counter'length) then
                        state_reg <= SEND_RCMD3;
                    end if;

                when SEND_RCMD3 =>
                    mosi_reg <= read_instr(3);
                    if counter = to_unsigned(20, counter'length) then
                        state_reg <= SEND_RCMD2;
                    end if;

                when SEND_RCMD2 =>
                    mosi_reg <= read_instr(2);
                    if counter = to_unsigned(24, counter'length) then
                        state_reg <= SEND_RCMD1;
                    end if;

                when SEND_RCMD1 =>
                    mosi_reg <= read_instr(1);
                    if counter = to_unsigned(28, counter'length) then
                        state_reg <= SEND_RCMD0;
                    end if;

                when SEND_RCMD0 =>
                    mosi_reg <= read_instr(0);
                    if counter = to_unsigned(32, counter'length) then
                        state_reg <= SEND_RADDR7;
                    end if;

                ----------------------------------------------------------------
                -- Read address
                ----------------------------------------------------------------
                when SEND_RADDR7 =>
                    mosi_reg <= x_LSB_addr(7);
                    if counter = to_unsigned(36, counter'length) then
                        state_reg <= SEND_RADDR6;
                    end if;

                when SEND_RADDR6 =>
                    mosi_reg <= x_LSB_addr(6);
                    if counter = to_unsigned(40, counter'length) then
                        state_reg <= SEND_RADDR5;
                    end if;

                when SEND_RADDR5 =>
                    mosi_reg <= x_LSB_addr(5);
                    if counter = to_unsigned(44, counter'length) then
                        state_reg <= SEND_RADDR4;
                    end if;

                when SEND_RADDR4 =>
                    mosi_reg <= x_LSB_addr(4);
                    if counter = to_unsigned(48, counter'length) then
                        state_reg <= SEND_RADDR3;
                    end if;

                when SEND_RADDR3 =>
                    mosi_reg <= x_LSB_addr(3);
                    if counter = to_unsigned(52, counter'length) then
                        state_reg <= SEND_RADDR2;
                    end if;

                when SEND_RADDR2 =>
                    mosi_reg <= x_LSB_addr(2);
                    if counter = to_unsigned(56, counter'length) then
                        state_reg <= SEND_RADDR1;
                    end if;

                when SEND_RADDR1 =>
                    mosi_reg <= x_LSB_addr(1);
                    if counter = to_unsigned(60, counter'length) then
                        state_reg <= SEND_RADDR0;
                    end if;

                when SEND_RADDR0 =>
                    mosi_reg <= x_LSB_addr(0);
                    if counter = to_unsigned(64, counter'length) then
                        state_reg <= REC_XLSB7;
                    end if;

                ----------------------------------------------------------------
                -- Receive X LSB
                ----------------------------------------------------------------
                when REC_XLSB7 =>
                    X(7) <= miso;
                    if counter = to_unsigned(68, counter'length) then
                        state_reg <= REC_XLSB6;
                    end if;

                when REC_XLSB6 =>
                    X(6) <= miso;
                    if counter = to_unsigned(72, counter'length) then
                        state_reg <= REC_XLSB5;
                    end if;

                when REC_XLSB5 =>
                    X(5) <= miso;
                    if counter = to_unsigned(76, counter'length) then
                        state_reg <= REC_XLSB4;
                    end if;

                when REC_XLSB4 =>
                    X(4) <= miso;
                    if counter = to_unsigned(80, counter'length) then
                        state_reg <= REC_XLSB3;
                    end if;

                when REC_XLSB3 =>
                    X(3) <= miso;
                    if counter = to_unsigned(84, counter'length) then
                        state_reg <= REC_XLSB2;
                    end if;

                when REC_XLSB2 =>
                    X(2) <= miso;
                    if counter = to_unsigned(88, counter'length) then
                        state_reg <= REC_XLSB1;
                    end if;

                when REC_XLSB1 =>
                    X(1) <= miso;
                    if counter = to_unsigned(92, counter'length) then
                        state_reg <= REC_XLSB0;
                    end if;

                when REC_XLSB0 =>
                    X(0) <= miso;
                    if counter = to_unsigned(96, counter'length) then
                        state_reg <= REC_XMSB7;
                    end if;

                ----------------------------------------------------------------
                -- Receive X MSB
                ----------------------------------------------------------------
                when REC_XMSB7 =>
                    X(15) <= miso;
                    if counter = to_unsigned(100, counter'length) then
                        state_reg <= REC_XMSB6;
                    end if;

                when REC_XMSB6 =>
                    X(14) <= miso;
                    if counter = to_unsigned(104, counter'length) then
                        state_reg <= REC_XMSB5;
                    end if;

                when REC_XMSB5 =>
                    X(13) <= miso;
                    if counter = to_unsigned(108, counter'length) then
                        state_reg <= REC_XMSB4;
                    end if;

                when REC_XMSB4 =>
                    X(12) <= miso;
                    if counter = to_unsigned(112, counter'length) then
                        state_reg <= REC_XMSB3;
                    end if;

                when REC_XMSB3 =>
                    X(11) <= miso;
                    if counter = to_unsigned(116, counter'length) then
                        state_reg <= REC_XMSB2;
                    end if;

                when REC_XMSB2 =>
                    X(10) <= miso;
                    if counter = to_unsigned(120, counter'length) then
                        state_reg <= REC_XMSB1;
                    end if;

                when REC_XMSB1 =>
                    X(9) <= miso;
                    if counter = to_unsigned(124, counter'length) then
                        state_reg <= REC_XMSB0;
                    end if;

                when REC_XMSB0 =>
                    X(8) <= miso;
                    if counter = to_unsigned(128, counter'length) then
                        state_reg <= REC_YLSB7;
                    end if;

                ----------------------------------------------------------------
                -- Receive Y LSB
                ----------------------------------------------------------------
                when REC_YLSB7 =>
                    Y(7) <= miso;
                    if counter = to_unsigned(132, counter'length) then
                        state_reg <= REC_YLSB6;
                    end if;

                when REC_YLSB6 =>
                    Y(6) <= miso;
                    if counter = to_unsigned(136, counter'length) then
                        state_reg <= REC_YLSB5;
                    end if;

                when REC_YLSB5 =>
                    Y(5) <= miso;
                    if counter = to_unsigned(140, counter'length) then
                        state_reg <= REC_YLSB4;
                    end if;

                when REC_YLSB4 =>
                    Y(4) <= miso;
                    if counter = to_unsigned(144, counter'length) then
                        state_reg <= REC_YLSB3;
                    end if;

                when REC_YLSB3 =>
                    Y(3) <= miso;
                    if counter = to_unsigned(148, counter'length) then
                        state_reg <= REC_YLSB2;
                    end if;

                when REC_YLSB2 =>
                    Y(2) <= miso;
                    if counter = to_unsigned(152, counter'length) then
                        state_reg <= REC_YLSB1;
                    end if;

                when REC_YLSB1 =>
                    Y(1) <= miso;
                    if counter = to_unsigned(156, counter'length) then
                        state_reg <= REC_YLSB0;
                    end if;

                when REC_YLSB0 =>
                    Y(0) <= miso;
                    if counter = to_unsigned(160, counter'length) then
                        state_reg <= REC_YMSB7;
                    end if;

                ----------------------------------------------------------------
                -- Receive Y MSB
                ----------------------------------------------------------------
                when REC_YMSB7 =>
                    Y(15) <= miso;
                    if counter = to_unsigned(164, counter'length) then
                        state_reg <= REC_YMSB6;
                    end if;

                when REC_YMSB6 =>
                    Y(14) <= miso;
                    if counter = to_unsigned(168, counter'length) then
                        state_reg <= REC_YMSB5;
                    end if;

                when REC_YMSB5 =>
                    Y(13) <= miso;
                    if counter = to_unsigned(172, counter'length) then
                        state_reg <= REC_YMSB4;
                    end if;

                when REC_YMSB4 =>
                    Y(12) <= miso;
                    if counter = to_unsigned(176, counter'length) then
                        state_reg <= REC_YMSB3;
                    end if;

                when REC_YMSB3 =>
                    Y(11) <= miso;
                    if counter = to_unsigned(180, counter'length) then
                        state_reg <= REC_YMSB2;
                    end if;

                when REC_YMSB2 =>
                    Y(10) <= miso;
                    if counter = to_unsigned(184, counter'length) then
                        state_reg <= REC_YMSB1;
                    end if;

                when REC_YMSB1 =>
                    Y(9) <= miso;
                    if counter = to_unsigned(188, counter'length) then
                        state_reg <= REC_YMSB0;
                    end if;

                when REC_YMSB0 =>
                    Y(8) <= miso;
                    if counter = to_unsigned(192, counter'length) then
                        state_reg <= REC_ZLSB7;
                    end if;

                ----------------------------------------------------------------
                -- Receive Z LSB
                ----------------------------------------------------------------
                when REC_ZLSB7 =>
                    Z(7) <= miso;
                    if counter = to_unsigned(196, counter'length) then
                        state_reg <= REC_ZLSB6;
                    end if;

                when REC_ZLSB6 =>
                    Z(6) <= miso;
                    if counter = to_unsigned(200, counter'length) then
                        state_reg <= REC_ZLSB5;
                    end if;

                when REC_ZLSB5 =>
                    Z(5) <= miso;
                    if counter = to_unsigned(204, counter'length) then
                        state_reg <= REC_ZLSB4;
                    end if;

                when REC_ZLSB4 =>
                    Z(4) <= miso;
                    if counter = to_unsigned(208, counter'length) then
                        state_reg <= REC_ZLSB3;
                    end if;

                when REC_ZLSB3 =>
                    Z(3) <= miso;
                    if counter = to_unsigned(212, counter'length) then
                        state_reg <= REC_ZLSB2;
                    end if;

                when REC_ZLSB2 =>
                    Z(2) <= miso;
                    if counter = to_unsigned(216, counter'length) then
                        state_reg <= REC_ZLSB1;
                    end if;

                when REC_ZLSB1 =>
                    Z(1) <= miso;
                    if counter = to_unsigned(220, counter'length) then
                        state_reg <= REC_ZLSB0;
                    end if;

                when REC_ZLSB0 =>
                    Z(0) <= miso;
                    if counter = to_unsigned(224, counter'length) then
                        state_reg <= REC_ZMSB7;
                    end if;

                ----------------------------------------------------------------
                -- Receive Z MSB
                ----------------------------------------------------------------
                when REC_ZMSB7 =>
                    Z(15) <= miso;
                    if counter = to_unsigned(228, counter'length) then
                        state_reg <= REC_ZMSB6;
                    end if;

                when REC_ZMSB6 =>
                    Z(14) <= miso;
                    if counter = to_unsigned(232, counter'length) then
                        state_reg <= REC_ZMSB5;
                    end if;

                when REC_ZMSB5 =>
                    Z(13) <= miso;
                    if counter = to_unsigned(236, counter'length) then
                        state_reg <= REC_ZMSB4;
                    end if;

                when REC_ZMSB4 =>
                    Z(12) <= miso;
                    if counter = to_unsigned(240, counter'length) then
                        state_reg <= REC_ZMSB3;
                    end if;

                when REC_ZMSB3 =>
                    Z(11) <= miso;
                    if counter = to_unsigned(244, counter'length) then
                        state_reg <= REC_ZMSB2;
                    end if;

                when REC_ZMSB2 =>
                    Z(10) <= miso;
                    if counter = to_unsigned(248, counter'length) then
                        state_reg <= REC_ZMSB1;
                    end if;

                when REC_ZMSB1 =>
                    Z(9) <= miso;
                    if counter = to_unsigned(252, counter'length) then
                        state_reg <= REC_ZMSB0;
                    end if;

                when REC_ZMSB0 =>
                    Z(8) <= miso;
                    if counter = to_unsigned(256, counter'length) then
                        cs_reg       <= '1';
                        sclk_control <= '0';
                        state_reg    <= END_SPI;
                    end if;

                ----------------------------------------------------------------
                -- End SPI, wait 10ms
                ----------------------------------------------------------------
                when END_SPI =>
                    if counter = to_unsigned(40259, counter'length) then
                        counter   <= (others => '0');
                        state_reg <= BEGIN_SPIR;
                    end if;

            end case;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Data buffer logic on falling edge
    --------------------------------------------------------------------
    latch_proc : process(iclk)
    begin
        if falling_edge(iclk) then
            if latch_data = '1' then
                -- sign + 4 bits each axis: X[11:7], Y[11:7], Z[11:7]
                temp_DATA <= X(11 downto 7) & Y(11 downto 7) & Z(11 downto 7);
            end if;
        end if;
    end process;

end Behavioral;

