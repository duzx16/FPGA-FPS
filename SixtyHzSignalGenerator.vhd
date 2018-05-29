library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity SixtyHzSignalGenerator is
port(
	clk100M:in std_logic;
	rst:in std_logic;
	clk60:out std_logic
);
end entity;

architecture struc of SixtyHzSignalGenerator is
	signal count : std_logic_vector( 20 downto 0);
begin
	clk60 <= count(20);
	
	process( clk100M , rst )
	begin 
		if ( rst = '0' ) then
			count <= (others =>'0');
		elsif ( rising_edge(clk100M) ) then
			if  count = "111111111111111111111" then
				count <= (others =>'0');
			else 
				count <= count + 1;
			end if;
		end if;
	end process;
end struc;