ENTITY orgate IS 
PORT (c_first,c_second: IN BIT;
	c_out: OUT BIT);
END orgate;


ARCHITECTURE behavioural of orgate IS
BEGIN
c_out <= c_first or c_second;
END behavioural;