library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library my_lib;
use my_lib.data_type.all;

entity fps_game is
    port(
    -- LED OUTPUT
    led_x1: out std_logic_vector(6 downto 0);
    led_y1: out std_logic_vector(6 downto 0);
    led_z1: out std_logic_vector(6 downto 0);
    led_x0: out std_logic_vector(6 downto 0);
    led_y0: out std_logic_vector(6 downto 0);
    led_z0: out std_logic_vector(6 downto 0);
    -- Clock Input
    clk: in std_logic; -- 100M时钟
    -- Rest
    rst: in std_logic;
    -- Sensor(传入sensor)
    sensor_input: in std_logic;
    -- FOR OPEN FILE
    open_fire: in std_logic;
	 click_ground: out std_logic;
	 click_vdd: out std_logic;
    -- VGA(传入color_controller)
    vga_hs, vga_vs: out std_logic;
    vga_r, vga_g, vga_b: out std_logic_vector(2 downto 0);
    base_sram_we, base_sram_oe, base_sram_ce : out std_logic;
    base_sram_addr : out std_logic_vector(19 downto 0);
    base_sram_data : inout std_logic_vector(31 downto 0)
    );
end entity;

architecture beh of fps_game is
component sensor is
port(
    rst, clk: in std_logic;
    uart_rx: in std_logic;  -- 串口读取
    -- 返回准星的位置
    post_x: out integer range 0 to X_LIMIT;
    post_y: out integer range 0 to Y_LIMIT;
    led_x1: out std_logic_vector(6 downto 0);
    led_y1: out std_logic_vector(6 downto 0);
    led_z1: out std_logic_vector(6 downto 0);
    led_x0: out std_logic_vector(6 downto 0);
    led_y0: out std_logic_vector(6 downto 0);
    led_z0: out std_logic_vector(6 downto 0)
);
end component;
component game_controller is
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
        start_stage: out std_logic;
        game_over_stage: out std_logic;
        game_winning: buffer std_logic;
        -- 表示修改数据是否安全
        data_safe: in std_logic
    );
end component;

component color_controller is
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
end component;

component SixtyHzSignalGenerator is
    port(
        clk100M:in std_logic;
        rst:in std_logic;
        clk60:out std_logic
    );
end component;

-- 显示器显示的准星的位置
signal show_post_x: integer range 0 to X_LIMIT;
signal show_post_y: integer range 0 to Y_LIMIT;
signal post_x: integer range 0 to X_LIMIT;
signal post_y: integer range 0 to Y_LIMIT;
-- 都是长度相同的数组，用来表示物体的数据
signal object_types: object_type_array;
signal object_xs: object_x_array;
signal object_ys: object_y_array;
signal object_statuses: object_status_array;
signal object_values: object_value_array;
-- 玩家的数据
signal player_hp: integer range 0 to PLAYER_HP_LIMIT;
-- 枪支相关的数据
signal bullet_num: integer range 0 to BULLET_NUM_LIMIT;
-- 用于表示是否处于开火
signal show_fired: std_logic;
-- 用于表示是否处于开始界面
signal start_stage: std_logic;
signal game_over_stage: std_logic;
signal game_winning: std_logic;
-- 表示数据是否有效
signal data_safe: std_logic;
signal sixtyHz:std_logic;

begin
    post_sensor: sensor port map(
        rst => rst,
        clk => clk,
        uart_rx => sensor_input,
        post_x => post_x,
        post_y => post_y,
        led_x1 => led_x1,
        led_y1 => led_y1,
        led_z1 => led_z1,
        led_x0 => led_x0,
        led_y0 => led_y0,
        led_z0 => led_z0
    );
    controller: game_controller port map(
        rst => rst,
        clk => clk,
        post_x => post_x,
        post_y => post_y,
        open_fire => open_fire,
        -- 显示器显示的准星的位置
        show_post_x => show_post_x,
        show_post_y => show_post_y,
        -- 都是长度相同的数组，用来表示物体的数据
        object_types => object_types,
        object_xs => object_xs,
        object_ys => object_ys,
        object_statuses => object_statuses,
        object_values => object_values,
        -- 玩家的数据
        player_hp => player_hp,
        -- 子弹相关的数据
        bullet_num => bullet_num,
        -- 用于表示是否处于开火
        show_fired => show_fired,
        -- 用于表示是否处于开始界面
        start_stage => start_stage,
        game_over_stage => game_over_stage,
        game_winning => game_winning,
        -- 表示修改数据是否安全
        data_safe => data_safe
        );
    u1:color_controller port map(
        clk, sixtyHz, rst, vga_hs, vga_vs, vga_r, vga_g, vga_b, object_types, object_xs, object_ys, object_statuses, object_values, player_hp, bullet_num
        ,show_fired, start_stage, game_over_stage, game_winning, conv_STD_LOGIC_VECTOR(show_post_x,10), CONV_STD_LOGIC_VECTOR(show_post_y,9), show_fired,
        base_sram_we, base_sram_oe, base_sram_ce, base_sram_addr, base_sram_data, data_safe
    );
    
    u2:SixtyHzSignalGenerator port map(
        clk100M=>clk, rst=>rst, clk60=>sixtyHz
    );
	 click_ground <= '0';
	 click_vdd <= '1';
end beh;