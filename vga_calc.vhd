library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library my_lib;
use my_lib.data_type.all;

entity vga_calc is
	port(
		--sys
		clk_0:in std_logic;  --100MHz
		reset : in std_logic;
		hs, vs :out std_logic;
		r,g,b : out std_logic_vector(2 downto 0);
		
		--status
		gamestart:in std_logic;
		gameover:in std_logic;
		
		--POST
		postX:in std_logic_vector(9 downto 0);
		postY:in std_logic_vector(8 downto 0);
		post_select:in std_logic;  --开火与选取物品
		
		--hp and bullet and fire
		my_hp :in integer range 0 to 100;
		bullet_num:in integer range 0 to 100;
		me_firing:in std_logic;
		
		object_types: in object_type_array;
        object_xs: in object_x_array;
        object_ys: in object_y_array;
        object_statuses: in object_status_array;
		
		base_sram_we, base_sram_oe, base_sram_ce : out std_logic;
		base_sram_addr : out std_logic_vector(19 downto 0);
		base_sram_data : inout std_logic_vector(31 downto 0);
		
		data_safe:out std_logic
	);
	end vga_calc;
	
architecture bhv of vga_calc is
	component vga640480 is
		port(
			reset       :         in  STD_LOGIC;
			clk_0       :         in  STD_LOGIC; --100M时钟
			hs,vs       :         out STD_LOGIC; --行同步信号场同步信号
			vector_x_out   :   out std_LOGIC_VECTOR(9 downto 0);
			vector_y_out :     out std_LOGIC_vector(8 downto 0);
			clk50 : out std_logic;
			data_safe:out std_logic;
			q : in std_logic_vector(9 downto 0);
			r,g,b : out std_logic_vector(2 downto 0)
		);
	end component;
	
	component sram_controller is
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
	end component;
	
	signal s_x:std_logic_vector(9 downto 0);
	signal s_y:std_logic_vector(8 downto 0);
	signal clk50:std_logic;
	signal q_vga:std_LOGIC_vector(9 downto 0);
	
	type GUN_PIXEL_LIMIT is array(0 to 2 * HGUN_HEIGHT - 1) of integer range 0 to 2 * HGUN_WIDTH;
	type ME_PIXEL_LIMIT is array(0 to 159) of integer range 0 to 160;
	type ENEMY_PIXEL_LIMIT is array(0 to 2 * HENEMY_HEIGHT - 1) of integer range 0 to 2 * HENEMY_WIDTH;

	constant enemy_no_pixel_left1: ENEMY_PIXEL_LIMIT := (14,12,11,9,9,9,9,9,9,9,10,10,10,9,11,8,8,8,7,7,6,6,5,5,5,4,3,3,2,2,2,1,2,3,4,14,14,14,14,15,15,15,15,15,15,15,15,15,15,14,13,11,10,9,8,7,6,6,5,4,4,3,3,2,2,1,1,1,1,1,1,1,1,2,3,30,30,31,32,34);
	constant enemy_no_pixel_right1: ENEMY_PIXEL_LIMIT := (19,20,21,22,23,24,24,25,25,26,26,26,26,29,36,36,36,36,42,41,41,41,42,43,43,43,44,43,43,42,42,43,9,9,7,45,45,39,37,37,37,37,37,37,39,40,41,41,42,42,42,42,41,41,41,40,40,41,41,41,40,41,41,41,41,24,21,19,18,16,14,11,9,7,4,41,40,39,38,37);
	constant enemy_no_pixel_left2: ENEMY_PIXEL_LIMIT := (32,31,30,29,29,29,29,30,31,31,31,32,32,33,41,41,40,40,1,1,1,1,1,1,1,1,1,1,1,1,1,1,11,12,13,1,1,41,42,42,43,43,43,43,42,47,47,47,48,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,29,29,29,29,29,29,29,29,29,29,1,1,1,1,1);
	constant enemy_no_pixel_right2: ENEMY_PIXEL_LIMIT := (35,36,36,36,36,36,36,35,35,36,36,36,36,36,43,43,42,42,0,0,0,0,0,0,0,0,0,0,0,0,0,0,43,44,44,0,0,45,46,46,46,47,47,46,44,47,47,48,48,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,41,41,41,41,41,41,41,41,41,41,0,0,0,0,0);
	
	constant me_fire_pixel_left1: ME_PIXEL_LIMIT := (60,58,58,57,57,57,57,58,59,60,61,62,64,64,63,63,62,62,61,61,53,51,50,50,50,50,49,49,49,49,48,48,48,48,47,47,47,47,46,46,46,46,45,45,45,45,44,44,44,44,43,43,43,43,42,42,42,42,41,41,41,41,40,40,40,40,39,38,32,31,29,28,26,25,23,20,18,14,12,10,7,6,5,4,3,2,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
	constant me_fire_pixel_right1: ME_PIXEL_LIMIT := (63,64,66,67,68,70,71,73,74,75,76,78,79,81,82,83,85,86,87,87,58,86,86,80,79,79,78,78,78,77,77,77,76,77,79,79,79,78,78,78,77,77,76,76,75,75,74,74,74,73,73,72,72,71,71,70,70,69,69,68,68,68,67,67,66,66,65,65,64,64,64,152,152,152,152,152,151,150,149,149,149,148,148,147,146,143,137,136,136,136,136,136,136,135,135,135,135,136,136,136,136,136,136,136,136,135,135,134,134,134,134,134,134,135,135,136,136,137,137,138,138,139,139,140,141,141,142,142,142,143,144,144,145,145,146,146,147,148,148,148,149,149,149,149,149,149,149,149,148,147,146,107,107,106,106,105,104,109,109,110);
	constant me_fire_pixel_left2: ME_PIXEL_LIMIT := (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,60,102,101,100,100,99,97,94,92,89,89,88,88,87,86,86,86,85,84,84,83,82,81,80,79,79,78,78,78,77,77,77,77,78,79,80,80,79,79,79,78,77,76,75,74,73,72,71,71,68,66,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,110,111,112,113,114,115,117,118,118);
	constant me_fire_pixel_right2: ME_PIXEL_LIMIT := (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,86,117,118,119,120,121,121,122,122,122,123,123,125,126,126,126,126,126,126,126,126,126,127,127,127,127,127,127,127,127,127,127,127,127,126,126,126,127,130,131,134,135,136,137,157,156,155,154,153,153,152,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,145,143,142,141,140,139,138,137,136);
	
	constant me_no_pixel_left1: ME_PIXEL_LIMIT := (127,127,126,126,125,125,124,124,123,123,122,121,119,118,116,115,114,93,92,92,92,92,92,91,91,91,91,91,92,92,92,92,92,92,91,91,90,89,88,82,78,75,74,71,68,66,63,60,56,54,53,51,49,48,46,44,43,41,40,38,37,35,33,31,29,27,25,24,23,21,20,19,17,16,16,15,15,14,14,13,12,12,11,11,11,10,10,10,9,9,9,8,8,8,8,7,7,7,7,7,6,6,6,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,5,5,6,6,7,7,8,9,10,11,11,12,13,13,12,12,11,10,9,8,7,7,6,6,6,5,4,4,4,3,2,2,1,1,1,0);
	constant me_no_pixel_right1: ME_PIXEL_LIMIT := (28,129,130,131,131,131,132,133,134,134,137,139,140,140,140,140,140,100,101,101,101,101,101,101,101,101,101,101,101,101,101,101,102,143,143,143,142,142,142,146,147,148,148,149,149,150,150,150,150,149,147,147,147,152,152,153,153,153,153,152,151,150,151,151,151,151,151,151,150,150,149,149,148,148,148,148,147,147,147,148,148,147,147,146,146,146,145,145,145,145,145,146,146,146,147,148,149,150,151,153,155,155,156,156,156,157,157,157,128,124,124,124,124,124,124,124,124,124,124,124,124,123,122,122,121,121,120,120,119,119,118,117,117,116,115,114,111,111,111,111,111,111,111,111,111,110,110,110,108,98,97,97,97,96,95,95,95,95,95,95);
	constant me_no_pixel_left2: ME_PIXEL_LIMIT := (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,113,113,112,111,110,109,108,108,107,107,107,107,107,106,106,105,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,130,132,133,134,135,136,136,136,137,138,139,140,140,141,141,141,142,143,145,146,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,103,1,1,1,1,1,1,1,1,1,1);
	constant me_no_pixel_right2: ME_PIXEL_LIMIT := (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,140,139,140,140,141,141,142,142,143,143,143,143,143,143,143,143,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,157,157,157,158,158,158,158,158,158,158,158,158,158,157,157,157,156,155,155,152,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,106,0,0,0,0,0,0,0,0,0,0);

	constant gun_pixel_left1: GUN_PIXEL_LIMIT := (18,18,18,18,17,16,3,0,0,15,17,41,41,41,41,41,40,41,41,41,40,40,40,40,40,39,39,39,40,42);
	constant gun_pixel_right1: GUN_PIXEL_LIMIT := (19,19,19,20,58,58,4,88,90,61,60,59,57,56,57,57,58,46,46,46,46,46,46,46,45,45,45,44,44,44);
	constant gun_pixel_left2: GUN_PIXEL_LIMIT := (51,51,51,51,1,84,1,1,1,65,68,70,71,76,77,78,79,80,81,82,55,55,56,56,56,1,1,1,1,1);
	constant gun_pixel_right2: GUN_PIXEL_LIMIT := (53,54,54,54,0,87,0,0,0,90,90,90,90,90,88,88,88,88,87,87,60,60,60,61,61,0,0,0,0,0);

	constant hpStart_x:std_LOGIC_vector(9 downto 0) := "1001011000";
	constant hpEnd_x:std_LOGIC_vector(9 downto 0) := "1001101100";
	constant hpStart_y:std_LOGIC_vector(8 downto 0) := "000010100";
	constant hpEnd_y:std_logic_vector(8 downto 0) := "000011110";
	
	constant BullnumStart_x:std_LOGIC_vector(9 downto 0) := "1001011000";
	constant BullnumEnd_x:std_LOGIC_vector(9 downto 0) := "1001101100";
	constant BullnumStart_y:std_LOGIC_vector(8 downto 0) := "111000010";
	constant BullnumEnd_y:std_logic_vector(8 downto 0) := "111001100";
	
	constant MeStartX:std_logic_vector(9 downto 0):="0000010100";
	constant MeEndX : std_logic_vector(9 downto 0):="0010110011";
	constant MeStartY:std_logic_vector(8 downto 0):="101000000";
	constant MeEndY : std_logic_vector(8 downto 0):="111011111";
	
	signal boarderOK, postOK, HpOK, enemyHPOK, gunOK, medicalOK, meOK, bulletnumOK, enemyOK, gamestartOK, 
				gameoverOK, backgroundOK:std_logic;
				
	signal enemy_x, medical_x, gun_x:std_logic_vector(9 downto 0);
	signal enemy_y, medical_y, gun_y:std_logic_vector(8 downto 0);

	signal gun_cnt, enemy_cnt, medical_cnt: integer range 0 to OBJECT_LIMIT;

	shared variable cnt: integer := 0;
	
	signal rwselect:std_logic;
	signal addr_cnt:std_logic_vector(19 downto 0);
	signal data_read, data_wrote : std_logic_vector(31 downto 0);
	
	signal q_background_calc:std_logic_vector(9 downto 0);
	signal background_addr:std_logic_vector(19 downto 0):= (others=>'0');
	signal clk25:std_logic;
begin
	
	rwselect <= '0';
	
	u1:vga640480 port map(
									reset=>reset,
									clk_0=>clk_0,
									hs=>hs,vs=>vs,
									vector_x_out=>s_x,
									vector_y_out=>s_y,
									clk50=>clk50,
									data_safe=>data_safe,
									q=>q_vga,
									r=>r,g=>g,b=>b
								);
	u2:sram_controller port map
								(
									clk_0=> clk50,
									rwselect=> rwselect,
									addr=> addr_cnt,
									base_sram_we=> base_sram_we,
									base_sram_oe=> base_sram_oe,
									base_sram_ce=> base_sram_ce,
									base_sram_addr=> base_sram_addr,
									base_sram_data=> base_sram_data,
									data_read=> data_read,
									data_wrote=> data_wrote
								);
-----------------------------Boarder---------------------------------
process(clk_0)
begin
	if(s_x = 0 or s_y = 0 or s_x = 638 or s_y = 479) then
		BoarderOK <= '1';
	else
		BoarderOK <= '0';
	end if;
end process;
-------------------------------HP------------------------------------
process(clk_0)
begin
	if(s_x >= hpStart_x and s_x <= hpEnd_x and s_y >= hpStart_y and s_y <= hpEnd_y) then
		if(CONV_INTEGER(s_x - hpStart_x) * PLAYER_HP_LIMIT <= my_hp * 20) then
			HpOK <= '1';
		else
			HpOK <= '0';
		end if;
	else
		HpOK <= '0';
	end if;
end process;
----------------------------bulletNUM--------------------------------
process(clk_0)
begin
	if(s_x >= BullnumStart_x and s_x <= BullnumEnd_x and s_y >= BullnumStart_y and s_y <= BullnumEnd_y) then
		if(CONV_INTEGER(s_x - BullnumStart_x) * BULLET_NUM_LIMIT <= bullet_num * 20) then
			BulletnumOK <= '1';
		else
			BulletnumOK <= '0';
		end if;
	else
		BulletnumOK <= '0';
	end if;
end process;

------------------------------POST-----------------------------------
process(clk_0)
begin
	if(postX <= s_x + 3 and s_x <= postX + 3 and postY <= s_y + 3 and s_y <= postY + 3) then
		PostOK <= '1';
	else
		PostOK <= '0';
	end if;
end process;


--------------------gun----------------------------
process(clk_0)
variable temp_x: integer range 0 to X_LIMIT;
variable temp_y: integer range 0 to Y_LIMIT;
begin
	gunOK <= '0';
	get_obj:for cnt in 0 to OBJECT_LIMIT - 1 loop
		if object_types(cnt) = tommygun then
				if(object_ys(cnt) <= s_y + HGUN_HEIGHT and s_y < object_ys(cnt) + HGUN_HEIGHT and object_xs(cnt) <= s_x + HGUN_WIDTH and s_x < object_xs(cnt) + HGUN_WIDTH) then
					temp_x := CONV_INTEGER(s_x) + HGUN_WIDTH - object_xs(cnt);
					temp_y := CONV_INTEGER(s_y) + HGUN_HEIGHT - object_ys(cnt);
					if (temp_x >= gun_pixel_left1(temp_y) and temp_x <= gun_pixel_right1(temp_y)) or (temp_x >= gun_pixel_left2(temp_y) and temp_x <= gun_pixel_right2(temp_y)) then
						gun_x <= CONV_STD_LOGIC_VECTOR(temp_x, 10);
						gun_y <= CONV_STD_LOGIC_VECTOR(temp_y, 9);
						gunOK <= '1';
						gun_cnt <= cnt;
						exit get_obj;
					end if;
				end if;
		end if;
	end loop get_obj;
end process;


--------------------enemy------------------------
process(clk_0)
variable temp_x: integer range 0 to X_LIMIT;
variable temp_y: integer range 0 to Y_LIMIT;
begin
	enemyOK <= '0';
	get_obj:for cnt in 0 to OBJECT_LIMIT - 1 loop
		if object_types(cnt) = enemy then
				if(object_ys(cnt) <= s_y + HENEMY_HEIGHT and s_y < object_ys(cnt) + HENEMY_HEIGHT and object_xs(cnt) <= s_x + HENEMY_WIDTH and s_x < object_xs(cnt) + HENEMY_WIDTH) then
					temp_x := CONV_INTEGER(s_x) + HENEMY_WIDTH - object_xs(cnt);
					temp_y := CONV_INTEGER(s_y) + HENEMY_HEIGHT - object_ys(cnt);
					if object_statuses(cnt) = attack then 
						if (temp_x >= enemy_no_pixel_left1(temp_y) and temp_x <= enemy_no_pixel_right1(temp_y)) or (temp_x >= enemy_no_pixel_left2(temp_y) and temp_x <= enemy_no_pixel_right2(temp_y)) then
							enemy_x <= CONV_STD_LOGIC_VECTOR(temp_x, 10);
							enemy_y <= CONV_STD_LOGIC_VECTOR(temp_y, 9);
							enemyOK <= '1';
							enemy_cnt <= cnt;
							exit get_obj;
						end if;
					else
						if (temp_x >= enemy_no_pixel_left1(temp_y) and temp_x <= enemy_no_pixel_right1(temp_y)) or (temp_x >= enemy_no_pixel_left2(temp_y) and temp_x <= enemy_no_pixel_right2(temp_y)) then
							enemy_x <= CONV_STD_LOGIC_VECTOR(temp_x, 10);
							enemy_y <= CONV_STD_LOGIC_VECTOR(temp_y, 9);
							enemyOK <= '1';
							enemy_cnt <= cnt;
							exit get_obj;
						end if;
					end if;
				end if;
		end if;
	end loop get_obj;
end process;

-----------------------medical-------------------------
process(clk_0)
begin
	medicalOK <= '0';
	get_obj:for cnt in 0 to OBJECT_LIMIT - 1 loop
		case object_types(cnt) is
			when medical=>
				if(object_xs(cnt) <= s_x + HMEDICAL_WIDTH and s_x < object_xs(cnt) + HMEDICAL_WIDTH and object_ys(cnt) <= s_y + HMEDICAL_HEIGHT and s_y < object_ys(cnt) + HMEDICAL_HEIGHT) then
					medical_x <= s_x + HMEDICAL_WIDTH - object_xs(cnt);
					medical_y <= s_y + HMEDICAL_HEIGHT - object_ys(cnt);
					medicalOK <= '1';
					medical_cnt <= cnt;
					exit get_obj;
				end if;
			when others => next get_obj;
		end case;
	end loop get_obj;
end process;
-----------------------------Me--------------------------------------
process(clk_0)
variable temp_x: integer range 0 to X_LIMIT;
variable temp_y: integer range 0 to Y_LIMIT;
begin
	MeOK <= '0';
	if(s_y >= MeStartY and s_y <= MeEndY and s_x >= MeStartX and s_x <= MeEndX) then
		temp_x := CONV_INTEGER(s_x - MeStartX);
		temp_y := CONV_INTEGER(s_y - MeStartY);
		if me_firing = '1' then
			if ((temp_x >= me_fire_pixel_left1(temp_y) and temp_x <= me_fire_pixel_right1(temp_y)) or (temp_x >= me_fire_pixel_left2(temp_y) and temp_x <= me_fire_pixel_right2(temp_y))) then
				MeOK <= '1';
			end if;
		else
			if ((temp_x >= me_no_pixel_left1(temp_y) and temp_x <= me_no_pixel_right1(temp_y)) or (temp_x >= me_no_pixel_left2(temp_y) and temp_x <= me_no_pixel_right2(temp_y))) then
				MeOK <= '1';
			end if;
		end if;
	end if;
end process;
---------------------------Gameover-----------------------------------
process(clk_0)
begin
	if gameover = '1' then
		GameoverOK <= '1';
	else
		GameoverOK <= '0';
	end if;
end process;
---------------------------GameStart----------------------------------
process(clk_0)
begin
	if gamestart = '1' then
		GamestartOK <= '1';
	else
		GamestartOK <= '0';
	end if;
end process;
----------------------------------------------------------------------
--++++++++++++++++++++++++  SRAM DATA ++++++++++++++++++++++++++++++++
process(clk50, addr_cnt, reset)
begin
	----------------------- background --------------------------
	if clk50'event and clk50 = '1' then
		if(MeOK = '1') then
			if me_firing = '1' then
				background_addr <= conV_STD_LOGIC_VECTOR(conV_INTEGER(s_x - MeStartX) / 2 + conV_INTEGER(s_y - MestartY) * 80, 20) + ME_ADDR_BEGIN;
				addr_cnt <= background_addr;
				if background_addr(0) = '0' then
					q_background_calc <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
				else
					q_background_calc <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
				end if;
			elsif me_firing = '0' then
				background_addr <= conV_STD_LOGIC_VECTOR(conV_INTEGER(s_x - MeStartX) / 2 + conV_INTEGER(s_y - MestartY) * 80, 20) + ME_NO_FIRE_START;
				addr_cnt <= background_addr;
				if background_addr(0) = '0' then
					q_background_calc <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
				else
					q_background_calc <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
				end if;
			end if;
			
		elsif(gunOK = '1') then
			if(object_statuses(gun_cnt) = selected) then
				background_addr <= conV_STD_LOGIC_VECTOR(conV_INTEGER(s_x - (object_xs(gun_cnt) - HGUN_WIDTH)) / 2 + 
					conV_INTEGER(s_y - (object_ys(gun_cnt) - HGUN_HEIGHT)) * HGUN_WIDTH, 20) + GUN_ADDR_BEGIN;
				addr_cnt <= background_addr;
				if background_addr(0) = '0' then
					q_background_calc <= "0" & "111" & data_read(28 downto 26) & data_read(25 downto 23);
				else
					q_background_calc <= "0" & "111" & data_read(12 downto 10) & data_read(9 downto 7);
				end if;
			else
				background_addr <= conV_STD_LOGIC_VECTOR(conV_INTEGER(s_x - (object_xs(gun_cnt) - HGUN_WIDTH)) / 2 + 
					conV_INTEGER(s_y - (object_ys(gun_cnt) - HGUN_HEIGHT)) * HGUN_WIDTH, 20) + GUN_ADDR_BEGIN;
				addr_cnt <= background_addr;
				if background_addr(0) = '0' then
					q_background_calc <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
				else
					q_background_calc <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
				end if;
			end if;
		elsif(enemyOK = '1') then
			if(object_statuses(enemy_cnt) = selected) then
				background_addr <= conV_STD_LOGIC_VECTOR(conV_INTEGER(s_x - (object_xs(enemy_cnt) - HENEMY_WIDTH)) / 2 + 
					conV_INTEGER(s_y - (object_ys(enemy_cnt) - HENEMY_HEIGHT)) * HENEMY_WIDTH, 20) + ENEMY_ADDR_BEGIN;
				addr_cnt <= background_addr;
				if background_addr(0) = '0' then
					q_background_calc <= "0" & "111" & data_read(28 downto 26) & data_read(25 downto 23);
				else
					q_background_calc <= "0" & "111" & data_read(12 downto 10) & data_read(9 downto 7);
				end if;
			elsif(object_statuses(enemy_cnt) = attack) then
				background_addr <= conV_STD_LOGIC_VECTOR(conV_INTEGER(s_x - (object_xs(enemy_cnt) - HENEMY_WIDTH)) / 2 + 
					conV_INTEGER(s_y - (object_ys(enemy_cnt) - HENEMY_HEIGHT)) * HENEMY_WIDTH, 20) + ENEMY_FIRE_ADDR_BEGIN;
				addr_cnt <= background_addr;
				if background_addr(0) = '0' then
					q_background_calc <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
				else
					q_background_calc <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
				end if;
			else
				background_addr <= conV_STD_LOGIC_VECTOR(conV_INTEGER(s_x - (object_xs(enemy_cnt) - HENEMY_WIDTH)) / 2 + 
					conV_INTEGER(s_y - (object_ys(enemy_cnt) - HENEMY_HEIGHT)) * HENEMY_WIDTH, 20) + ENEMY_ADDR_BEGIN;
				addr_cnt <= background_addr;
				if background_addr(0) = '0' then
					q_background_calc <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
				else
					q_background_calc <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
				end if;
			end if;
		elsif(medicalOK = '1') then
			if(object_statuses(medical_cnt) = selected) then
				background_addr <= conV_STD_LOGIC_VECTOR(conV_INTEGER(s_x - (object_xs(medical_cnt) - HMEDICAL_WIDTH)) / 2 + 
					conV_INTEGER(s_y - (object_ys(medical_cnt) - HMEDICAL_HEIGHT)) * HMEDICAL_WIDTH, 20) + MEDICAL_ADDR_BEGIN;
				addr_cnt <= background_addr;
				if background_addr(0) = '0' then
					q_background_calc <= "0" & "111" & data_read(28 downto 26) & data_read(25 downto 23);
				else
					q_background_calc <= "0" & "111" & data_read(12 downto 10) & data_read(9 downto 7);
				end if;
			else
				background_addr <= conV_STD_LOGIC_VECTOR(conV_INTEGER(s_x - (object_xs(medical_cnt) - HMEDICAL_WIDTH)) / 2 + 
					conV_INTEGER(s_y - (object_ys(medical_cnt) - HMEDICAL_HEIGHT)) * HMEDICAL_WIDTH, 20) + MEDICAL_ADDR_BEGIN;
				addr_cnt <= background_addr;
				if background_addr(0) = '0' then
					q_background_calc <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
				else
					q_background_calc <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
				end if;
			end if;
		elsif s_x < 640 and s_y < 480 then			
			background_addr <= CONV_STD_LOGIC_VECTOR(conV_INTEGER(s_x) / 2 + conV_INTEGER(s_y) * 320, 20);
			addr_cnt <= background_addr;
			if background_addr(0) = '0' then
				q_background_calc <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
			else
				q_background_calc <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
			end if;
		else
			q_background_calc <= "0111111111";
		end if;
		
	end if;
	
	-------------------------------------------------------------
end process;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

----------------------Connect2VGA640480------------------------------
process(clk_0)
begin
	if(BoarderOK = '1') then
		q_vga <= "0111111111";
	end if;
	-------------------TODO-----------------------
	
	if(gamestart = '1') then                           
		if(GameoverOK = '1') then
			q_vga <= "0111111000";
		else
			q_vga <= "0000001001";
		end if;
	elsif(gameover = '1') then
		if GameoverOK <= '1' then
			q_vga <= "0111000000";
		else
			q_vga <= "0000001001";
		end if;
	else
		if(HpOK = '1') then   --血量红色
			q_vga <= "0111000000";
		elsif(BulletnumOK = '1') then  --子弹量蓝色
			q_vga <= "0000000111";
		elsif(PostOK = '1') then  --准星黑色
			q_vga <= q_background_calc;
		elsif(gunOK = '1')then  --枪橙色
			q_vga <= q_background_calc;
		elsif(medicalOK = '1') then  --医药包红色
			q_vga <= q_background_calc;
		elsif(MeOK = '1') then  --我绿色
			q_vga <= q_background_calc;
		elsif(enemyOK = '1') then  --敌人黄色
			q_vga <= q_background_calc;
		else
			q_vga <= q_background_calc;
		end if;
	end if;
end process;
---------------------------------------------------------------------
end bhv;