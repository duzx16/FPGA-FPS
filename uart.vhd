library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity uart is
port(
	clk: in std_logic; --100M的时钟
	rst: in std_logic; --rst信号
	rx: in std_logic; -- 串口读取
	data: out std_logic_vector(7 downto 0); --读取的8位向量值
	data_valid: out std_logic; --在读取完一个字节之后会变成1，开始下一个字节又会变成0
	uart_clk: buffer std_logic --按照串口波特率分频后的时钟
);
end entity;

architecture beh of uart is
	signal count: integer range 0 to 867 := 0; --分频计数
	signal pointer: integer range -1 to 8 := -1;
	signal data_buffer: std_logic_vector(7 downto 0); 
begin
process(clk) is
begin
	if clk'event and clk = '1' then
		count <= count + 1;
		if count = 867 then
			uart_clk <= '1';
			count <= 0;
		elsif count = 20 then
			uart_clk <= '0';
		end if;
	end if;
end process;

process(clk, rst, uart_clk) is
begin
	if rst = '0' then
		data_valid <= '0';
		data_buffer <= "00000000";
		pointer <= -1;
	elsif uart_clk'event and uart_clk = '1' then
		data_valid <= '0';
		case pointer is
			when -1 =>
				if rx = '0' then
					pointer <= 0;
				end if;
			when 8 =>
				if rx = '1' then
					data <= data_buffer;
					data_valid <= '1';
				end if;
				pointer <= -1;
			when others =>
				data_buffer(pointer) <= rx;
				pointer <= pointer + 1;
		end case;
	end if;		
end process;

end architecture;
	
	