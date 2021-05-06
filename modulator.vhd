LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
entity modulator is 
	port(
		clk100 : in std_logic;--100 MHZ
		reset : in std_logic;
		data_in : in std_logic;
		data_in_valid : in std_logic;
		data_out_valid : out std_logic;
		q_out : out std_logic_vector (15 downto 0):=(others=> '0');
		i_out : out std_logic_vector (15 downto 0):=(others=> '0')
		);
end modulator;

architecture modulator_arch of modulator is 
type modulator_state is (idle, i_ready, iq_out);
signal state : modulator_state;
signal in_concat : std_logic_vector (15 downto 0); --input& 101101001111111

begin 
	 process (reset, clk100)
	begin
	if (reset = '0') then 
		in_concat <= (others => '0');
		state<= idle;
	elsif ( clk100'event and clk100 = '1') then

	case state is 
		when idle => 
			if (data_in_valid = '1') then 
				in_concat<= data_in & "101101001111111";
				state<= iq_out;
			else
				state<= idle;
				data_out_valid<='0';
			end if;
			when iq_out=> 
			if (data_in_valid='1') then 
				data_out_valid<='1';
				i_out<= in_concat;
				q_out<=data_in & "101101001111111";
				state<= i_ready;
			else 
				state<=idle;
				data_out_valid<='0';
			end if; 
		when i_ready => 
			if (data_in_valid='1') then 
				in_concat<= data_in & "101101001111111";
				state<= iq_out;
			else 
				state<=idle;
				data_out_valid<='0';
			end if; 

	end case; 
	end if;
end process;

end modulator_arch;
