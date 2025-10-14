entity four_bit_adder_subtracter_tb is
end four_bit_adder_subtracter_tb;

architecture structural of four_bit_adder_subtracter_tb is 

component four_bit_adder_subtracter

	port(   a: IN BIT_VECTOR (3 downto 0);
		b: IN BIT_VECTOR (3 downto 0);
		s: out BIT_VECTOR (3 downto 0);
		k: IN BIT; 
		cout : out bit
 	     );

end component;
signal a_tb, b_tb, s_tb : BIT_VECTOR (3 downto 0);
signal k_tb, cout_tb : BIT;
begin

	DUT: four_bit_adder_subtracter port map (a => a_tb, b => b_tb, s => s_tb, cout => cout_tb, k => k_tb);

	k_tb <=    '0', '1' after 10 ns, '0' after 20 ns, '1' after 30 ns;
	a_tb <= "0000", "1011" after 10 ns, "1000" after 20 ns, "0111" after 30 ns;
	b_tb <= "0000", "0011" after 10 ns, "0001" after 20 ns, "0111" after 30 ns;
	

end structural;
