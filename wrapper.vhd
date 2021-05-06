library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wrapper is 
port(
clk: in std_logic--;
--reset: in std_logic;
--prps_check :out std_logic;
--fec_check :out std_logic;
--inter_check :out std_logic;
--mod_check :out std_logic--;

	);
end wrapper;

architecture wrapper_arch of wrapper is

component pll is 
port (
	refclk   : in  std_logic := '0'; --  refclk.clk
	rst      : in  std_logic := '0'; --   reset.reset
	outclk_0 : out std_logic;        -- outclk0.clk
	outclk_1 : out std_logic;        -- outclk1.clk
	locked   : out std_logic  
);
end component pll;

component wimax_top is
port (
	clk_top_50 : in std_logic;
	clk_top_100 : in std_logic;
	data_in : in std_logic;
	ready : in std_logic;
	
	reset : in std_logic;
	
	data_out_valid_top : out std_logic;
	q_top : out std_logic_vector (15 downto 0);
	i_top : out std_logic_vector (15 downto 0);
	
	prbs_out : out std_logic;
	fec_out : out std_logic;
	inter_out : out std_logic;
	
	prbs_out_ready : out std_logic;
	fec_out_ready : out std_logic;
	inter_out_ready : out std_logic
	);
end component wimax_top;

--------------------------------------------------------------
component jtag_system is
	port (
		source : out std_logic_vector(0 downto 0);                    -- source
		probe  : in  std_logic_vector(3 downto 0) := (others => 'X')  -- probe
	);
end component jtag_system;
--------------------------------------------------------------

signal clk_top_50, clk_top_100, locked, ready, data_in,data_out_valid_top: std_logic;
signal q_top, i_top : std_logic_vector(15 downto 0);
signal prbs_out, fec_out, inter_out : std_logic;
signal pr,int,fe,modu: std_logic;
signal prbs_out_ready,fec_out_ready,inter_out_ready: std_logic;
signal input_counter, counter_prbs, counter_fec, counter_inter, q_index, i_index: unsigned (7 downto 0);
constant input: std_logic_vector(0 to 95) := X"ACBCD2114DAE1577C6DBF4C9";
constant output_prbs:std_logic_vector(0 to 95):=X"558AC4A53A1724E163AC2BF9";
constant output_fec:std_logic_vector(0 to 191):=X"2833E48D392026D5B6DC5E4AF47ADD29494B6C89151348CA";
constant output_inter:std_logic_vector(0 to 191):=x"4B047DFA42F2A5D5F61C021A5851E9A309A24FD58086BD1E";

--------------------------------------------------------------
signal source_concat : std_logic_vector(0 downto 0); 
signal probe_concat : std_logic_vector(3 downto 0);  
signal reset,prps_check,fec_check,mod_check,inter_check : std_logic:='0'; 
--------------------------------------------------------------
begin 
j_tag: jtag_system
port map (
	source=> source_concat,
	probe => probe_concat
		);
reset<=source_concat(0);
probe_concat(0)<=prps_check;
probe_concat(1)<=fec_check;
probe_concat(2)<=inter_check;
probe_concat(3)<=mod_check;

phase : pll
port map (
	refclk => clk,
	rst => reset,
	outclk_0 => clk_top_100,
	outclk_1 => clk_top_50,
	locked => locked
		);
top : wimax_top
port map (
	clk_top_50 => clk_top_50,
	clk_top_100 => clk_top_100,
	data_in => data_in,
	ready => ready,
	reset => locked,
	data_out_valid_top => data_out_valid_top,
	q_top => q_top,
	i_top => i_top,
	
	prbs_out => prbs_out,
	fec_out => fec_out,
	inter_out => inter_out,
	
	prbs_out_ready => prbs_out_ready,
	fec_out_ready => fec_out_ready,
	inter_out_ready => inter_out_ready
		);	

prbs_process: process (clk_top_50, locked)
begin
	if (locked ='0') then
		prps_check <= '0';
		counter_prbs<= (others=> '0');
		input_counter<= (others=>'0');
		pr<='1';
		ready<='0';
	elsif(clk_top_50'event and clk_top_50='1') then
		if (to_integer(input_counter)<95) then 
			input_counter<=input_counter + 1;
			data_in <=input(to_integer(input_counter));
			ready<='1';
		elsif (to_integer(input_counter)=95) then 
			input_counter<= (others=> '0');
			data_in <=input(to_integer(input_counter));
			ready<='1';
			pr<='1';
		end if;
		
		if (to_integer(counter_prbs)<95 and prbs_out_ready = '1') then 
			counter_prbs<=counter_prbs + 1;
		elsif(to_integer(counter_prbs)=95 and prbs_out_ready = '1') then 
			counter_prbs<=(others=>'0');
		end if; 
		
		-- if (output_prbs(to_integer(counter_prbs)) =prbs_out and prbs_out_ready='1') then 
			-- prps_check <= '1';
		-- else 
			-- prps_check <= '0';
			
		-- end if;
		
		if (prbs_out_ready='1') then
			if (output_prbs(to_integer(counter_prbs)) =prbs_out ) then
				prps_check<= pr;
			else 
				pr<='0';
			end if;
		else 
			prps_check<= '0';
		end if;
		
		
		
	end if; 
end process prbs_process;
	
	
	
fec_process: process (clk_top_100, locked)
begin
	if (locked = '0') then
		counter_fec<= (others=>'0');
		fec_check<= '0';
		fe<='1';
	elsif (clk_top_100'event and clk_top_100='1') then 
	
		if (fec_out_ready = '1' and to_integer(counter_fec) < 191) then 
			counter_fec<= counter_fec + 1;
			
		elsif (fec_out_ready = '1' and to_integer(counter_fec) = 191) then 
			counter_fec<= (others=>'0');
			fe<='1';
		end if;
		
		
		if (fec_out_ready = '1') then
			if (output_fec(to_integer(counter_fec)) = fec_out ) then
				fec_check<= fe;
			else 
				fe<='0';
			end if;
		else 
			fec_check<= '0';
		end if;
		
		
		--if (output_fec(to_integer(counter_fec)) = fec_out and fec_out_ready = '1' and fe='1') then
			--fec_check<= fe;
			--fe<='1';
		--elsif (fec_out_ready = '0') then
			--fec_check<= '0';
			--fe<='1';
		--else 
			--fe<='0';
		--end if; 
		--fec_check<= fe;
	end if; 

end process fec_process;
	

inter_process: process (clk_top_100, locked)
begin

	if (locked = '0') then
		counter_inter<= (others=>'0');
		inter_check<= '0';
		int<='1';
	elsif (clk_top_100'event and clk_top_100='1') then 
	
		if (inter_out_ready = '1' and to_integer(counter_inter) < 191) then 
			counter_inter<= counter_inter + 1;
		elsif (inter_out_ready = '1' and to_integer(counter_inter) = 191) then 
			int<='1';
			counter_inter<= (others=>'0');
		end if;

		
		-- if (output_inter(to_integer(counter_inter)) = inter_out and inter_out_ready = '1') then
			-- inter_check<= '1';
		-- else 
			-- inter_check<= '0';
		-- end if; 
		
		if (inter_out_ready = '1') then 
			if (output_inter(to_integer(counter_inter))= inter_out) then 
				inter_check<= int;
			else 
				int<='0';
			end if; 
		else 
			inter_check<= '0';
		end if;
	end if; 

end process inter_process;
	
	
mod_process: process (clk_top_50, locked)
begin
	if (locked = '0') then 
		mod_check<='0';
		q_index<="00000001";
		i_index<="00000000";
		modu<='1';
	elsif (clk_top_50'event and clk_top_50='1') then 
	
	
		if (data_out_valid_top = '1' and to_integer(q_index) < 191) then 
			q_index<= q_index+2;
			i_index<= i_index+2;

		elsif (data_out_valid_top = '1' and to_integer(q_index) = 191) then 
			q_index<="00000001";
			i_index<="00000000";
			modu<='1';
		end if;
		
		
		if  (q_top(15) = output_inter(to_integer(q_index)) and i_top(15) = output_inter(to_integer(i_index)))  then 
			mod_check<=modu;
		else 
			modu<='0';
			
		end if;
		
	end if; 
		
	
end process mod_process;
	
end wrapper_arch;