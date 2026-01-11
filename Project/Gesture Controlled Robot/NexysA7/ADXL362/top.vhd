library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    Port (
        CLK100MHZ : in  STD_LOGIC;                       -- Nexys A7 clock
        ACL_MISO  : in  STD_LOGIC;                       -- Master In Slave Out
        ACL_MOSI  : out STD_LOGIC;                       -- Master Out Slave In
        ACL_SCLK  : out STD_LOGIC;                       -- SPI clock
        ACL_CSN   : out STD_LOGIC;                       -- SPI chip select
        LED       : out STD_LOGIC_VECTOR(14 downto 0);   -- LEDs for X[14:10], Y[9:5], Z[4:0]
        SEG       : out STD_LOGIC_VECTOR(6 downto 0);    -- 7 segments of display
        DP        : out STD_LOGIC;                       -- Decimal point of display
        AN        : out STD_LOGIC_VECTOR(7 downto 0)     -- 8 anodes for 7-segment display
    );
end top;

architecture Behavioral of top is

    signal w_4MHz   : STD_LOGIC;                         -- Internal 4 MHz clock
    signal acl_data : STD_LOGIC_VECTOR(14 downto 0);     -- Internal 15-bit accelerometer data

begin

    --------------------------------------------------------------------
    -- Clock generation (iclk_genr)
    --------------------------------------------------------------------
    clock_generation : entity work.iclk_genr
        port map (
            CLK100MHZ => CLK100MHZ,
            clk_4MHz  => w_4MHz
        );

    --------------------------------------------------------------------
    -- SPI master (spi_master)
    --------------------------------------------------------------------
    master : entity work.spi_master
        port map (
            iclk     => w_4MHz,
            miso     => ACL_MISO,
            sclk     => ACL_SCLK,
            mosi     => ACL_MOSI,
            cs       => ACL_CSN,
            acl_data => acl_data
        );

    --------------------------------------------------------------------
    -- 7-segment display control (seg7_control)
    --------------------------------------------------------------------
    display_control : entity work.seg7_control
        port map (
            CLK100MHZ => CLK100MHZ,
            acl_data  => acl_data,
            seg       => SEG,
            dp        => DP,
            an        => AN
        );

    --------------------------------------------------------------------
    -- LEDs showing accelerometer data
    --------------------------------------------------------------------
    LED(14 downto 10) <= acl_data(14 downto 10);   -- X[14:10]
    LED(9  downto 5)  <= acl_data(9  downto 5);    -- Y[9:5]
    LED(4  downto 0)  <= acl_data(4  downto 0);    -- Z[4:0]

end Behavioral;

