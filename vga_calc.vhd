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
	
	type ENEMY_PIXEL_LIMIT is array(0 to 29) of integer range 0 to 90;
	type ME_PIXEL_LIMIT is array(0 to 79) of integer range 0 to 80;
	constant enemy_pixel_left: ENEMY_PIXEL_LIMIT := (18, 18, 18, 18, 17, 16, 3, 0, 0, 15, 17, 41, 41, 41, 41, 41, 40, 41, 41, 41, 40, 40, 40, 40, 40, 39, 39, 39, 40, 42);
	constant enemy_pixel_right: ENEMY_PIXEL_LIMIT := (53, 54, 54, 54, 58, 87, 88, 88, 89, 89, 89, 89, 89, 89, 88, 88, 88, 88, 87, 87, 60, 60, 60, 61, 61, 45, 45, 44, 44, 44);
	
	constant me_pixel_left1: ME_PIXEL_LIMIT := (29,29,28,29,30,31,32,32,31,31,26,25,25,25,24,24,24,24,23,23,23,23,22,22,22,22,21,21,21,21,20,20,20,20,16,14,13,11,9,5,3,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
	constant me_pixel_right1: ME_PIXEL_LIMIT := (31,33,34,35,37,38,39,41,42,43,43,39,39,39,38,38,38,39,39,38,38,38,37,37,36,36,35,35,34,34,33,33,32,32,32,76,76,75,75,74,74,73,72,68,68,67,67,67,67,68,68,68,67,67,66,67,67,67,68,68,69,69,70,71,71,71,72,72,73,74,74,74,74,74,73,53,53,52,54,54);
	constant me_pixel_left2: ME_PIXEL_LIMIT := (0,0,0,0,0,0,0,0,0,0,54,50,50,48,45,44,44,43,43,42,41,40,39,39,39,39,39,40,40,40,39,38,37,36,35,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,55,56,57,58,59);
	constant me_pixel_right2: ME_PIXEL_LIMIT := (0,0,0,0,0,0,0,0,0,0,57,59,60,60,61,61,62,62,62,62,63,63,63,63,63,63,63,63,63,65,67,68,78,77,76,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,72,71,70,69,68);
	
	constant hpStart_x:std_LOGIC_vector(9 downto 0) := "1001011000";
	constant hpEnd_x:std_LOGIC_vector(9 downto 0) := "1001101100";
	constant hpStart_y:std_LOGIC_vector(8 downto 0) := "000010100";
	constant hpEnd_y:std_logic_vector(8 downto 0) := "000011110";
	
	constant BullnumStart_x:std_LOGIC_vector(9 downto 0) := "1001011000";
	constant BullnumEnd_x:std_LOGIC_vector(9 downto 0) := "1001101100";
	constant BullnumStart_y:std_LOGIC_vector(8 downto 0) := "111000010";
	constant BullnumEnd_y:std_logic_vector(8 downto 0) := "111001100";
	
	constant MeStartX:std_logic_vector(9 downto 0):="0100011000";
	constant MeEndX : std_logic_vector(9 downto 0):="0101100111";
	constant MeStartY:std_logic_vector(8 downto 0):="110010000";
	constant MeEndY : std_logic_vector(8 downto 0):="111011111";
	
	signal boarderOK, postOK, HpOK, gunOK, medicalOK, meOK, bulletnumOK, enemyOK, gamestartOK, 
				gameoverOK, backgroundOK:std_logic;
				
	signal enemy_x, medical_x, gun_x:std_logic_vector(9 downto 0);
	signal enemy_y, medical_y, gun_y:std_logic_vector(8 downto 0);
	
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
				if(object_ys(cnt) <= s_y + HGUN_HEIGHT and s_y < object_ys(cnt) + HGUN_HEIGHT) then
					temp_x := CONV_INTEGER(s_x) + HGUN_WIDTH - object_xs(cnt);
					temp_y := CONV_INTEGER(s_y) + HGUN_HEIGHT - object_ys(cnt);
					if temp_x >= enemy_pixel_left(temp_y) and temp_x <= enemy_pixel_right(temp_y) then
						gun_x <= CONV_STD_LOGIC_VECTOR(temp_x, 10);
						gun_y <= CONV_STD_LOGIC_VECTOR(temp_y, 9);
						gunOK <= '1';
						exit get_obj;
					end if;
				end if;
		end if;
	end loop get_obj;
end process;

-----------------------gun & medical & enemy-------------------------
process(clk_0)
begin
	enemyOK <= '0';
	medicalOK <= '0';
	get_obj:for cnt in 0 to OBJECT_LIMIT - 1 loop
		case object_types(cnt) is
			when enemy =>
				if(object_xs(cnt) <= s_x + HENEMY_WIDTH and s_x < object_xs(cnt) + HENEMY_WIDTH and object_ys(cnt) <= s_y + HENEMY_HEIGHT and s_y < object_ys(cnt) + HENEMY_HEIGHT) then
					enemy_x <= s_x + HENEMY_WIDTH - object_xs(cnt);
					enemy_y <= s_y + HENEMY_HEIGHT - object_ys(cnt);
					enemyOK <= '1';
					exit get_obj;
				end if;
			when medical=>
				if(object_xs(cnt) <= s_x + HMEDICAL_WIDTH and s_x < object_xs(cnt) + HMEDICAL_WIDTH and object_ys(cnt) <= s_y + HMEDICAL_HEIGHT and s_y < object_ys(cnt) + HMEDICAL_HEIGHT) then
					medical_x <= s_x + HMEDICAL_WIDTH - object_xs(cnt);
					medical_y <= s_y + HMEDICAL_HEIGHT - object_ys(cnt);
					medicalOK <= '1';
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
	if(s_y >= MeStartY and s_y <= MeEndY) then
		temp_x := CONV_INTEGER(s_x - MeStartX);
		temp_y := CONV_INTEGER(s_y - MeStartY);
		if ((temp_x >= me_pixel_left1(temp_y) and temp_x <= me_pixel_right1(temp_y)) or (temp_x >= me_pixel_left2(temp_y) and temp_x <= me_pixel_right2(temp_y))) then
			MeOK <= '1';
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
			background_addr <= conV_STD_LOGIC_VECTOR(conV_INTEGER(s_x - MeStartX) / 2 + conV_INTEGER(s_y - MestartY) * 40, 20) + ME_ADDR_BEGIN;
			addr_cnt <= background_addr;
			if background_addr(0) = '0' then
				q_background_calc <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
			else
				q_background_calc <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
			end if;
		elsif s_x < 640 and s_y < 480 then			
			background_addr <= CONV_STD_LOGIC_VECTOR(conV_INTEGER(s_x) / 2 + conV_INTEGER(s_y) * 320, 20);
			addr_cnt <= background_addr;
			if background_addr(0) = '0' then
				q_background_calc <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
			else
				q_background_calc <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
			end if;
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
			q_vga <= "0000000000";
		elsif(gunOK = '1')then  --枪橙色
			q_vga <= "0111100001";
		elsif(medicalOK = '1') then  --医药包红色
			q_vga <= "0111000000";
		elsif(MeOK = '1') then  --我绿色
			q_vga <= q_background_calc;
		elsif(enemyOK = '1') then  --敌人黄色
			q_vga <= "0111111000";
		else
			q_vga <= q_background_calc;
		end if;
	end if;
end process;
---------------------------------------------------------------------
end bhv;