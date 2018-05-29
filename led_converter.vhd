library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity led_converter is
port(
	num: in std_logic_vector(3 downto 0);
	led_display: out std_logic_vector(6 downto 0)
);
end entity;

architecture bhv of led_converter is
begin
	process(num)
	begin
		case num is
			when "0000"=> led_display<="1111110";
			when "0001"=> led_display<="1100000";
			when "0010"=> led_display<="1011101";
			when "0011"=> led_display<="1111001";
			when "0100"=> led_display<="1100011";
			when "0101"=> led_display<="0111011";
			when "0110"=> led_display<="0111111";
			when "0111"=> led_display<="1101000";
			when "1000"=> led_display<="1111111";
			when "1001"=> led_display<="1111011";
			when others=> led_display<="0000000";
		end case;
	end process;
end bhv;