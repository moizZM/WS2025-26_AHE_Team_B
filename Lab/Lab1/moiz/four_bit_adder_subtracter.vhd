entity four_bit_adder_subtracter is

	port(   a: IN BIT_VECTOR (3 downto 0);
		b: IN BIT_VECTOR (3 downto 0);
		s: out BIT_VECTOR (3 downto 0);
		k: IN BIT; 
		cout : out bit
 	     );

end four_bit_adder_subtracter;

architecture structural of four_bit_adder_subtracter is

component full_adder
	port(A, B, c_in : IN BIT;
	c_out, S : OUT BIT);
end component;

signal c0, c1, c2 : BIT;
signal b_xor_k : BIT_VECTOR (3 downto 0);
begin 
	b_xor_k(0) <= b(0) xor K;
	b_xor_k(1) <= b(1) xor K;
	b_xor_k(2) <= b(2) xor K;
	b_xor_k(3) <= b(3) xor K;

	FA0 : full_adder port map (

		A => a(0) , 
		B => b_xor_k(0) ,
		c_in => k  ,
		c_out => c0 ,
		S => s(0) );
	FA1 : full_adder port map (

		A => a(1) , 
		B => b_xor_k(1) ,
		c_in => c0  ,
		c_out => c1 ,
		S => s(1) );

	FA2 : full_adder port map (

		A => a(2) , 
		B => b_xor_k(2) ,
		c_in => c1  ,
		c_out => c2 ,
		S => s(2) );

	FA3 : full_adder port map (

		A => a(3) , 
		B => b_xor_k(3) ,
		c_in => c2  ,
		c_out => cout ,
		S => s(3) );
	

end structural;
