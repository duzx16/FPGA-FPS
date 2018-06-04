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

architecture struc of RandomNumber is
signal seed : std_logic_vector(15 downto 0) := "0000000000000000";
begin
	num <= seed;
	process(clkin, rst)
	begin
		if (rst = '0') then
			seed <= "0000000000000000";
		elsif (rising_edge(clkin)) then
			seed <=
			shl(seed, "110") + shl(seed, "101") + shl(seed, "100") +
			shl(seed, "11") + shl(seed, "1") + seed + 59;
		end if;
	end process;
end struc;