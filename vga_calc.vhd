library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

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
        game_winning: in std_logic;
        
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
        object_values: in object_value_array;
        
	--sram
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
    
    signal s_x:std_logic_vector(9 downto 0);  --扫描位置的临时变量
    signal s_y:std_logic_vector(8 downto 0);
    signal clk50:std_logic;
    signal q_vga:std_LOGIC_vector(9 downto 0);  --给vga赋值，与外界接口连接
    
    --opencv处理得到图像边缘
    type GUN_PIXEL_LIMIT is array(0 to 2 * HGUN_HEIGHT - 1) of integer range 0 to 2 * HGUN_WIDTH;
    type ME_PIXEL_LIMIT is array(0 to 159) of integer range 0 to 160;
    type ENEMY_PIXEL_LIMIT is array(0 to 2 * HENEMY_HEIGHT - 1) of integer range 0 to 2 * HENEMY_WIDTH;

    --代表不规则图形的左边缘及右边缘。如果中间有掏空的部分，则左边缘有两个。
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

    --血量、子弹数、玩家的显示位置都是固定的。Start_x表示显示位置的左上角的横坐标，
    constant hpStart_x:std_LOGIC_vector(9 downto 0) := "1000111010";
    constant hpEnd_x:std_LOGIC_vector(9 downto 0) := "1001101100";
    constant hpStart_y:std_LOGIC_vector(8 downto 0) := "000010100";
    constant hpEnd_y:std_logic_vector(8 downto 0) := "000011110";
    
    constant BullnumStart_x:std_LOGIC_vector(9 downto 0) := "1000111010";
    constant BullnumEnd_x:std_LOGIC_vector(9 downto 0) := "1001101100";
    constant BullnumStart_y:std_LOGIC_vector(8 downto 0) := "111000010";
    constant BullnumEnd_y:std_logic_vector(8 downto 0) := "111001100";
    
    constant MeStartX:std_logic_vector(9 downto 0):="0000010100";
    constant MeEndX : std_logic_vector(9 downto 0):="0010110011";
    constant MeStartY:std_logic_vector(8 downto 0):="101000000";
    constant MeEndY : std_logic_vector(8 downto 0):="111011111";
    
    --代表几个变量的像素或者地址是否计算完成
    signal postOK, HpOK, enemyHPOK, gunOK, medicalOK, meOK, bulletnumOK, enemyOK, gamestartOK, 
                gameoverOK, backgroundOK, buttonOK:std_logic;
    
    --几个会变化的物体的位置
    signal enemy_x, medical_x, gun_x:std_logic_vector(9 downto 0);
    signal enemy_y, medical_y, gun_y:std_logic_vector(8 downto 0);

    signal gun_cnt, enemy_cnt, medical_cnt: integer range 0 to OBJECT_LIMIT;
    
    signal rwselect:std_logic;
    signal addr_cnt:std_logic_vector(19 downto 0);
    signal data_read, data_wrote : std_logic_vector(31 downto 0);
    
    signal clk25:std_logic;
begin
    --只读sram
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
-------------------------------HP------------------------------------
process(clk_0)
begin
    if(s_x >= hpStart_x and s_x <= hpEnd_x and s_y >= hpStart_y and s_y <= hpEnd_y) then
        if(CONV_INTEGER(s_x - hpStart_x) * PLAYER_HP_LIMIT <= my_hp * 50) then  --长条形状
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
        if(CONV_INTEGER(s_x - BullnumStart_x) * BULLET_NUM_LIMIT <= bullet_num * 50) then  --长条形状
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
variable dis2:integer range 0 to 640000;
begin
    postOK <= '0';
    --圆形
    if(postX <= s_x and postY <= s_y) then
        dis2 := conV_INTEGER(s_x-postX)*conV_INTEGER(s_x-postX)+conV_INTEGER(s_y-postY)*conV_INTEGER(s_y-postY);
    elsif(postX <= s_x and postY > s_y) then
        dis2 := conV_INTEGER(s_x-postX)*conV_INTEGER(s_x-postX)+conV_INTEGER(postY-s_y)*conV_INTEGER(postY-s_y);
    elsif(postX > s_x and postY <= s_y) then
        dis2 := conV_INTEGER(postX-s_x)*conV_INTEGER(postX-s_x)+conV_INTEGER(s_y-postY)*conV_INTEGER(s_y-postY);
    elsif(postX > s_x and postY > s_y) then
        dis2 := conV_INTEGER(postX-s_x)*conV_INTEGER(postX-s_x)+conV_INTEGER(postY-s_y)*conV_INTEGER(postY-s_y);
    else
        dis2 := 0;
    end if;
    
    --分开火与非开火状态，改准星的颜色、大小
    if post_select = '0' then
        if(dis2 >= 100 and dis2 <= 144) then
            PostOK <= '1';
        elsif (abs(CONV_INTEGER(s_x) - CONV_INTEGER(postX)) < 2 and abs(CONV_INTEGER(s_y) - CONV_INTEGER(postY)) <= 12) or
        (abs(CONV_INTEGER(s_y) - CONV_INTEGER(postY)) < 2 and abs(CONV_INTEGER(s_x) - CONV_INTEGER(postX)) <= 12) then
            postOK <= '1';
        else
            PostOK <= '0';
        end if;
    elsif post_select = '1' then
        if(dis2 >= 196 and dis2 <= 256) then
            postOK <= '1';
        elsif (abs(CONV_INTEGER(s_x) - CONV_INTEGER(postX)) < 2 and abs(CONV_INTEGER(s_y) - CONV_INTEGER(postY)) <= 16) or
        (abs(CONV_INTEGER(s_y) - CONV_INTEGER(posty)) < 2 and abs(CONV_INTEGER(s_x) - CONV_INTEGER(postX)) <= 16) then
            postOK <= '1';
        else
            postOK <= '0';
        end if;
    end if;
end process;
--------------------gun----------------------------
process(clk_0)
variable temp_x: integer range 0 to X_LIMIT;
variable temp_y: integer range 0 to Y_LIMIT;
variable cnt: integer range 0 to OBJECT_LIMIT := 0;
begin
    gunOK <= '0';
    gun_cnt <= OBJECT_LIMIT;
    gun_x <= "0000000000";
    gun_y <= "000000000";
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
--------------------enemy HP--------------------
process(clk_0)
variable cnt: integer range 0 to OBJECT_LIMIT:=0;
variable temp_x: integer range 0 to X_LIMIT;
begin
    enemyHPOK <= '0';
    get_obj: for cnt in 0 to OBJECT_LIMIT - 1 loop
        if object_types(cnt) = enemy then
            if(s_x >= object_xs(cnt) - HENEMY_WIDTH - 3 and s_x <= object_xs(cnt) + HENEMY_WIDTH + 3 and 
            s_y <= object_ys(cnt) - HENEMY_HEIGHT - 3 and s_y >= object_ys(cnt) - HENEMY_HEIGHT - 8) then
                temp_x := CONV_INTEGER(s_x) - object_xs(cnt) + HENEMY_WIDTH + 3;
                if temp_x * PLAYER_HP_LIMIT < object_values(cnt) * (HENEMY_WIDTH * 2 + 6) then
                    enemyHPOK <= '1';
                end if;
            end if;
        end if;
    end loop get_obj;
end process;

--------------------enemy------------------------
process(clk_0)
variable temp_x: integer range 0 to X_LIMIT;
variable temp_y: integer range 0 to Y_LIMIT;
variable cnt: integer range 0 to OBJECT_LIMIT := 0;
begin
    enemyOK <= '0';
    enemy_cnt <= OBJECT_LIMIT;
    enemy_x <= "0000000000";
    enemy_y <= "000000000";
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
variable cnt: integer range 0 to OBJECT_LIMIT := 0;
begin
    medicalOK <= '0';
    medical_cnt <= OBJECT_LIMIT;
    medical_x <= "0000000000";
    medical_y <= "000000000";
    get_obj:for cnt in 0 to OBJECT_LIMIT - 1 loop
        case object_types(cnt) is
            when medical=>
                if(object_xs(cnt) <= s_x + HMEDICAL_WIDTH and s_x < object_xs(cnt) + HMEDICAL_WIDTH and object_ys(cnt) <= s_y + HMEDICAL_HEIGHT and s_y < object_ys(cnt) + HMEDICAL_HEIGHT) then
                    if((object_xs(cnt) <= s_x + 3 and s_x < object_xs(cnt) + 3) or (object_ys(cnt) <= s_y + 3 and s_y < object_ys(cnt) + 3)) then
                        medical_x <= s_x + HMEDICAL_WIDTH - object_xs(cnt);
                        medical_y <= s_y + HMEDICAL_HEIGHT - object_ys(cnt);
                        medicalOK <= '1';
                        medical_cnt <= cnt;
                        exit get_obj;
                    end if;
                end if;
            when others => null;
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
----------------------------BUTTON-----------------------------------
--开始界面的按钮
process(clk_0)
begin
	buttonOK <= '0';
	if s_x >= BUTTON_X_BEGIN - 2 and s_x <= BUTTON_X_END + 2 and s_y >= BUTTON_Y_BEGIN - 2 and s_y <= BUTTON_Y_BEGIN then
		buttonOK <= '1';
	elsif s_x >= BUTTON_X_BEGIN - 2 and s_x <= BUTTON_X_END + 2 and s_y >= BUTTON_Y_END and s_y <= BUTTON_Y_END + 2 then
		buttonOK <= '1';
	elsif s_x >= BUTTON_X_BEGIN - 2 and s_x <= BUTTON_X_BEGIN and s_y >= BUTTON_Y_BEGIN - 2 and s_y <= BUTTON_Y_END + 2 then
		buttonOK <= '1';
	elsif s_x >= BUTTON_X_END and s_x <= BUTTON_X_END + 2 and s_y >= BUTTON_Y_BEGIN - 2 and s_y <= BUTTON_Y_END + 2 then
		buttonOK <= '1';
	else 
		buttonOK <= '0';
	end if;
end process;
--++++++++++++++++++++++++  SRAM DATA ++++++++++++++++++++++++++++++++
process(clk50, reset)
variable temp_addr:std_logic_vector(19 downto 0):= (others=>'0');
begin
    ----------------------- background --------------------------
    if clk50'event and clk50 = '1' then
			if(PostOK = '1' and post_select = '1') then
            q_vga <= "0111000000";
			elsif(postOK = '1' and post_select = '0') then
            q_vga <= "0111111000";
			elsif (gamestart = '1') then
            if s_x < 640 and s_y < 480 then
					temp_addr := CONV_STD_LOGIC_VECTOR(conV_INTEGER(s_x) / 2 + conV_INTEGER(s_y) * 320, 20) + START_ADDR_BEGIN;
					addr_cnt <= temp_addr;
					if temp_addr(0) = '0' then
						q_vga <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
					else
						q_vga <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);	
					end if;
					if postX >= BUTTON_X_BEGIN and postx <= BUTTON_X_END and postY >= BUTTON_Y_BEGIN and postY <= BUTTON_Y_END then
						if(buttonOK = '1') then
							q_vga <= "0111110000";
						end if;
					end if;
				end if;
		--===============================================================================
			elsif (game_winning = '1') then
            if s_x < 640 and s_y < 480 then
					temp_addr := CONV_STD_LOGIC_VECTOR(conV_INTEGER(s_x) / 2 + conV_INTEGER(s_y) * 320, 20) + WIN_ADDR_BEGIN;
					addr_cnt <= temp_addr;
					if temp_addr(0) = '0' then
						q_vga <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
					else
						q_vga <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
					end if;
				end if;
		--===============================================================================
        elsif (gameover = '1') then
            if s_x < 640 and s_y < 480 then
					temp_addr := CONV_STD_LOGIC_VECTOR(conV_INTEGER(s_x) / 2 + conV_INTEGER(s_y) * 320, 20) + LOSE_ADDR_BEGIN;
					addr_cnt <= temp_addr;
					if temp_addr(0) = '0' then
						q_vga <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
					else
						q_vga <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
					end if;
				end if;
        elsif(HpOK = '1' or enemyHPOK = '1') then   --血量红色
            q_vga <= "0111000000";
        elsif(BulletnumOK = '1') then  --子弹量蓝色
            q_vga <= "0000000111";
        elsif(MeOK = '1') then
            if me_firing = '1' then
                temp_addr := conV_STD_LOGIC_VECTOR(conV_INTEGER(s_x - MeStartX) / 2 + conV_INTEGER(s_y - MestartY) * 80, 20) + ME_ADDR_BEGIN;
                addr_cnt <= temp_addr;
                if temp_addr(0) = '0' then
                    q_vga <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
                else
                    q_vga <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
                end if;
            elsif me_firing = '0' then
                temp_addr := conV_STD_LOGIC_VECTOR(conV_INTEGER(s_x - MeStartX) / 2 + conV_INTEGER(s_y - MestartY) * 80, 20) + ME_NO_FIRE_START;
                addr_cnt <= temp_addr;
                if temp_addr(0) = '0' then
                    q_vga <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
                else
                    q_vga <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
                end if;
            end if;
            --q_vga <= "0000111000";
        elsif(gunOK = '1') then
            if(object_statuses(gun_cnt) = selected) then  --分枪支、敌人是否被选中（攻击），如果选中则将红色部分赋值为111
                temp_addr := conV_STD_LOGIC_VECTOR(conV_INTEGER(gun_x) / 2 + 
                    conV_INTEGER(gun_y) * HGUN_WIDTH, 20) + GUN_ADDR_BEGIN;
                addr_cnt <= temp_addr;
                if temp_addr(0) = '0' then
                    q_vga <= "0" & "111" & data_read(28 downto 26) & data_read(25 downto 23);
                else
                    q_vga <= "0" & "111" & data_read(12 downto 10) & data_read(9 downto 7);
                end if;
                --q_vga <= "0000111000";
            else
                temp_addr := conV_STD_LOGIC_VECTOR(conV_INTEGER(gun_x) / 2 + 
                    conV_INTEGER(gun_y) * HGUN_WIDTH, 20) + GUN_ADDR_BEGIN;
                addr_cnt <= temp_addr;
                if temp_addr(0) = '0' then
                    q_vga <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
                else
                    q_vga <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
                end if;
                --q_vga <= "0111111000";
            end if;
            
        elsif(enemyOK = '1') then
	--分为敌人自己被攻击、敌人攻击玩家的状态，敌人攻击玩家则枪口会出现火光，敌人被攻击会变红
            if(object_statuses(enemy_cnt) = selected) then
                temp_addr := conV_STD_LOGIC_VECTOR(conV_INTEGER(enemy_x) / 2 + 
                    conV_INTEGER(enemy_y) * HENEMY_WIDTH, 20) + ENEMY_ADDR_BEGIN;
                addr_cnt <= temp_addr;
                if temp_addr(0) = '0' then
                    q_vga <= "0" & "111" & data_read(28 downto 26) & data_read(25 downto 23);
                else
                    q_vga <= "0" & "111" & data_read(12 downto 10) & data_read(9 downto 7);
                end if;
                --q_vga <= "0111111111";
            elsif(object_statuses(enemy_cnt) = attack) then
                temp_addr := conV_STD_LOGIC_VECTOR(conV_INTEGER(enemy_x) / 2 + 
                    conV_INTEGER(enemy_y) * HENEMY_WIDTH, 20) + ENEMY_FIRE_ADDR_BEGIN;
                addr_cnt <= temp_addr;
                if temp_addr(0) = '0' then
                    q_vga <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
                else
                    q_vga <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
                end if;
                --q_vga <= "0000111000";
            else
                temp_addr := conV_STD_LOGIC_VECTOR(CONV_INTEGER(enemy_x) / 2 + 
                    conV_INTEGER(enemy_y) * HENEMY_WIDTH, 20) + ENEMY_ADDR_BEGIN;
                addr_cnt <= temp_addr;
                if temp_addr(0) = '0' then
                    q_vga <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
                else
                    q_vga <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
                end if;
                --q_vga <= "0000111111";
            end if;
        elsif(medicalOK = '1') then
            if(object_statuses(medical_cnt) = selected) then
                q_vga <= "0111111000";
            else
                q_vga <= "0111000000";
            end if;
        elsif s_x < 640 and s_y < 480 then          
            temp_addr := CONV_STD_LOGIC_VECTOR(conV_INTEGER(s_x) / 2 + conV_INTEGER(s_y) * 320, 20);
            addr_cnt <= temp_addr;
            if temp_addr(0) = '0' then
                q_vga <= "0" & data_read(31 downto 29) & data_read(28 downto 26) & data_read(25 downto 23);
            else
                q_vga <= "0" & data_read(15 downto 13) & data_read(12 downto 10) & data_read(9 downto 7);
            end if;
            --q_vga <= "0111111111";
        else
            q_vga <= "0111111111";
        end if;
        
    end if;
    
    -------------------------------------------------------------
end process;

end bhv;
