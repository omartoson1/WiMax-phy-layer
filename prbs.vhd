LIBRARY ieee;
USE ieee.numeric_std.all;
USE ieee.std_logic_1164.all; 
entity prbs is 
	port (
	--seed_load : in std_logic_vector (0 to 14); replaced with 101010001110110 for the project
	clk : in std_logic;
	reset : in std_logic;
	en : in std_logic;
	data_in : in std_logic;
	data_out_valid :out std_logic;
	data_out : out std_logic
	);
end prbs;
architecture prbs_arch of prbs is
SIGNAL r_reg: std_logic_vector(14 downto 0);
SIGNAL r_next: std_logic_vector (14 downto 0);
signal counter: unsigned (6 downto 0); 
begin 
	process (clk, reset)
	begin
    if (reset='0')then
		r_reg<="101010001110110";
		counter<="0000000";
		data_out_valid<='0';
		data_out <= '0';
	elsif (clk'event AND clk = '1') then 

		if en = '1' then 
			data_out <= (data_in xor (r_reg(13) xor r_reg(14)));
			data_out_valid<='1';
			if (to_integer(counter)= 95) then 
				r_reg<="101010001110110";
				counter<="0000000";
			else 
				r_reg <= r_next;
				counter<= counter +1;
			end if;
		else
			data_out_valid<='0';
			data_out <= '0';
			counter<= counter;
			r_reg <=r_reg;
		end if;
	end if;
	end process;
	
--data_out_valid<=en;
r_next<= (r_reg(13 downto 0) & (r_reg(13) xor r_reg(14)));
end prbs_arch;
