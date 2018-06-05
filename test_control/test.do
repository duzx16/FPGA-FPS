quit -sim
.main clear
vlib work
vmap work work
vcom ./../utils/RandomNumber.vhd
vcom ./../my_lib/data_type.vhd
vcom ./../game_controller.vhd ./game_controller_tb.vhd

vsim work.game_controller_tb -t 1ns

add wave -position end  sim:/game_controller_tb/uut/clk
add wave -position end  sim:/game_controller_tb/uut/rst
add wave -position end  sim:/game_controller_tb/uut/data_safe
add wave -position end  sim:/game_controller_tb/uut/control_state
add wave -position end  sim:/game_controller_tb/uut/value_changed
add wave -position end  sim:/game_controller_tb/object_types
add wave -position end  sim:/game_controller_tb/uut/iter_count
add wave -position end  sim:/game_controller_tb/uut/object_values(0)
add wave -position end  sim:/game_controller_tb/uut/object_counts(0)
add wave -position end  sim:/game_controller_tb/uut/object_xs(0)
add wave -position end  sim:/game_controller_tb/uut/object_ys(0)
add wave -position end  sim:/game_controller_tb/uut/object_statuses(0)
add wave -position end  sim:/game_controller_tb/uut/player_hp

run 30000

