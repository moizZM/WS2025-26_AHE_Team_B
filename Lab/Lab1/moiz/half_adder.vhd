entity half_adder is
	port (a, b : IN BIT;
	s,c : OUT BIT);
end half_adder;

architecture structural of half_adder is 
begin
	c <= a and b;
	s <= a xor b;
end structural;	
