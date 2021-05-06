LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
entity interleaver is 
	port(
		clk100 : in std_logic;--100 MHZ
		reset : in std_logic;
		data_in : in std_logic;
		data_in_valid : in std_logic;
		data_out_valid : out std_logic;
		data_out : out std_logic -- :='0'
		);
end interleaver;

architecture interleaver_arch of interleaver is 
type interleaver_state is (idle, load, out_1, out_2, no_in);
signal state : interleaver_state;
signal state_next : interleaver_state;
signal counter : unsigned (7 downto 0);
signal counter_next : unsigned (7 downto 0); 
signal data1: std_logic_vector(0 to 191);
signal data1_next: std_logic_vector(0 to 191);
signal data2: std_logic_vector(0 to 191);
signal data2_next: std_logic_vector(0 to 191);
--signal count_last : unsigned (7 downto 0);--:= (others=> '0');
signal x:std_logic;
signal last_in: std_logic:='0'; -- 0 => last input was in data1, 1=> last input was in data2
signal last_in_next: std_logic:='0'; -- 0 => last input was in data1, 1=> last input was in data2


begin 

data_out_valid<=x;

D:process (clk100, reset)
	begin 
	if (reset = '0') then 
		state <= idle; 
		counter <= (others => '0');
		data1 <= (others => '0');
		data2 <= (others => '0'); 
		--count_last<= (others => '0'); 
		last_in<='0';
	elsif (clk100'event AND clk100 = '1') then
		state <= state_next; 
		counter <= counter_next;
		data1 <= data1_next;
		data2 <= data2_next;
		last_in<=last_in_next;
	end if; 
	end process D;
	

fsm : process (state, counter, data1, data2, data_in_valid, last_in, data_in, x)
	begin 
	last_in_next<= last_in;
	state_next<= state;
	counter_next<= counter;
	data1_next<= data1;
	data2_next<=data2;
	--x<=x;
case state is 
	when idle => 
		x<='0';
		data_out<= '0';
		if (data_in_valid= '1' ) then 
			state_next <= load;
			data1_next (to_integer(( counter / 16 + counter mod 16 * 12) ) ) <= data_in;
			counter_next <= counter + 1;
		else  
			state_next<= idle;
		end if;
		
	when load => 
			x<='0';
			data_out<= '0';
		if (counter < 191 ) then 
			data1_next (to_integer(( counter / 16 + counter mod 16 * 12) ) ) <= data_in;
			counter_next <= counter + 1;
			state_next<= load;
			last_in_next<='0';
		elsif (counter = 191 ) then 
			data1_next (to_integer(( counter / 16 + counter mod 16 * 12) ) ) <= data_in;
			counter_next<= (others=> '0');
			state_next<= out_1;
		end if;	
		
		when out_1 => 
			x<='1';
		if (counter < 191 ) then 
			data2_next (to_integer(( counter / 16 + counter mod 16 * 12) ) ) <= data_in;
			counter_next <= counter + 1;
			last_in_next<='1';
			data_out<= data1(to_integer( counter ));
			state_next<= out_1;
		elsif (counter = 191 and data_in_valid='1') then
			data2_next (to_integer(( counter / 16 + counter mod 16 * 12) ) ) <= data_in;
			counter_next<= (others=> '0');
			data_out<= data1(to_integer( counter ));
			state_next<= out_2;
		elsif (counter = 191 and data_in_valid='0') then 
			state_next<=no_in;
			counter_next<= (others=> '0');
			data2_next (to_integer(( counter / 16 + counter mod 16 * 12) ) ) <= data_in;
			data_out<= data1(to_integer( counter ));
		else
			data_out<= data1(to_integer( counter ));
		end if;		
		
		when out_2 => 
			x<='1';
		if (counter < 191 ) then 
			last_in_next<='0';
			data1_next (to_integer(( counter / 16 + counter mod 16 * 12) ) ) <= data_in;
			counter_next <= counter + 1;
			data_out<= data2(to_integer( counter ));
			state_next<= out_2;
		elsif (counter = 191 and data_in_valid='1') then
			data1_next (to_integer(( counter / 16 + counter mod 16 * 12) ) ) <= data_in;
			counter_next<= (others=> '0');
			data_out<= data2(to_integer( counter ));
			state_next<= out_1;
		elsif (counter = 191 and data_in_valid='0') then 
			state_next<= no_in;
			counter_next<=(others=>'0');
			data1_next (to_integer(( counter / 16 + counter mod 16 * 12) ) ) <= data_in;
			data_out<= data2(to_integer( counter ));
		else 
			data_out<= data2(to_integer( counter ));
		end if;	
		
		when no_in=> 
		if (last_in = '1' and counter < 192) then 
			counter_next <= counter + 1;
			data_out<= data2(to_integer( counter ));
			x<='1';
		elsif (last_in = '0'and counter < 192) then 
			counter_next <= counter + 1;
			data_out<= data1(to_integer( counter ));
			x<='1';
		elsif(counter = 192) then 
			state_next<= idle;
			data_out<= '0';
			x<='0';
		else 
			data_out<= '0';
			x<='0';
		end if;
		
	end case;
end process fsm;

end interleaver_arch;











