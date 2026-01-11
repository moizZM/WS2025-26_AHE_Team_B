library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity iclk_genr is
    Port (
        CLK100MHZ : in  STD_LOGIC;     -- 100 MHz input clock
        clk_4MHz  : out STD_LOGIC      -- Generated ~4 MHz clock
    );
end iclk_genr;

architecture Behavioral of iclk_genr is

    signal counter : unsigned(4 downto 0) := (others => '0'); -- 5-bit counter
    signal clk_reg : STD_LOGIC := '1';                       -- internal clock toggle
begin

    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then

            if counter = 12 then
                clk_reg <= not clk_reg;        -- toggle at 12
            end if;

            if counter = 24 then
                clk_reg <= not clk_reg;        -- toggle again at 24
                counter <= (others => '0');    -- reset counter
            else
                counter <= counter + 1;        -- increment counter
            end if;

        end if;
    end process;

    clk_4MHz <= clk_reg;

end Behavioral;

