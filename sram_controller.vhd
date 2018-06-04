library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity sram_controller is
	port(
		clk_0 : in std_logic;  --25M
		rwselect : in std_logic;   --read for '0'
		addr: in std_logic_vector(19 downto 0);
		base_sram_we, base_sram_oe, base_sram_ce : out std_logic;
		base_sram_addr:out std_logic_vector(19 downto 0);
		base_sram_data:inout std_logic_vector(31 downto 0);
		data_read:out std_logic_vector(31 downto 0);
		data_wrote:in std_logic_vector(31 downto 0)
	);
end sram_controller;

architecture bhv of sram_controller is
begin
	base_sram_addr <= addr;
	
	process(clk_0)
	begin
		if clk_0'event and clk_0 = '1' then
			if rwselect = '0' then
				base_sram_we <= '1';
				base_sram_oe <= '0';
				base_sram_ce <= '0';
				data_read <= base_sram_data;
				base_sram_data <= (others => 'Z');
			else
				base_sram_we <= '0';
				base_sram_ce <= '0';
				base_sram_oe <= '1';
				base_sram_data <= data_wrote;
			end if;
		end if;
	end process;
	
end bhv;