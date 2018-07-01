library ieee; 
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity RandomNumber is
port(
	clkin : in std_logic;
	rst : in std_logic;
	num : out std_logic_vector(15 downto 0) --random number
);
end entity;

architecture beh of RandomNumber is
signal feedback : std_logic;
signal lfsr_reg : std_logic_vector(15 downto 0); 
begin
	feedback <= lfsr_reg(15) xor lfsr_reg(4) xor lfsr_reg(2) xor lfsr_reg(1);
	latch_it: process(clkin, rst) 
	begin 
		if (rst = '0') then 
			lfsr_reg <= "0110110101111010";
		elsif (clkin = '1' and clkin'event) then 
			lfsr_reg <= lfsr_reg(14 downto 0) & feedback;
		end if; 
	end process; 
	num <= lfsr_reg; 
end beh;