library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all; 

entity wimax_top is
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
end wimax_top;

architecture wimax_top_arch of wimax_top is
--component pll is
--	port (
--		refclk   : in  std_logic := '0'; --  refclk.clk
--		rst      : in  std_logic := '0'; --   reset.reset
--		outclk_0 : out std_logic;        -- outclk0.clk
--		outclk_1 : out std_logic;        -- outclk1.clk
--		locked   : out std_logic         --  locked.export
--	);
--end component;
 
component prbs 
	port (
		clk : in std_logic; -- 50 MHz
		reset : in std_logic;
		en : in std_logic;
		data_in : in std_logic;
		data_out_valid :out std_logic;
		data_out : out std_logic
	);
end component;

component fec
	port (
		clk50 : in std_logic:='0';
		clk100: in std_logic:='0';
		data_in: in std_logic:='0';
		data_in_valid: in std_logic:='0';
		reset: in std_logic:='1';
		data_out: out std_logic:='0';
		data_out_valid: out std_logic:='0'
	);
end component;

component interleaver 
	port (
		clk100 : in std_logic;--100 MHZ
		reset : in std_logic;
		data_in : in std_logic;
		data_in_valid : in std_logic;
		data_out_valid : out std_logic;
		data_out : out std_logic
	);
end component;

component modulator  
	port (
		clk100 : in std_logic;--100 MHZ
		reset : in std_logic;
		data_in : in std_logic;
		data_in_valid : in std_logic;
		
		
		
		data_out_valid : out std_logic;
		q_out : out std_logic_vector (15 downto 0);
		i_out : out std_logic_vector (15 downto 0)
	);
end component;

signal clk50_sig : std_logic;
signal clk100_sig : std_logic;

signal global_reset_sig : std_logic;
signal en_sig : std_logic;
signal data_in_sig : std_logic;

signal prbs_out_sig : std_logic;
signal fec_out_sig : std_logic;
signal interleaver_out_sig : std_logic;

signal fec_in_sig : std_logic;
signal interleaver_in_sig : std_logic;
signal modulator_in_sig : std_logic;

signal prbs_out_ready_sig : std_logic;
signal fec_out_ready_sig : std_logic;
signal interleaver_out_ready_sig : std_logic;
--signal reset_sig: std_logic;

--signal locked_sig : std_logic;

begin 
--reset_sig<= reset;
global_reset_sig <= reset;
clk50_sig <= clk_top_50;
clk100_sig <=clk_top_100;
en_sig <= ready;
--global_reset_sig <= locked_sig;
data_in_sig<=data_in;

fec_in_sig <= prbs_out_sig;
interleaver_in_sig <= fec_out_sig;
modulator_in_sig <= interleaver_out_sig;

prbs_out<=prbs_out_sig; 
fec_out<=fec_out_sig;
inter_out<=interleaver_out_sig;
prbs_out_ready <= prbs_out_ready_sig;
fec_out_ready <=fec_out_ready_sig;
inter_out_ready<=interleaver_out_ready_sig ;

--phase_loop: pll
--port map(
--refclk => clk_top_50,
--rst => reset,
--outclk_0 => clk100_sig,
--outclk_1 => clk50_sig,
--locked => locked_sig 
--		);

randomizer : prbs
port map (
		clk => clk50_sig,
		reset => global_reset_sig,
		en=> en_sig,
		data_in=> data_in_sig,
		data_out_valid => prbs_out_ready_sig,
		data_out => prbs_out_sig
		);
encoder : fec
port map (
		clk50 => clk50_sig,
		clk100 => clk100_sig,
		reset => global_reset_sig,
		data_in => fec_in_sig,	
		data_in_valid => prbs_out_ready_sig,
		data_out_valid =>fec_out_ready_sig, 
		data_out => fec_out_sig
		);
interleave : interleaver
port map (
		clk100 => clk100_sig,
		reset => global_reset_sig,
		data_in => interleaver_in_sig,
		data_in_valid => fec_out_ready_sig,
		data_out_valid => interleaver_out_ready_sig,
		data_out => interleaver_out_sig
		);
modulate: modulator
	port map (
		clk100 => clk100_sig,
		reset => global_reset_sig,
		data_in => modulator_in_sig,
		data_in_valid => interleaver_out_ready_sig,
		data_out_valid => data_out_valid_top,
		q_out => q_top,
		i_out => i_top
		);	
		
end wimax_top_arch;