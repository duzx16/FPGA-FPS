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
	
	shared variable isBoarderPixel, isPostPixel ,isHpPixel, isGunPixel, isMedicalPixel,
						 isMePixel, isBulletNumPixel, isenemyPixel, isGameStartPixel, isGameOverPixel,
						 isBackgroundPixel:std_logic;
	
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
		isboarderPixel := '1';
	else
		isboarderPixel := '0';
	end if;
end process;
-------------------------------HP------------------------------------
process(clk_0)
begin
	if(s_x >= hpStart_x and s_x <= hpEnd_x and s_y >= hpStart_y and s_y <= hpEnd_y) then
		if(CONV_INTEGER(s_x - hpStart_x) * PLAYER_HP_LIMIT <= my_hp * 20) then
			isHpPixel := '1';
		else
			isHpPixel := '0';
		end if;
	else
		isHpPixel := '0';
	end if;
end process;
----------------------------bulletNUM--------------------------------
process(clk_0)
begin
	if(s_x >= BullnumStart_x and s_x <= BullnumEnd_x and s_y >= BullnumStart_y and s_y <= BullnumEnd_y) then
		if(CONV_INTEGER(s_x - BullnumStart_x) * BULLET_NUM_LIMIT <= bullet_num * 20) then
			isBulletNumPixel := '1';
		else
			isBulletNumPixel := '0';
		end if;
	else
		isBulletNumPixel := '0';
	end if;
end process;
------------------------------POST-----------------------------------
process(clk_0)
begin
	if(postX <= s_x + 3 and s_x <= postX + 3 and postY <= s_y + 3 and s_y <= postY + 3) then
		isPostPixel := '1';
	else
		isPostPixel := '0';
	end if;
end process;

-----------------------gun & medical & enemy-------------------------
process(clk_0)
begin
	gunOK <= '0';
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
			when tommygun=>
				if(object_xs(cnt) <= s_x + HGUN_WIDTH and s_x < object_xs(cnt) + HGUN_WIDTH and object_ys(cnt) <= s_y + HGUN_HEIGHT and s_y < object_ys(cnt) + HGUN_HEIGHT) then
					gun_x <= s_x + HGUN_WIDTH - object_xs(cnt);
					gun_y <= s_y + HGUN_HEIGHT - object_ys(cnt);
					gunOK <= '1';
					exit get_obj;
				end if;
			when none => next get_obj;
		end case;
	end loop get_obj;
end process;
-----------------------------Me--------------------------------------
process(clk_0)
begin
	if(s_x >= MeStartX and s_x <= MeEndX and s_y >= MeStartY and s_y <= MeEndY) then
		isMePixel := '1';
	else
		isMePixel := '0';
	end if;
end process;
---------------------------Gameover-----------------------------------
process(clk_0)
begin
	if gameover = '1' then
		isGameOverPixel := '1';
	else
		isGameOverPixel := '0';
	end if;
end process;
---------------------------GameStart----------------------------------
process(clk_0)
begin
	if gamestart = '1' then
		isGameStartPixel := '1';
	else
		isGameStartPixel := '0';
	end if;
end process;
----------------------------------------------------------------------
--++++++++++++++++++++++++  SRAM DATA ++++++++++++++++++++++++++++++++
process(clk50, addr_cnt, reset)
begin
	----------------------- background --------------------------
	backgroundOK <= '0';
	if clk50'event and clk50 = '1' then
		if s_x < 640 and s_y < 480 then			
			background_addr <= CONV_STD_LOGIC_VECTOR(conV_INTEGER(s_x) / 2 + conV_INTEGER(s_y) * 320, 20);
			addr_cnt <= background_addr;
			if background_addr(0) = '0' then
				q_background_calc <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
			else
				q_background_calc <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
			end if;
			if(q_background_calc = 0) then
				isBackgroundPixel := '0';
			else
				isBackgroundPixel := '1';
			end if;
		end if;
	end if;
	backgroundOK <= '1';
	
	-------------------------------------------------------------
end process;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

----------------------Connect2VGA640480------------------------------
process(clk_0)
begin
	if(isBoarderPixel = '1') then
		q_vga <= "0111111111";
	end if;
	-------------------TODO-----------------------
	if(isBackgroundPixel = '1' and backgroundOK = '1') then
		q_vga <= q_background_calc;
	end if;
	
	if(gamestart = '1') then                           
		if(isGameStartPixel = '1') then
			q_vga <= "0111111000";
		else
			q_vga <= "0000001001";
		end if;
	elsif(gameover = '1') then
		if isGameOverPixel <= '1' then
			q_vga <= "0111000000";
		else
			q_vga <= "0000001001";
		end if;
	else
		if(isHpPixel = '1') then   --血量红色
			q_vga <= "0111000000";
		elsif(isBulletNumPixel = '1') then  --子弹量蓝色
			q_vga <= "0000000111";
		elsif(isPostPixel = '1') then  --准星黑色
			q_vga <= "0000000000";
		elsif(gunOK = '1')then  --枪橙色
			q_vga <= "0111100001";
		elsif(medicalOK = '1') then  --医药包红色
			q_vga <= "0111000000";
		elsif(isMePixel = '1') then  --我绿色
			q_vga <= "0000111000";
		elsif(enemyOK = '1') then  --敌人黄色
			q_vga <= "0111111000";
		else
			q_vga <= q_background_calc;
		end if;
	end if;
end process;
---------------------------------------------------------------------
end bhv;