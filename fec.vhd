LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
entity fec is 
port (
	clk50 : in std_logic:='0';
	clk100: in std_logic:='0';
	data_in: in std_logic:='0';
	data_in_valid: in std_logic:='0';
	reset: in std_logic:='1';
	data_out: out std_logic;--:='0';
	data_out_valid: out std_logic:='0'
	);
end fec; 
architecture fec_arch of fec is 
component DPR 
	PORT (
		address_a		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock_a		: IN STD_LOGIC  := '1';
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
	);
END component;
signal address_a : STD_LOGIC_VECTOR (7 DOWNTO 0);
signal address_b : STD_LOGIC_VECTOR (7 DOWNTO 0);
signal data_a : STD_LOGIC_VECTOR (0 DOWNTO 0);
signal data_b : STD_LOGIC_VECTOR (0 DOWNTO 0);
signal wren_a : STD_LOGIC:='1';
signal wren_b : STD_LOGIC:='1';
signal q_a : STD_LOGIC_VECTOR (0 DOWNTO 0);
signal q_b : STD_LOGIC_VECTOR (0 DOWNTO 0);
type fec_state is (idle, out_y, out_x);
signal state : fec_state;
signal state_next : fec_state;
signal counter_write : unsigned (7 downto 0) :="00000000";
signal counter_read : unsigned (7 downto 0) :="01100000";-- 7 bits to count up to 95 (1011 111)
signal counter_last : unsigned (7 downto 0) :="00000000";-- 7 bits to count up to 95 (1011 111)

signal r_reg_a: std_logic_vector(0 to 5):=(others=>'0');
signal r_reg_b: std_logic_vector(0 to 5):=(others=>'0');
signal ready: std_logic;-- 0 = not intialized 
signal switch: std_logic:='0'; 

-- switch = 0 means writing in data_a and reading from data_b 
-- switch = 1 means writing in data_b and reading from data_a

begin 
ram: DPR 
port map (
address_a => address_a,
address_b => address_b, --not needed 
clock_a => clk50,
clock_b => clk50,
data_a => data_a,
data_b => data_b,--not needed 
wren_a => wren_a,
wren_b => wren_b,
q_a => q_a,
q_b => q_b);

address_b (7 DOWNTO 0)<= std_logic_vector(counter_read); 	
address_a (7 DOWNTO 0)<= std_logic_vector(counter_write); 
data_a(0) <= data_in; 	
wren_a <= '1' when data_in_valid = '1' else 
'0';

process(clk50, reset)
begin
	if (reset = '0') then
		ready<='0';
		wren_b <= '0';
		counter_write<= (others=> '0');
		counter_read<="01100001";
		switch <= '0';
		data_b(0) <= '0';
	elsif(clk50'event AND clk50 = '1') then 
		data_b(0) <= '0';
		wren_b <= '0';
		if (data_in_valid = '1') then 
			if (counter_write < 96) then
				counter_write <= counter_write + 1;  
				counter_read <= counter_read + 1;
				r_reg_a <= data_in & r_reg_a (0 to 4);
				r_reg_b <= q_b(0) & r_reg_b (0 to 4);
			elsif (counter_write = 96) then
				counter_write <= counter_write + 1;  
				counter_read <= "00000001";	
				--r_reg_a <= data_in & r_reg_a (0 to 4);
				r_reg_b <= q_b(0) & r_reg_b (0 to 4);
				ready<= '1';
				switch <= '1';
			elsif (counter_write > 96 and counter_write < 192) then 
				counter_write <= counter_write + 1;
				counter_read <= counter_read + 1;
				r_reg_b <= data_in & r_reg_b(0 to 4);
				r_reg_a <= q_b(0) & r_reg_a (0 to 4);
			elsif (counter_write = 192) then 
				counter_write <= "00000001";	
				counter_read <= counter_read + 1;
				--r_reg_b <= data_in & r_reg_b(0 to 4);
				r_reg_a <= q_b(0) & r_reg_a (0 to 4);
				switch <= '0';
			end if;
		elsif (data_in_valid = '0' and ready = '1') then 
			
				counter_last<= counter_last + 1;
				
			
				if (counter_write < 96 and counter_last< 96) then
					counter_write <= counter_write + 1;  
					counter_read <= counter_read + 1;
					--r_reg_a <= data_in & r_reg_a (0 to 4);
					r_reg_b <= q_b(0) & r_reg_b (0 to 4);
				elsif (counter_write = 96 and counter_last< 96) then
					counter_write <= counter_write + 1;  
					counter_read <= "00000001";	
					--r_reg_a <= data_in & r_reg_a (0 to 4);
					r_reg_b <= q_b(0) & r_reg_b (0 to 4);
					ready<= '1';
					switch <= '1';
				elsif (counter_write > 96 and counter_write < 192 and counter_last< 96) then 
					counter_write <= counter_write + 1;
					counter_read <= counter_read + 1;
					--r_reg_b <= data_in & r_reg_b(0 to 4);
					r_reg_a <= q_b(0) & r_reg_a (0 to 4);
				elsif (counter_write = 192 and counter_last< 96) then 
					counter_write <= "00000001";	
					counter_read <= counter_read + 1;
					--r_reg_b <= data_in & r_reg_b(0 to 4);
					r_reg_a <= q_b(0) & r_reg_a (0 to 4);
					switch <= '0';				
				else 
					ready<= '0';
			end if;
			
		end if; 
	end if; 
end process;

process(clk100, reset)
begin
	if (reset = '0') then 
		state<= idle;
	elsif (clk100'event AND clk100 = '1') then
		state<=state_next;
	end if;
	end process;
	
fsm:process (state, ready, q_b,r_reg_b, r_reg_a, switch)
begin
	state_next<= state;
case state is 

	when idle =>
	if (ready = '1') then
		state_next<=out_x;
		data_out_valid<='1';
		data_out<= q_b(0) xor r_reg_a(1) xor r_reg_a(2) xor r_reg_a(4) xor r_reg_a(5);
	else 
		state_next<= idle;
		data_out_valid<='0';
		data_out<='0';
	end if;
		
	when out_y => 
	if ( ready = '1' ) then
		state_next<= out_x;
		data_out_valid<='1';
		if (switch = '1') then 
			data_out<= q_b(0) xor r_reg_a(0) xor r_reg_a(1) xor r_reg_a(2) xor r_reg_a(5);
		else 
			data_out<= q_b(0) xor r_reg_b(0) xor r_reg_b(1) xor r_reg_b(2) xor r_reg_b(5);
		end if;
	else
		data_out<='0';
		state_next<= idle;
		data_out_valid<='0';
	end if;
	
	when out_x=>
	if ( ready = '1') then
		state_next<= out_y;
		data_out_valid<='1';
		
		if (switch = '1') then 
			data_out<= q_b(0) xor r_reg_a(1) xor r_reg_a(2) xor r_reg_a(4) xor r_reg_a(5);
		else 
			data_out<= q_b(0) xor r_reg_b(1) xor r_reg_b(2) xor r_reg_b(4) xor r_reg_b(5);
		end if;		
	else
		data_out<='0';
		state_next<= idle;
		data_out_valid<='0';
	end if;
	end case;
end process fsm;
end fec_arch;
--