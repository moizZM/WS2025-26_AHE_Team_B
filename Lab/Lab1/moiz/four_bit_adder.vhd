entity four_bit_adder is
	port(a1,a2,a3,a4,b1,b2,b3,b4 : IN BIT;
	s1,s2,s3,s4, c_o : OUT BIT);
end four_bit_adder;

architecture structural of four_bit_adder is

component full_adder
	port(A, B, c_in : IN BIT;
	c_out, S : OUT BIT);
end component;

signal x, y, z : BIT;
signal gnd: BIT := '0';

begin 

	FA1 : full_adder port map (

		A => a1, 
		B => b1,
		c_in => gnd,
		c_out => x,
		S => s1 );

	FA2 : full_adder port map (

		A => a2, 
		B => b2,
		c_in => x,
		c_out => y,
		S => s2 );

	FA3 : full_adder port map (

		A => a3, 
		B => b3,
		c_in => y,
		c_out => z,
		S => s3 );

	FA4 : full_adder port map (

		A => a4, 
		B => b4,
		c_in => z,
		c_out => c_o,
		S => s4 );

end structural;