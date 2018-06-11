library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity RandomNumber is
port(
--basic	
	clkin : in std_logic;
	rst : in std_logic;
	num : out std_logic_vector(15 downto 0) --random number
);
end entity;

architecture beh of RandomNumber is
signal feedback : std_logic;
signal lfsr_reg : std_logic_vector(15 downto 0); 
begin
	feedback <= lfsr_reg(7) xor lfsr_reg(0);
	latch_it: process(clkin, rst) 
	begin 
		if (rst = '1') then 
			lfsr_reg <= (others => '0'); 
		elsif (clkin = '1' and clkin'event) then 
			lfsr_reg <= lfsr_reg(lfsr_reg'high - 1 downto 0) & feedback;
		end if; 
	end process; 
	num <= lfsr_reg; 
end beh;