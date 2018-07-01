library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library my_lib;
use my_lib.data_type.all;

entity color_controller is
	port(		
		clk_0: in std_logic; --100MHz
		clk_w : in std_logic;  --60Hz
		reset: in std_logic;
		hs,vs:out std_logic;
		r,g,b  : out std_logic_vector(2 downto 0);
		
		object_types: in object_type_array;
      	object_xs: in object_x_array;
      	object_ys: in object_y_array;
      	object_statuses: in object_status_array;
		object_values: in object_value_array;
		-- 玩家的数据
		player_hp: in integer range 0 to PLAYER_HP_LIMIT;
		-- 枪支相关的数据
		bullet_num: in integer;
		show_fired: in std_logic;
		-- 用于表示是否处于开始界面
		start_stage: in std_logic;
		gameover:in std_logic;
		game_winning: in std_logic;
		
		--POST
		postX:in std_logic_vector(9 downto 0);
		postY:in std_logic_vector(8 downto 0);
		post_select:in std_logic;  --准星选中，开火或者选物品
		
		base_sram_we, base_sram_oe, base_sram_ce : out std_logic;
		base_sram_addr : out std_logic_vector(19 downto 0);
		base_sram_data : inout std_logic_vector(31 downto 0);
		
		data_safe: out std_logic
	);
end entity;


architecture bhv of color_controller is
	
	component vga_calc is
		port(
		--sys
		clk_0:in std_logic;  --100MHz
		reset : std_logic;
		hs, vs :out std_logic;
		r,g,b : out std_logic_vector(2 downto 0);
		
		--status
		gamestart:in std_logic;
		gameover:in std_logic;
		game_winning:in std_logic;
		
		--POST
		postX:in std_logic_vector(9 downto 0);
		postY:in std_logic_vector(8 downto 0);
		post_select:in std_logic;  --准星选中，开火或者选物品
		
		--ME
		my_hp :in integer range 0 to 100;
		bullet_num:in integer range 0 to 100;
		me_firing:in std_logic;
		
		object_types: in object_type_array;
        object_xs: in object_x_array;
        object_ys: in object_y_array;
        object_statuses: in object_status_array;
        object_values: in object_value_array;
		
		base_sram_we, base_sram_oe, base_sram_ce : out std_logic;
		base_sram_addr : out std_logic_vector(19 downto 0);
		base_sram_data : inout std_logic_vector(31 downto 0);
		
		data_safe:out std_logic
	);
	end component;
	
begin
	u1:vga_calc port map(
								clk_0, reset, hs, vs, r, g, b, start_stage, gameover, game_winning,
								postX, postY, show_fired, player_hp, bullet_num,
								show_fired, object_types, object_xs, object_ys, object_statuses, object_values, base_sram_we, 
								base_sram_oe, base_sram_ce, base_sram_addr, base_sram_data, data_safe
							);

end bhv;
