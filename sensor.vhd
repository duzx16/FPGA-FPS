library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library my_lib;
use my_lib.data_type.all;

entity sensor is
port(
	rst, clk: in std_logic;
	uart_rx: in std_logic;  -- 串口读取
	-- 返回准星的位置
	post_x: out integer range 0 to X_LIMIT;
	post_y: out integer range 0 to Y_LIMIT;
	led_x1: out std_logic_vector(6 downto 0);
	led_y1: out std_logic_vector(6 downto 0);
	led_z1: out std_logic_vector(6 downto 0);
	led_x0: out std_logic_vector(6 downto 0);
	led_y0: out std_logic_vector(6 downto 0);
	led_z0: out std_logic_vector(6 downto 0)
);
end entity;

architecture beh of sensor is
component uart is
port(
	clk: in std_logic; --100M的时钟
	rst: in std_logic; --rst信号
	rx: in std_logic; -- 串口读取
	data: out std_logic_vector(7 downto 0); --读取的8位向量值
	data_valid: out std_logic; --在读取完一个字节之后会变成1，开始下一个字节又会变成0
	uart_clk: buffer std_logic --按照串口波特率分频后的时钟
);
end component;
component led_converter is
port(
	num: in std_logic_vector(3 downto 0);
	led_display: out std_logic_vector(6 downto 0)
);
end component;
type recv_state is (head, type_data, value_data, check_sum);
signal current_state: recv_state;
signal pointer: integer range 0 to 8;
signal uart_data: std_logic_vector(7 downto 0);
signal uart_clk: std_logic;
signal data_valid: std_logic;
signal data_byte: std_logic_vector(7 downto 0);
signal data_buffer: std_logic_vector(71 downto 0);
signal angx, angy, angz: integer range -180 to 180;
signal vx1, vy1, vz1, vx0, vy0, vz0: std_logic_vector(3 downto 0);
begin
	sensor_uart: uart port map(
	clk => clk,
	rst => rst,
	rx => uart_rx,
	data_valid => data_valid,
	data => uart_data,
	uart_clk => uart_clk
	);
	converter_x1: led_converter port map(
	num => vx1,
	led_display => led_x1
	);
	converter_y1: led_converter port map(
	num => vy1,
	led_display => led_y1
	);
	converter_z1: led_converter port map(
	num => vz1,
	led_display => led_z1
	);
	converter_x0: led_converter port map(
	num => vx0,
	led_display => led_x0
	);
	converter_y0: led_converter port map(
	num => vy0,
	led_display => led_y0
	);
	converter_z0: led_converter port map(
	num => vz0,
	led_display => led_z0
	);
	process(rst, uart_clk)
	begin
		if rst = '0' then
			current_state <= head;
			angx <= 0;
			angy <= 0;
			angz <= 0;
			pointer <= 0;
		elsif rising_edge(uart_clk) then
			if data_valid = '1' then
				case current_state is
					when head =>
						if uart_data = x"55" then
							current_state <= type_data;
							pointer <= 0;
						end if;
					when type_data =>
						if uart_data = x"53" then
							current_state <= value_data;
							data_buffer(7 downto 0) <= uart_data;
							pointer <= 1;
						end if;
					when value_data =>
						data_buffer(8 * pointer + 7 downto 8 * pointer) <= uart_data;
						if pointer = 8 then
							pointer <= 0;
							current_state <= check_sum;
						end if;
						pointer <= pointer + 1;
					when check_sum =>
						current_state <= head;
						if conv_std_logic_vector(conv_integer(data_buffer(7 downto 0)) + conv_integer(data_buffer(15 downto 8)) + conv_integer(data_buffer(23 downto 16)) + conv_integer(data_buffer(31 downto 24))
						+ conv_integer(data_buffer(39 downto 32)) + conv_integer(data_buffer(47 downto 40)) + conv_integer(data_buffer(55 downto 48)) + conv_integer(data_buffer(63 downto 56))
						+ conv_integer(data_buffer(71 downto 64)) + 85, 8) = uart_data then
							if data_buffer(7 downto 0) = x"53" then
								angx <= (conv_integer(signed(data_buffer(23 downto 16)))*256 + conv_integer(data_buffer(15 downto 8))) / 182;
								angy <= (conv_integer(signed(data_buffer(39 downto 32)))*256 + conv_integer(data_buffer(31 downto 24))) / 182;
								angz <= (conv_integer(signed(data_buffer(55 downto 48)))*256 + conv_integer(data_buffer(47 downto 40))) / 182;
							end if;
						end if;
				end case;
			end if;
		end if;
	end process;
	
	process(angx, angy, angz)
	variable temp_x, temp_y: integer;
	begin
		temp_x := -(angz+8) * X_LIMIT / 56  + X_LIMIT / 2;
		temp_y := -(angx + 20) * Y_LIMIT / 56 + Y_LIMIT / 2;
		if temp_x >= X_LIMIT then
			post_x <= X_LIMIT - 1;
		elsif temp_x < 0 then
			post_x <= 0;
		else
			post_x <= temp_x;
		end if;
		if temp_y >= Y_LIMIT then
			post_y <= Y_LIMIT - 1;
		elsif temp_y < 0 then
			post_y <= 0;
		else
			post_y <= temp_y;
		end if;
	end process;
	process(angx, angy, angz)
	begin
		vx0 <= conv_std_logic_vector((angx + 180) / 40, 4);
		vy0 <= conv_std_logic_vector((angy + 180) / 40, 4);
		vz0 <= conv_std_logic_vector((angz + 180) / 40, 4);
		vx1 <= conv_std_logic_vector((angx + 180) / 4 MOD 10, 4);
		vy1 <= conv_std_logic_vector((angy + 180) / 4 MOD 10, 4);
		vz1 <= conv_std_logic_vector((angz + 180) / 4 MOD 10, 4);
	end process;
end architecture; 