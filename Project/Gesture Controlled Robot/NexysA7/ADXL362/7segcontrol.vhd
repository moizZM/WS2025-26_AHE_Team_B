library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seg7_control is
    Port (
        CLK100MHZ : in  STD_LOGIC;                      -- 100 MHz clock
        acl_data  : in  STD_LOGIC_VECTOR(14 downto 0);  -- 15-bit accelerometer data
        seg       : out STD_LOGIC_VECTOR(6 downto 0);   -- 7-seg segments
        dp        : out STD_LOGIC;                      -- decimal point
        an        : out STD_LOGIC_VECTOR(7 downto 0)    -- anodes
    );
end seg7_control;

architecture Behavioral of seg7_control is

    -- Sign bits
    signal x_sign, y_sign, z_sign : STD_LOGIC;

    -- 4-bit data for each axis
    signal x_data, y_data, z_data : UNSIGNED(3 downto 0);

    -- BCD digits (tens and ones)
    signal x_10, x_1 : UNSIGNED(3 downto 0);
    signal y_10, y_1 : UNSIGNED(3 downto 0);
    signal z_10, z_1 : UNSIGNED(3 downto 0);

    -- 7-seg patterns (active-low)
    constant ZERO  : STD_LOGIC_VECTOR(6 downto 0) := "1000000";
    constant ONE   : STD_LOGIC_VECTOR(6 downto 0) := "1111001";
    constant TWO   : STD_LOGIC_VECTOR(6 downto 0) := "0100100";
    constant THREE : STD_LOGIC_VECTOR(6 downto 0) := "0110000";
    constant FOUR  : STD_LOGIC_VECTOR(6 downto 0) := "0011001";
    constant FIVE  : STD_LOGIC_VECTOR(6 downto 0) := "0010010";
    constant SIX   : STD_LOGIC_VECTOR(6 downto 0) := "0000010";
    constant SEVEN : STD_LOGIC_VECTOR(6 downto 0) := "1111000";
    constant EIGHT : STD_LOGIC_VECTOR(6 downto 0) := "0000000";
    constant NINE  : STD_LOGIC_VECTOR(6 downto 0) := "0010000";
    -- ?NULL? ? VHDL ?????????? BLANK
    constant BLANK : STD_LOGIC_VECTOR(6 downto 0) := "1111111";

    -- anode control
    signal anode_select : UNSIGNED(2 downto 0) := (others => '0');
    signal anode_timer  : UNSIGNED(16 downto 0) := (others => '0');

    -- internal registers for outputs
    signal seg_reg : STD_LOGIC_VECTOR(6 downto 0) := BLANK;
    signal dp_reg  : STD_LOGIC := '1';
    signal an_reg  : STD_LOGIC_VECTOR(7 downto 0) := (others => '1');
    


begin

    -- output mapping
    seg <= seg_reg;
    dp  <= dp_reg;
    an  <= an_reg;

    -- Extract sign bits
    x_sign <= acl_data(14);
    y_sign <= acl_data(9);
    z_sign <= acl_data(4);

    -- Extract 4-bit data (as unsigned)
    x_data <= UNSIGNED(acl_data(13 downto 10));
    y_data <= UNSIGNED(acl_data(8  downto 5));
    z_data <= UNSIGNED(acl_data(3  downto 0));

    -- Binary to BCD (4-bit / 10 and mod 10)
    x_10 <= x_data / 10;
    x_1  <= x_data mod 10;
    y_10 <= y_data / 10;
    y_1  <= y_data mod 10;
    z_10 <= z_data / 10;
    z_1  <= z_data mod 10;

    --------------------------------------------------------------------
    -- Anode timing: 1ms per digit, 8 digits ? 8ms refresh
    --------------------------------------------------------------------
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
        
            if anode_timer = 99999 then                -- 100 MHz ? 10 ns
                anode_timer  <= (others => '0');       -- 10 ns * 100000 = 1 ms
                anode_select <= anode_select + 1;
            else
                anode_timer <= anode_timer + 1;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Anode decode
    --------------------------------------------------------------------
    process(anode_select)
    begin
        case anode_select is
            when "000" => an_reg <= "11111110";
            when "001" => an_reg <= "11111101";
            when "010" => an_reg <= "11111011";
            when "011" => an_reg <= "11110111";
            when "100" => an_reg <= "11101111";
            when "101" => an_reg <= "11011111";
            when "110" => an_reg <= "10111111";
            when "111" => an_reg <= "01111111";
            when others => an_reg <= (others => '1');
        end case;
    end process;

    --------------------------------------------------------------------
    -- Segment / DP logic
    --------------------------------------------------------------------
    process(anode_select, x_sign, y_sign, z_sign,
            x_1, x_10, y_1, y_10, z_1, z_10)
    begin
        -- default
        dp_reg  <= '1';
        seg_reg <= BLANK;

        case anode_select is

            -- Z axis, ones digit, show sign in dp
            when "000" =>
                if z_sign = '1' then
                    dp_reg <= '0';   -- ON
                else
                    dp_reg <= '1';   -- OFF
                end if;

                case z_1 is
                    when "0000" => seg_reg <= ZERO;
                    when "0001" => seg_reg <= ONE;
                    when "0010" => seg_reg <= TWO;
                    when "0011" => seg_reg <= THREE;
                    when "0100" => seg_reg <= FOUR;
                    when "0101" => seg_reg <= FIVE;
                    when "0110" => seg_reg <= SIX;
                    when "0111" => seg_reg <= SEVEN;
                    when "1000" => seg_reg <= EIGHT;
                    when "1001" => seg_reg <= NINE;
                    when others => seg_reg <= BLANK;
                end case;

            -- Z axis, tens digit
            when "001" =>
                dp_reg <= '1';  -- OFF
                case z_10 is
                    when "0000" => seg_reg <= ZERO;
                    when "0001" => seg_reg <= ONE;
                    when "0010" => seg_reg <= TWO;
                    when "0011" => seg_reg <= THREE;
                    when "0100" => seg_reg <= FOUR;
                    when "0101" => seg_reg <= FIVE;
                    when "0110" => seg_reg <= SIX;
                    when "0111" => seg_reg <= SEVEN;
                    when "1000" => seg_reg <= EIGHT;
                    when "1001" => seg_reg <= NINE;
                    when others => seg_reg <= BLANK;
                end case;

            -- unused anode
            when "010" =>
                dp_reg  <= '1';
                seg_reg <= BLANK;

            -- Y axis, ones digit, show sign in dp
            when "011" =>
                if y_sign = '1' then
                    dp_reg <= '0';
                else
                    dp_reg <= '1';
                end if;

                case y_1 is
                    when "0000" => seg_reg <= ZERO;
                    when "0001" => seg_reg <= ONE;
                    when "0010" => seg_reg <= TWO;
                    when "0011" => seg_reg <= THREE;
                    when "0100" => seg_reg <= FOUR;
                    when "0101" => seg_reg <= FIVE;
                    when "0110" => seg_reg <= SIX;
                    when "0111" => seg_reg <= SEVEN;
                    when "1000" => seg_reg <= EIGHT;
                    when "1001" => seg_reg <= NINE;
                    when others => seg_reg <= BLANK;
                end case;

            -- Y axis, tens digit
            when "100" =>
                dp_reg <= '1';
                case y_10 is
                    when "0000" => seg_reg <= ZERO;
                    when "0001" => seg_reg <= ONE;
                    when "0010" => seg_reg <= TWO;
                    when "0011" => seg_reg <= THREE;
                    when "0100" => seg_reg <= FOUR;
                    when "0101" => seg_reg <= FIVE;
                    when "0110" => seg_reg <= SIX;
                    when "0111" => seg_reg <= SEVEN;
                    when "1000" => seg_reg <= EIGHT;
                    when "1001" => seg_reg <= NINE;
                    when others => seg_reg <= BLANK;
                end case;

            -- unused anode
            when "101" =>
                dp_reg  <= '1';
                seg_reg <= BLANK;

            -- X axis, ones digit, show sign in dp
            when "110" =>
                if x_sign = '1' then
                    dp_reg <= '0';
                else
                    dp_reg <= '1';
                end if;

                case x_1 is
                    when "0000" => seg_reg <= ZERO;
                    when "0001" => seg_reg <= ONE;
                    when "0010" => seg_reg <= TWO;
                    when "0011" => seg_reg <= THREE;
                    when "0100" => seg_reg <= FOUR;
                    when "0101" => seg_reg <= FIVE;
                    when "0110" => seg_reg <= SIX;
                    when "0111" => seg_reg <= SEVEN;
                    when "1000" => seg_reg <= EIGHT;
                    when "1001" => seg_reg <= NINE;
                    when others => seg_reg <= BLANK;
                end case;

            -- X axis, tens digit
            when "111" =>
                dp_reg <= '1';
                case x_10 is
                    when "0000" => seg_reg <= ZERO;
                    when "0001" => seg_reg <= ONE;
                    when "0010" => seg_reg <= TWO;
                    when "0011" => seg_reg <= THREE;
                    when "0100" => seg_reg <= FOUR;
                    when "0101" => seg_reg <= FIVE;
                    when "0110" => seg_reg <= SIX;
                    when "0111" => seg_reg <= SEVEN;
                    when "1000" => seg_reg <= EIGHT;
                    when "1001" => seg_reg <= NINE;
                    when others => seg_reg <= BLANK;
                end case;

            when others =>
                dp_reg  <= '1';
                seg_reg <= BLANK;

        end case;
    end process;

end Behavioral;

