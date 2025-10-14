entity four_bit_adder_tb is
end  four_bit_adder_tb;

architecture structural of  four_bit_adder_tb is 

component  four_bit_adder
	port(a1,a2,a3,a4,b1,b2,b3,b4 : IN BIT;
	s1,s2,s3,s4, c_o : OUT BIT);
end component;

signal a1_tb, a2_tb, a3_tb, a4_tb, b1_tb, b2_tb, b3_tb, b4_tb, s1_tb, s2_tb, s3_tb, s4_tb, c_o : BIT;

begin

	DUT: four_bit_adder port map ( a1 => a1_tb, a2 => a2_tb, a3 => a3_tb, a4 => a4_tb, b1 => b1_tb, b2 => b2_tb, b3 => b3_tb, b4 => b4_tb, s1 => s1_tb, s2 => s2_tb, s3 => s3_tb, s4 => s4_tb, c_o => c_o  );
	
	-- A inputs
	a1_tb <= '0', '1' after 10 ns, '1' after 20 ns, '1' after 30 ns, '0' after 40 ns;
	a2_tb <= '0', '0' after 10 ns, '0' after 20 ns, '1' after 30 ns, '1' after 40 ns;
	a3_tb <= '0', '0' after 10 ns, '1' after 20 ns, '1' after 30 ns, '0' after 40 ns;
	a4_tb <= '0', '0' after 10 ns, '0' after 20 ns, '1' after 30 ns, '1' after 40 ns;

	-- B inputs
	b1_tb <= '0', '1' after 10 ns, '1' after 20 ns, '1' after 30 ns, '1' after 40 ns;
	b2_tb <= '0', '0' after 10 ns, '1' after 20 ns, '0' after 30 ns, '0' after 40 ns;
	b3_tb <= '0', '0' after 10 ns, '0' after 20 ns, '0' after 30 ns, '1' after 40 ns;
	b4_tb <= '0', '0' after 10 ns, '0' after 20 ns, '0' after 30 ns, '0' after 40 ns;


        
	
end structural;