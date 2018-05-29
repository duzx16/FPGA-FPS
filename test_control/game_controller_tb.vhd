library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

library work;
use work.data_type.all;


entity game_controller_tb is
end;

architecture bench of game_controller_tb is

  component game_controller
  	port(
  	   clk: in std_logic;
  		rst: in std_logic;
  		post_x: in integer range 0 to X_LIMIT;
  		post_y: in integer range 0 to Y_LIMIT;
  		open_fire: in std_logic;
  		show_post_x: buffer integer range 0 to X_LIMIT;
  		show_post_y: buffer integer range 0 to Y_LIMIT;
  		object_types: buffer object_type_array;
  	   object_xs: buffer object_x_array;
  		object_ys: buffer object_y_array;
  		object_statuses: buffer object_status_array;
  		player_hp: buffer integer range 0 to PLAYER_HP_LIMIT;
  		bullet_num: buffer integer range 0 to BULLET_NUM_LIMIT;
  		show_fired: out std_logic;
  		start_stage: out std_logic;
  		game_over_stage: out std_logic;
  		data_safe: in std_logic
  	);
  end component;

  signal clk: std_logic;
  signal rst: std_logic;
  signal post_x: integer range 0 to X_LIMIT;
  signal post_y: integer range 0 to Y_LIMIT;
  signal open_fire: std_logic;
  signal show_post_x: integer range 0 to X_LIMIT;
  signal show_post_y: integer range 0 to Y_LIMIT;
  signal object_types: object_type_array;
  signal object_xs: object_x_array;
  signal object_ys: object_y_array;
  signal object_statuses: object_status_array;
  signal player_hp: integer range 0 to PLAYER_HP_LIMIT;
  signal bullet_num: integer range 0 to BULLET_NUM_LIMIT;
  signal show_fired: std_logic;
  signal start_stage: std_logic;
  signal game_over_stage: std_logic;
  signal data_safe: std_logic ;

  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean;

begin

  uut: game_controller port map ( clk             => clk,
                                  rst             => rst,
                                  post_x          => post_x,
                                  post_y          => post_y,
                                  open_fire       => open_fire,
                                  show_post_x     => show_post_x,
                                  show_post_y     => show_post_y,
                                  object_types    => object_types,
                                  object_xs       => object_xs,
                                  object_ys       => object_ys,
                                  object_statuses => object_statuses,
                                  player_hp       => player_hp,
                                  bullet_num      => bullet_num,
                                  show_fired      => show_fired,
                                  start_stage     => start_stage,
                                  game_over_stage => game_over_stage,
                                  data_safe       => data_safe );

  stimulus: process
  begin
  
    -- Put initialisation code here

    rst <= '0';
    wait for 5 ns;
    rst <= '1';
    wait for 5 ns;

    -- Put test bench stimulus code here
	 for i in 0 to 1000 loop
    data_safe <= '1';
    wait for 250 ns;
    data_safe <= '0';
    wait for 10 ns;
	 end loop;
    stop_the_clock <= true;
    wait;
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end;