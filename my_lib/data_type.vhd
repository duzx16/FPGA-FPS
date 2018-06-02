library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

package data_type is
	
	constant X_LIMIT: integer := 640;
	constant Y_LIMIT: integer := 480;
	constant OBJECT_LIMIT: integer := 10;
	constant PLAYER_HP_LIMIT: integer := 100;
	constant BULLET_NUM_LIMIT: integer := 20;
	constant HENEMY_WIDTH: integer:= 16;
	constant HENEMY_HEIGHT: integer:=40;
	constant HMEDICAL_WIDTH: integer:=8;
	constant HMEDICAL_HEIGHT: integer:=8;
	constant HGUN_HEIGHT: integer:= 15;
	constant HGUN_WIDTH: integer:=45;
	constant HALF_Y_LIMIT: integer := 160;
	
	-- 物体的类型（敌人、医药包、冲锋枪，暂时还没有确定）
	type object_type is (enemy, medical, tommygun, none);
	-- 表示物体的状态，正常，被拾取（仅限物品），
	type object_status is (normal, selected, attack);
	
	-- 物体数据的数组
	type object_type_array is array(0 to OBJECT_LIMIT - 1) of object_type;
	type object_x_array is array(0 to OBJECT_LIMIT - 1) of integer range 0 to X_LIMIT;
	type object_y_array is array(0 to OBJECT_LIMIT - 1) of integer range 0 to Y_LIMIT;
	type object_status_array is array(0 to OBJECT_LIMIT - 1) of object_status;
	-- 这个数组是预留出来存放物体的数值的，比如敌人的血量，医药包和枪支的剩余存在时间
	type object_value_array is array(0 to OBJECT_LIMIT - 1) of integer range 0 to 2047;

end package;