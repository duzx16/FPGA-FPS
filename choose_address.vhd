library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

entity AddressChooser is
port(
	--clk_
	clk100M: in std_logic;
	--out to ram
	data: out std_logic_vector( 15 downto 0 );
	wraddress: out std_logic_vector( 11 downto 0 );
	wren: out std_logic;
	rdaddress: out std_logic_vector( 11 downto 0 );
	rden: out std_logic;
	q: in std_logic_vector( 15 downto 0 );
	
	--in  1
	worken1: in std_logic;
	data1: in std_logic_vector( 15 downto 0 );
	wraddress1: in std_logic_vector( 11 downto 0 );
	wren1: in std_logic;
	rdaddress1: in std_logic_vector( 11 downto 0 );
	rden1: in std_logic;
	q1: out std_logic_vector( 15 downto 0 );	
	
	--in  2
	worken2: in std_logic;
	data2: in std_logic_vector( 15 downto 0 );
	wraddress2: in std_logic_vector( 11 downto 0 );
	wren2: in std_logic;
	rdaddress2: in std_logic_vector( 11 downto 0 );
	rden2: in std_logic;
	q2: out std_logic_vector( 15 downto 0 );
	
	--in  3
	worken3: in std_logic;
	data3: in std_logic_vector( 15 downto 0 );
	wraddress3: in std_logic_vector( 11 downto 0 );
	wren3: in std_logic;
	rdaddress3: in std_logic_vector( 11 downto 0 );
	rden3: in std_logic;
	q3: out std_logic_vector( 15 downto 0 );

	--in  4
	worken4: in std_logic;
	data4: in std_logic_vector( 15 downto 0 );
	wraddress4: in std_logic_vector( 11 downto 0 );
	wren4: in std_logic;
	rdaddress4: in std_logic_vector( 11 downto 0 );
	rden4: in std_logic;
	q4: out std_logic_vector( 15 downto 0 );
	
	--in  5
	worken5: in std_logic;
	data5: in std_logic_vector( 15 downto 0 );
	wraddress5: in std_logic_vector( 11 downto 0 );
	wren5: in std_logic;
	rdaddress5: in std_logic_vector( 11 downto 0 );
	rden5: in std_logic;
	q5: out std_logic_vector( 15 downto 0 )
);

end entity;

architecture choose of AddressChooser is
	signal flag : std_logic_vector ( 15 downto 0 );
	--out to ram
	signal data_in: std_logic_vector( 15 downto 0 );
	signal wraddress_in: std_logic_vector( 11 downto 0 );
	signal wren_in: std_logic;
	signal rdaddress_in: std_logic_vector( 11 downto 0 );
	signal rden_in: std_logic;
	signal q_s: std_logic_vector( 15 downto 0 );
begin 	
	flag <= "11111111111" & worken5 & worken4 & worken3 & worken2 & worken1;
	data <= data_in;
	wraddress <= wraddress_in;
	wren <= wren_in;
	rdaddress <= rdaddress_in;
	rden <= rden_in;
	q_s <= q;
	q1<= q_s;
	q2<= q_s;
	q3<= q_s;
	q4<= q_s;
	q5<= q_s;
	process (clk100M)
	begin
		case flag is 
		when "1111111111111110" =>
			data_in <= data1;
			wraddress_in <= wraddress1;
			rdaddress_in <= rdaddress1;
			rden_in <= rden1;
			wraddress_in <= wraddress1;
			wren_in <= wren1;
			--q1 <= q_s;
		when "1111111111111101" =>
			data_in <= data2;
			wraddress_in <= wraddress2;
			rdaddress_in <= rdaddress2;
			rden_in <= rden2;
			wraddress_in <= wraddress2;
			wren_in <= wren2;
			--q2 <= q_s;
		when "1111111111111011" =>
			data_in <= data3;
			wraddress_in <= wraddress3;
			rdaddress_in <= rdaddress3;
			rden_in <= rden3;
			wraddress_in <= wraddress3;
			wren_in <= wren3;
			--q3 <= q_s;
		when "1111111111110111" =>
			data_in <= data4;
			wraddress_in <= wraddress4;
			rdaddress_in <= rdaddress4;
			rden_in <= rden4;
			wraddress_in <= wraddress4;
			wren_in <= wren4;
			--q4 <= q_s;
		when "1111111111101111" =>
			data_in <= data5;
			wraddress_in <= wraddress5;
			rdaddress_in <= rdaddress5;
			rden_in <= rden5;
			wraddress_in <= wraddress5;
			wren_in <= wren5;
			--q4 <= q_s;
		when others => 
			wren_in <= '1';
			rden_in <='0';
		end case;
			
	end process;

end choose;