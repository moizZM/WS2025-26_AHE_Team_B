entity full_adder is
	port(A, B, c_in : IN BIT;
	c_out, S : OUT BIT);
end full_adder;

architecture structural of full_adder is

component half_adder
	port(a, b   : IN BIT;
		c, s : OUT BIT);
end component;

signal s1, s2, s3: BIT;
begin 

	HA1 : half_adder port map (

		a => A, 
		b => B,
		s => s2,
		c => s1);
	HA2 : half_adder port map (

		a => s2, 
		b => c_in,
		s => S,
		c => s3);

	c_out <= s1 or s3;

end structural;
