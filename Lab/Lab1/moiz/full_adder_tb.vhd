entity full_adder_tb is
end full_adder_tb;

architecture structural of full_adder_tb is 

component full_adder
	port (A, B, c_in : IN BIT;
		S, c_out : OUT BIT);
end component;

signal a_tb, b_tb, s_tb, c_in_tb, c_out_tb  : BIT;
begin

	DUT: full_adder port map (A => a_tb, B => b_tb, c_in => c_in_tb, S => s_tb, c_out => c_out_tb);

	c_in_tb       <=  '0' after 10 ns , '0' after 20 ns, '0' after 30 ns ,'0' after 40 ns , '1' after 50 ns, '1' after 60 ns, '1' after 70 ns, '1' after 80 ns;
	b_tb    <=     '0' after 10 ns , '0' after 20 ns, '1' after 30 ns ,'1' after 40 ns , '0' after 50 ns, '0' after 60 ns, '1' after 70 ns, '1' after 80 ns;
	a_tb <=     '0' after 10 ns , '1' after 20 ns, '0' after 30 ns ,'1' after 40 ns , '0' after 50 ns, '1' after 60 ns, '0' after 70 ns, '1' after 80 ns;
end structural;
