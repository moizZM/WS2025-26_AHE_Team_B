ENTITY full_adder IS 
PORT (a,b,c_in: IN BIT;
	c_out, s: OUT BIT);
END full_adder;

ARCHITECTURE structural OF full_adder is
COMPONENT half_adder
PORT (a,b: IN BIT;
	c,s: OUT BIT);
END COMPONENT;
COMPONENT orgate IS
PORT (c_first,c_second: IN BIT;
	c_out: OUT BIT);
END COMPONENT;
SIGNAL c_first, s_a, c_second: BIT;
BEGIN
U1: half_adder PORT MAP(a=>a,b=>b,c=>c_first,s=>s_a);
U2: half_adder PORT MAP(a=>s_a,b=>c_in,c=>c_second,s=>s);
U3: orgate PORT MAP(c_first=>c_first,c_second=>c_second,c_out=>c_out);
END structural;