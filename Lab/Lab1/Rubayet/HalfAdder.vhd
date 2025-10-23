ENTITY half_adder IS
PORT (a,b: IN BIT;
	s,c: OUT BIT);
END ENTITY;

ARCHITECTURE behavioural of half_adder IS
BEGIN
s <= a XOR b;
c <=  a AND b;
END behavioural;