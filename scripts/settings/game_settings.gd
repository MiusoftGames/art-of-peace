@tool
class_name PeaceSettings
extends Resource
## Shared tuning resource. Edit resources/default_settings.tres in the Inspector.

@export_category("Forest Grid")
@export var grid_size := Vector2i(19, 15):
	set(value):
		grid_size = Vector2i(maxi(3, value.x), maxi(3, value.y))
		emit_changed()
@export_range(20.0, 100.0, 1.0) var cell_size := 40.0:
	set(value):
		cell_size = maxf(20.0, value)
		emit_changed()

@export_category("Rescue Goals")
@export_range(1, 100) var first_goal := 5
@export_range(1, 100) var goal_increment := 1
@export_range(1, 30) var maximum_rescue_goal := 15

@export_category("Later Level Variety")
@export_range(1, 30) var random_goal_after_level := 8
@export_range(1, 15) var random_goal_min := 6
@export_range(1, 30) var burst_after_level := 7
@export_range(1, 5) var maximum_spawn_group := 3
@export_range(1, 30) var extra_camp_after_level := 8
@export_range(0.0, 1.0, 0.05) var extra_camp_chance := 0.35

@export_category("Level Layout")
@export var vary_level_layout := true

@export_category("Waves")
@export_range(1, 100) var pairs_per_wave := 10
@export_range(0.1, 30.0, 0.1) var initial_spawn_gap := 10.0
@export_range(0.1, 10.0, 0.05) var minimum_spawn_gap := 0.65
@export_range(0.0, 5.0, 0.05) var gap_reduction_per_wave := 1.0
@export_range(0.0, 60.0, 0.5) var wave_rest_seconds := 10.0
@export_range(1, 20) var anomaly_gap_min := 3
@export_range(1, 30) var anomaly_gap_max := 8
@export_range(1, 100) var anomaly_start_level := 5

@export_category("People")
@export_range(1.0, 200.0, 1.0) var movement_speed := 48.0
@export_range(0.0, 20.0, 0.5) var speed_gain_per_level := 0.0
@export_range(1.0, 40.0, 1.0) var contact_distance := 15.0
@export_range(0.0, 5.0, 0.1) var peaceful_wait_min := 0.3
@export_range(0.0, 5.0, 0.1) var peaceful_wait_max := 1.0

@export_category("Camp Attacks")
@export_range(0.1, 5.0, 0.1) var building_attack_interval := 1.0

@export_category("Trees and Seeds")
@export_range(0, 100) var starting_seeds := 8
@export_range(1, 10) var tree_cost := 1
@export_range(0.1, 10.0, 0.1) var tree_cut_seconds := 2.0
@export_range(0.1, 10.0, 0.1) var seed_spawn_seconds := 1.4
@export_range(1, 100) var maximum_seeds := 20

@export_category("Anomaly Routes")
@export_range(0.0, 1.0, 0.05) var detour_chance := 0.55
@export_range(0, 10) var detour_rows := 3
@export_range(1, 20) var route_steps_min := 3
@export_range(1, 20) var route_steps_max := 6
