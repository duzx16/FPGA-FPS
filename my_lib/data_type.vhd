library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

package data_type is
	-- 屏幕显示区域大小
	constant X_LIMIT: integer := 640;
	constant Y_LIMIT: integer := 480;
	-- 一些数值的范围
	constant OBJECT_LIMIT: integer := 10;
	constant PLAYER_HP_LIMIT: integer := 100;
	constant BULLET_NUM_LIMIT: integer := 20;
	-- 物品的包围盒大小
	constant HENEMY_WIDTH: integer:= 25;
	constant HENEMY_HEIGHT: integer:=40;
	constant HMEDICAL_WIDTH: integer:=20;
	constant HMEDICAL_HEIGHT: integer:=20;
	constant HGUN_HEIGHT: integer:= 15;
	constant HGUN_WIDTH: integer:=45;
	constant HALF_Y_LIMIT: integer := 280;
	-- 图片的地址
	constant BACKGROUND_ADDR_LIMIT: integer := 153599;
	constant ME_ADDR_BEGIN: integer := 153600;
	constant ME_ADDR_END: integer := ME_ADDR_BEGIN + 12799;
	constant ME_NO_FIRE_START:integer := ME_ADDR_END + 1;
	constant ME_NO_FIRE_END:integer := ME_NO_FIRE_START + 12799;
	constant GUN_ADDR_BEGIN:integer:= ME_NO_FIRE_END + 1;
	constant GUN_ADDR_END:integer:= GUN_ADDR_BEGIN + (2* HGUN_HEIGHT * HGUN_WIDTH - 1);
	constant ENEMY_ADDR_BEGIN:integer:=GUN_ADDR_END + 1;
	constant ENEMY_ADDR_END:integer:= ENEMY_ADDR_BEGIN + (2 * HENEMY_HEIGHT * HENEMY_WIDTH - 1);
	constant ENEMY_FIRE_ADDR_BEGIN:integer:=ENEMY_ADDR_END + 1;
	constant ENEMY_FIRE_ADDR_END:integer := ENEMY_FIRE_ADDR_BEGIN + (2 * HENEMY_HEIGHT * HENEMY_WIDTH - 1);
	constant MEDICAL_ADDR_BEGIN:integer := ENEMY_FIRE_ADDR_END + 1;
	constant MEDICAL_ADDR_END:integer := MEDICAL_ADDR_BEGIN + (2 * 8 * 8 - 1);
	constant START_ADDR_BEGIN:integer := MEDICAL_ADDR_END + 1;
	constant START_ADDR_END:integer := START_ADDR_BEGIN + 153599;
	constant WIN_ADDR_BEGIN:integer := START_ADDR_END + 1;
	constant WIN_ADDR_END:integer := WIN_ADDR_BEGIN + 153599;
	constant LOSE_ADDR_BEGIN:integer := WIN_ADDR_END + 1;
	constant LOSE_ADDR_END:integer := LOSE_ADDR_BEGIN + 153599;
	-- 开始界面的按钮区域
	constant BUTTON_X_BEGIN:integer := 6;
	constant BUTTON_X_END:integer := 145;
	constant BUTTON_Y_BEGIN:integer := 406;
	constant BUTTON_Y_END:integer := 466;
	
	-- 物体的类型（敌人、医药包、冲锋枪）
	type object_type is (enemy, medical, tommygun, none);
	-- 表示物体的状态，正常，被拾取（仅限物品），
	type object_status is (normal, selected, attack);
	
	-- 物体数据的数组
	type object_type_array is array(0 to OBJECT_LIMIT - 1) of object_type;
	type object_x_array is array(0 to OBJECT_LIMIT - 1) of integer range 0 to X_LIMIT;
	type object_y_array is array(0 to OBJECT_LIMIT - 1) of integer range 0 to Y_LIMIT;
	type object_status_array is array(0 to OBJECT_LIMIT - 1) of object_status;
	-- 这个数组是预留出来存放物体的数值的，比如敌人的血量，医药包和枪支的剩余存在时间
	type object_value_array is array(0 to OBJECT_LIMIT - 1) of integer range 0 to 5000;

end package;