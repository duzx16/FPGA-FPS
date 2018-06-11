library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;
use work.data_type.all;

entity game_controller is
	port(
		-- 100M时钟
	   clk: in std_logic;
		rst: in std_logic;
		post_x: in integer range 0 to X_LIMIT;
		post_y: in integer range 0 to Y_LIMIT;
		open_fire: in std_logic;
		-- 显示器显示的准星的位置
		show_post_x: buffer integer range 0 to X_LIMIT;
		show_post_y: buffer integer range 0 to Y_LIMIT;
		-- 都是长度相同的数组，用来表示物体的数据
		object_types: buffer object_type_array;
	    object_xs: buffer object_x_array;
		object_ys: buffer object_y_array;
		object_statuses: buffer object_status_array;
		object_values: buffer object_value_array;
		-- 玩家的数据
		player_hp: buffer integer range 0 to PLAYER_HP_LIMIT;
		-- 子弹相关的数据
		bullet_num: buffer integer range 0 to BULLET_NUM_LIMIT;
		-- 用于表示是否处于开火
		show_fired: out std_logic;
		-- 用于表示是否处于开始界面
		start_stage: buffer std_logic;
		game_over_stage: buffer std_logic;
		game_winning: buffer std_logic;
		-- 表示修改数据是否安全
		data_safe: in std_logic
	);
end entity;

architecture beh of game_controller is
component RandomNumber is
port(
--basic	
	clkin : in std_logic;
	rst : in std_logic;
	num : out std_logic_vector(15 downto 0) --random number
);
end component;
-- 控制游戏难度的常数
constant ADD_OBJECT_COOLDOWN_LIMIT: integer:= 600;
constant COOL_DOWN_LIMIT: integer:= 30;
constant BULLET_UPDATE_LIMIT: integer:= 180;
constant ENEMY_ACTION_INTEVAL: integer:= 300;
constant PLAYER_ATK: integer:= 40;
constant ENEMY_ATK: integer:= 10;
constant KILL_ENEMY_AIM: integer:=10;
-- 游戏的状态控制
type control_state_type is (waiting, post_iter, post_act, object_iter, update_post, update_gun, update_stage, restart);
signal control_state:control_state_type;
signal value_changed: std_logic;
-- 各种各样的count
signal iter_count: integer range 0 to OBJECT_LIMIT;
signal bullet_update_count: integer range 0 to BULLET_UPDATE_LIMIT:=0;
signal cool_down_count: integer range 0 to COOL_DOWN_LIMIT:=0;
signal add_object_cooldown: integer range 0 to ADD_OBJECT_COOLDOWN_LIMIT;
signal kill_enemy_count: integer range 0 to 100;
-- 物品状态的一些辅助数据
type object_count_type is array(0 to OBJECT_LIMIT - 1) of integer range 0 to 1000;
type object_dir_type is array(0 to OBJECT_LIMIT - 1) of std_logic_vector(1 downto 0);
signal object_counts: object_count_type;
signal object_dirs: object_dir_type;
-- 表示玩家是否进行了射击
signal fired_temp: std_logic;
-- 表示玩家是否有冲锋枪
-- 现在这个信号被位置0的type代替
-- 表示准星选择的目标
signal post_selected: integer range 0 to OBJECT_LIMIT;
-- 随机数用于敌人移动、物品生成
signal random_vector: std_logic_vector(15 downto 0);

begin
random_generator: RandomNumber port map
(
	clkin => clk,
	rst => rst,
	num => random_vector
);

com:process(clk, rst)
variable random_num: integer;
begin
	if rst = '0' then
		control_state <= waiting;
		fired_temp <= '0';
		cool_down_count <= 0;
		bullet_update_count <= 0;
		add_object_cooldown <= 0;
		player_hp <= 100;
		bullet_num <= BULLET_NUM_LIMIT;
		value_changed <= '0';
		game_over_stage <= '0';
		start_stage <= '1';
		show_post_x <= 100;
		show_post_y <= 100;
		
		for i in 0 to OBJECT_LIMIT - 1 loop
			object_types(i) <= none;
		end loop;
--		object_types(0) <= tommygun;
--		object_xs(0) <= 320;
--		object_ys(0) <= 240;
--		object_values(0) <= 1000;
--		object_counts(0) <= 0;
--		object_statuses(0) <= normal;
		object_types(1) <= enemy;
		object_xs(1) <= 220;
		object_ys(1) <= 240;
		object_values(1) <= 100;
		object_counts(1) <= 0;
		object_statuses(1) <= normal;
	elsif rising_edge(clk) then
		case control_state is
			when waiting =>
				-- 检测是否开火
				if open_fire = '0' then
					fired_temp <= '1';
				end if;
				if data_safe = '1' then
					if value_changed = '0' then
						if game_over_stage = '1' or start_stage = '1' then
							control_state <= update_stage;
						else
							post_selected <= OBJECT_LIMIT;
							if cool_down_count = 0 then
								if fired_temp = '1' and bullet_update_count = 0 then
									if object_types(0) = tommygun then
										cool_down_count <= 3;
									else
										cool_down_count <= COOL_DOWN_LIMIT;
									end if;
									show_fired <= '1';
									bullet_num <= bullet_num - 1;
									control_state <= post_iter;
									iter_count <= 1;
								else
									control_state <= object_iter;
									iter_count <= 1;
								end if;
							else
								control_state <= object_iter;
								iter_count <= 1;
								if cool_down_count = 1 then
									show_fired <= '0';
								end if;
								cool_down_count <= cool_down_count - 1;
							end if;
						end if;
					end if;
				else
					value_changed <= '0';
				end if;
			when post_iter =>
				-- 这里的数值决定了物品包围盒的大小
				case object_types(iter_count) is
					when enemy =>
						if abs(show_post_x - object_xs(iter_count)) < HENEMY_WIDTH and abs(show_post_y - object_ys(iter_count)) < HENEMY_HEIGHT then
								post_selected <= iter_count;
						end if;
					when medical =>
						if abs(show_post_x - object_xs(iter_count)) < HMEDICAL_WIDTH and abs(show_post_y - object_ys(iter_count)) < HMEDICAL_HEIGHT then
								post_selected <= iter_count;
						end if;
					when tommygun =>
						if abs(show_post_x - object_xs(iter_count)) < HGUN_WIDTH and abs(show_post_y - object_ys(iter_count)) < HGUN_HEIGHT then
								post_selected <= iter_count;
						end if;
					when none =>
						null;
				end case;
				if iter_count = OBJECT_LIMIT - 1 then
					control_state <= post_act;
					iter_count <= 0;
				else
					iter_count <= iter_count + 1;
				end if;
			when post_act =>
				-- 对准星攻击的目标进行攻击或者拾取
				if post_selected < OBJECT_LIMIT then
					case object_types(post_selected) is
						when enemy =>
							object_statuses(post_selected) <= selected;
							-- 从130开始进入被攻击画面
							object_counts(post_selected) <= ENEMY_ACTION_INTEVAL + 1;
							-- 对敌人进行减血
							if object_values(post_selected) <= PLAYER_ATK then
								object_types(post_selected) <= none;
								kill_enemy_count <= kill_enemy_count + 1;
							else
								object_values(post_selected) <= object_values(post_selected) - PLAYER_ATK;
							end if;
						when medical =>
							object_statuses(post_selected) <= selected;
							object_counts(post_selected) <= 0;
							-- 对玩家进行加血
							if player_hp > 60 then
								player_hp <= 100;
							else
								player_hp <= player_hp + 40;
							end if;
						when tommygun =>
							object_statuses(post_selected) <= selected;
							object_counts(post_selected) <= 0;
							-- 获得冲锋枪效果
							object_types(0) <= tommygun;
							object_statuses(0) <= selected;
							object_xs(0) <= 360;
							object_ys(0) <= 460;
							object_values(0) <= 1800;
						when others =>
							null;
					end case;
				end if;				
				control_state <= object_iter;
				iter_count <= 1;
			when object_iter =>
				-- 敌人攻击（物品消失、空格实例化）、敌人移动（物品时间减少）
				case object_types(iter_count) is
					when enemy =>
						if object_counts(iter_count) = 0 then
							-- 决定敌人移动的方向
							if random_vector(0) = '1' then
								if object_xs(iter_count) + HENEMY_WIDTH < X_LIMIT then
									object_dirs(iter_count)(0) <= '1';
								else
									object_dirs(iter_count)(0) <= '0';
								end if;
							else
								if object_xs(iter_count) > HENEMY_WIDTH then
									object_dirs(iter_count)(0) <= '0';
								else
									object_dirs(iter_count)(0) <= '1';
								end if;
							end if;
							if random_vector(1) = '1' then
							if object_ys(iter_count) + HENEMY_HEIGHT < Y_LIMIT then
									object_dirs(iter_count)(1) <= '1';
								else
									object_dirs(iter_count)(1) <= '0';
								end if;
							else
								if object_ys(iter_count) > HALF_Y_LIMIT then
									object_dirs(iter_count)(1) <= '0';
								else
									object_dirs(iter_count)(1) <= '1';
								end if;
							end if;
							object_counts(iter_count) <= object_counts(iter_count) + 1;
						elsif object_counts(iter_count) <= 30 then
							-- 进行敌人的移动
							if object_dirs(iter_count)(1) = '1' then
								if object_ys(iter_count) + HENEMY_HEIGHT < Y_LIMIT then
									object_ys(iter_count) <= object_ys(iter_count) + 1;
								end if;
							else
								if object_ys(iter_count) > HALF_Y_LIMIT then
									object_ys(iter_count) <= object_ys(iter_count) - 1;
								end if;
							end if;
							if object_dirs(iter_count)(0) = '1' then
								if object_xs(iter_count) + HENEMY_WIDTH < X_LIMIT then
									object_xs(iter_count) <= object_xs(iter_count) + 1;
								end if;
							else
								if object_xs(iter_count) > HENEMY_WIDTH then
									object_xs(iter_count) <= object_xs(iter_count) - 1;
								end if;
							end if;
							object_counts(iter_count) <= object_counts(iter_count) + 1;
						-- 这里的数值决定了敌方动作的长度
						elsif object_counts(iter_count) <= ENEMY_ACTION_INTEVAL then
							if object_counts(iter_count) = ENEMY_ACTION_INTEVAL then
								-- 进行开火，我方生命下降
								if player_hp <= ENEMY_ATK then
									player_hp <= 0;
								else
									player_hp <= player_hp - ENEMY_ATK;
								end if;
								object_statuses(iter_count) <= normal;
								object_counts(iter_count) <= 0;
							elsif object_counts(iter_count) = ENEMY_ACTION_INTEVAL - 60 then
								-- 开始进入开火状态
								object_statuses(iter_count) <= attack;
								object_counts(iter_count) <= object_counts(iter_count) + 1;
							else
								object_counts(iter_count) <= object_counts(iter_count) + 1;
							end if;
						else
							-- 在150时被攻击的状态终止
							if object_counts(iter_count) = ENEMY_ACTION_INTEVAL + 60 then
								object_statuses(iter_count) <= normal;
								object_counts(iter_count) <= 0;
							else
								object_counts(iter_count) <= object_counts(iter_count) + 1;
							end if;
						end if;
					when medical =>
						-- 物体消失的判定
						if object_values(iter_count) = 0 or object_counts(iter_count) = 40 then
							object_types(iter_count) <= none;
						-- 物体被选择的时长的判定
						elsif object_statuses(iter_count) = selected then
							object_counts(iter_count) <= object_counts(iter_count) + 1;
						else
							object_values(iter_count) <= object_values(iter_count) - 1;
						end if;
					when tommygun =>
						-- 物体消失的判定
						if object_values(iter_count) = 0 or object_counts(iter_count) = 30 then
							object_types(iter_count) <= none;
						-- 物体被选择的时长的判定
						elsif object_statuses(iter_count) = selected then
							object_counts(iter_count) <= object_counts(iter_count) + 1;
						else
							object_values(iter_count) <= object_values(iter_count) - 1;
						end if;
					when none =>
						-- 这里的数值决定了不同的物品被添加的概率
						if add_object_cooldown = 0 then
							random_num := CONV_INTEGER(random_vector(15 downto 12));
							object_statuses(iter_count) <= normal;
							if random_num < 12 then
								-- 添加敌人
								object_xs(iter_count) <= CONV_INTEGER(random_vector(8 downto 0)) + 74;
								object_ys(iter_count) <= HALF_Y_LIMIT;
								object_types(iter_count) <= enemy;
								object_counts(iter_count) <= 0;
								object_values(iter_count) <= 100;
							elsif random_num < 14 then
								-- 添加医药包
								object_types(iter_count) <= medical;
								object_counts(iter_count) <= 0;
								object_values(iter_count) <= 1024;
							else
								-- 添加冲锋枪
								object_xs(iter_count) <= CONV_INTEGER(random_vector(8 downto 0)) + 74;
								object_ys(iter_count) <= HALF_Y_LIMIT + 80;
								object_types(iter_count) <= tommygun;
								object_counts(iter_count) <= 0;
								object_values(iter_count) <= 1024;
							end if;
							add_object_cooldown <= ADD_OBJECT_COOLDOWN_LIMIT;
						else
							add_object_cooldown <= add_object_cooldown - 1;
						end if;
						iter_count <= iter_count + 1;
					end case;
				if iter_count = OBJECT_LIMIT - 1 then
					control_state <= update_gun;
					iter_count <= 0;
				else
					iter_count <= iter_count + 1;
				end if;
			when update_gun =>
				if object_values(0) = 0 then
					object_types(0) <= none;
				else
					object_values(0) <= object_values(0) - 1;
				end if;
				control_state <= update_stage;
			when update_stage =>
				if start_stage = '1' then
					if fired_temp = '1' and cool_down_count = 0 then
						start_stage <= '0'; 
						kill_enemy_count <= 0;
						cool_down_count <= COOL_DOWN_LIMIT;
					end if;
					if cool_down_count > 0 then
						cool_down_count <= cool_down_count - 1;
					end if;
				elsif game_over_stage = '1' then
					if fired_temp = '1' and cool_down_count = 0 then
						game_over_stage <= '0';
						game_winning <= '0';
						start_stage <= '1';
						cool_down_count <= 0;
						bullet_update_count <= 0;
						add_object_cooldown <= 0;
						player_hp <= 100;
						bullet_num <= BULLET_NUM_LIMIT;
						for i in 0 to OBJECT_LIMIT - 1 loop
							object_types(i) <= none;
						end loop;
						cool_down_count <= COOL_DOWN_LIMIT;
					end if;
					if cool_down_count > 0 then
						cool_down_count <= cool_down_count - 1;
					end if;
				else
					if kill_enemy_count = KILL_ENEMY_AIM then
						game_over_stage <= '1';
						game_winning <= '1';
						show_fired <= '0';
					elsif player_hp = 0 then
						game_over_stage <= '1';
						game_winning <= '0';
					end if;
				end if;
				fired_temp <= '0';
				control_state <= update_post;
			when update_post =>
				show_post_x <= post_x;
				show_post_y <= post_y;
--				show_post_x <= show_post_x + 1;
--				if show_post_x = 639 then
--					show_post_x <= 0;
--					show_post_y <= show_post_y + 10;
--				end if;
--				if show_post_y = 479 or show_post_y < 300 then
--					show_post_y <= 300;
--				end if;
				if bullet_num = 0 then
					bullet_update_count <= 1;
				end if;
				if bullet_update_count > 0 then
					if bullet_num < BULLET_NUM_LIMIT and bullet_update_count MOD 5 = 0 then
						bullet_num <= bullet_num + 1;
					end if;
					if bullet_update_count = BULLET_UPDATE_LIMIT then
						bullet_update_count <= 0;
						bullet_num <= BULLET_NUM_LIMIT;
					else
						bullet_update_count <= bullet_update_count + 1;
					end if;
				end if;
				control_state <= waiting;
				value_changed <= '1';
			when others =>
				null;
		end case;			
	end if;
end process;
end architecture;