library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library my_lib;
use my_lib.data_type.all;

--constant enemy_NUM : integer := 10;
--type enemy_type_matrix is array(enemy_NUM downto 0) of std_logic_vector(1 downto 0);

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
		post_select:in std_logic;  --鍑嗘槦閫変腑锛屽紑鐏垨鑰呴€夌墿鍝
		
		--ME
		--meX:in std_logic_vector(9 downto 0);
		--meY:in std_logic_vector(8 downto 0);
		my_hp :in integer range 0 to 100;
		bullet_num:in integer range 0 to 100;
		me_firing:in std_logic;
		
		--enemy
		--enemy_X: in std_logic_vector(9 downto 0);
		--enemy_Y : in std_logic_vector(8 downto 0);
		--enemy_type: in enemy_type_matrix; --寰呭畾
		--enemy_firing:in std_logic;
		
		--objs
		--medical_X:in std_logic_vector(9 downto 0);
		--medical_Y:in std_logic_vector(8 downto 0);
		--tommygun_X:in std_logic_vector(9 downto 0);
		--tommygun_Y:in std_logic_vector(8 downto 0);
		--object_statuses: in object_status_array;
		object_types: in object_type_array;
      object_xs: in object_x_array;
      object_ys: in object_y_array;
      object_statuses: in object_status_array;
		
		data_safe:out std_logic
	);
	end vga_calc;
	
architecture bhv of vga_calc is
	component vga640480 is
		port(
			reset       :         in  STD_LOGIC;
			clk_0       :         in  STD_LOGIC; --100M鏃堕挓杈撳叆
			hs,vs       :         out STD_LOGIC; --琛屽悓姝ャ€佸満鍚屾淇″彿
			vector_x_out   :   out std_LOGIC_VECTOR(9 downto 0);
			vector_y_out :     out std_LOGIC_vector(8 downto 0);
			clk50 : out std_logic;
			data_safe:out std_logic;
			q : in std_logic_vector(9 downto 0);
			r,g,b : out std_logic_vector(2 downto 0)
		);
	end component;
	
	--component digital_rom is
		--port(
		--	address:in std_logic_vector(15 downto 0);
			--clock:in std_logic;
--			q:out std_logic_vector(9 downto 0)
	--	);
	--end component;
	
	signal s_x:std_logic_vector(9 downto 0);
	signal s_y:std_logic_vector(8 downto 0);
	signal clk50:std_logic;
	signal q_vga:std_LOGIC_vector(9 downto 0);
	signal address_tmp16:std_LOGIC_vector(15 downto 0);
	signal q_tmp10:std_logic_vector(9 downto 0);
	
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
						 isMePixel, isBulletNumPixel, isenemyPixel, isGameStartPixel, isGameOverPixel:std_logic;
	
	signal boarderOK, postOK, HpOK, gunOK, medicalOK, meOK, bulletnumOK, enemyOK, gamestartOK, gameoverOK:std_logic;
	signal enemy_x, medical_x, gun_x:std_logic_vector(9 downto 0);
	signal enemy_y, medical_y, gun_y:std_logic_vector(8 downto 0);
	
	shared variable cnt: integer := 0;
begin
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
	--u2:digital_rom port map(
		--							address=>address_tmp16,
			--						clock=>clk50,
				--					q=>q_tmp10
					--			);
				
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

----------------------------tommygun---------------------------------
--process(clk_0)
--begin
	--gunOK <= '0';
		--if(tommygun_X <= s_x + 3 and s_x <= tommygun_X + 3 and tommygun_Y <= s_y + 3 and s_y <= tommygun_Y + 3) then
			--isGunPixel <= '1';
--		else
	--		isGunPixel <= '0';
		--end if;
--	gunOK <= '1';
--end process;

---------------------------Medical-----------------------------------
--process(clk_0)
--begin
	--medicalOK <= '0';
		--if(medical_X <= s_x + 3 and s_x <= medical_X + 3 and medical_Y <= s_y + 3 and s_y <= medical_Y + 3) then
			--isMedicalPixel <= '1';
--		else
	--		isMedicalPixel <= '0';
		--end if;
--	medicalOK <= '1';
--end process;
---------------------------enemy------------------------------------
--process(clk_0)
--begin
	--enemyOK <= '0';
	--if(enemy_X <= s_x + 3 and s_x <= enemy_X + 3 and enemy_Y <= s_y + 3 and s_y <= enemy_Y + 3) then
		--isenemyPixel <= '1';
--	else
	--	isenemyPixel <= '0';
 	--end if;
	  --enemyOK <= '1';
--end process;
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


----------------------Connect2VGA640480------------------------------
process(clk_0)
begin
	if(isBoarderPixel = '1') then
		q_vga <= "0111111111";
	end if;
	
	-------------------TODO-----------------------
	-----------娓告垙寮€濮嬫槸榛勮壊鐣岄潰------------
	if(gamestart = '1') then                           
		if(isGameStartPixel = '1') then
			q_vga <= "0111111000";
		else
			q_vga <= "0000001001";
		end if;
	-----------娓告垙寮€濮嬫槸绾㈣壊鐣岄潰------------
	elsif(gameover = '1') then
		if isGameOverPixel <= '1' then
			q_vga <= "0111000000";
		else
			q_vga <= "0000001001";
		end if;
	else
		if(isHpPixel = '1') then   --琛€閲忕孩鑹
			q_vga <= "0111000000";
		---------elsif() then----------------------
		elsif(isBulletNumPixel = '1') then  --瀛愬脊鏁伴噺钃濊壊
			q_vga <= "0000000111";
		elsif(isPostPixel = '1') then  --鍑嗘槦鐧借壊
			q_vga <= "0000000000";
		elsif(gunOK = '1')then  --鏋鐭ラ亾鏄剧ず鍑烘潵浠€涔堥鑹
			q_vga <= "0111100001";
		elsif(medicalOK = '1') then  --鍖昏嵂鍖呯櫧鑹
			q_vga <= "0111000000";
		elsif(isMePixel = '1') then  --鎴戞槸缁胯壊
			q_vga <= "0000111000";
		elsif(enemyOK = '1') then  --鏁屼汉榛勮壊
			q_vga <= "0111111000";
		else
			q_vga <= "0111111111";
		end if;
	end if;
end process;
---------------------------------------------------------------------
end bhv;