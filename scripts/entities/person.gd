@tool
class_name PeacePerson
extends Node2D
## Appearance can be changed in this scene; movement is stepped by the game.

@export_enum("Neutral:-1", "Blue:0", "Red:1") var team := 0:
	set(value):
		team = value
		refresh_sprite()
@export var peaceful := false:
	set(value):
		peaceful = value
		refresh_sprite()
@export var anomaly := false:
	set(value):
		anomaly = value
		refresh_sprite()
@export_range(0.1, 3.0, 0.1) var speed_multiplier := 1.0
@export_group("Images")
@export var blue_texture: Texture2D = preload("res://assets/sprites/person_blue.png"):
	set(value):
		blue_texture = value
		refresh_sprite()
@export var red_texture: Texture2D = preload("res://assets/sprites/person_red.png"):
	set(value):
		red_texture = value
		refresh_sprite()
@export var peaceful_texture: Texture2D = preload("res://assets/sprites/person_peaceful.png"):
	set(value):
		peaceful_texture = value
		refresh_sprite()

var cell := Vector2i.ZERO
var next_cell := Vector2i.ZERO
var dead := false
var retreated := false
var attack_elapsed := 0.0
var wait_remaining := 0.0
var cut_elapsed := 0.0
var waypoint := Vector2i(-1, -1)
var route_steps := 0
var reached_village := false
var seed_target := Vector2i(-1, -1)
var carried_seeds := 0:
	set(value):
		carried_seeds = value
		var carried_sprite := get_node_or_null("CarriedSeed") as Sprite2D
		if carried_sprite != null:
			carried_sprite.visible = carried_seeds > 0

func _ready() -> void:
	refresh_sprite()

func refresh_sprite() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = peaceful_texture if peaceful else (blue_texture if team == 0 else red_texture)
	var marker := get_node_or_null("AnomalyMarker") as Sprite2D
	if marker != null:
		marker.visible = anomaly and not peaceful
	var halo := get_node_or_null("PeaceHalo") as Sprite2D
	if halo != null:
		halo.visible = peaceful

func step(delta: float, game: Node) -> void:
	if dead or retreated:
		return
	var destination: Vector2 = game.board.point(next_cell)
	if position.distance_to(destination) > 0.1:
		var movement_speed: float = (game.settings.movement_speed + (game.level - 1) * game.settings.speed_gain_per_level) * speed_multiplier
		position = position.move_toward(destination, movement_speed * delta)
		if anomaly and not peaceful and game.trees.has(next_cell) and position.distance_to(destination) <= game.settings.cell_size * 0.5:
			game.destroy_tree(next_cell)
			game.emit_effect(destination, Color("ffa65c"))
		return
	cell = next_cell
	if not peaceful and game.is_matching_gate(cell, team):
		peaceful = true
		game.converted += 1
		game.emit_effect(position, Color.WHITE)
	if peaceful:
		visit_village(delta, game)
		return
	var target: Vector2i = game.hostile_destination(team)
	if cell == target:
		attack_elapsed += delta
		var interval: float = maxf(0.1, game.settings.building_attack_interval)
		while attack_elapsed >= interval:
			attack_elapsed -= interval
			game.attack_destination(self)
			if game.lost or game.won:
				attack_elapsed = 0.0
				break
		return
	attack_elapsed = 0.0
	if anomaly:
		move_anomaly(target, game)
		return
	var path: Array[Vector2i] = game.find_path(cell, target)
	if not path.is_empty():
		next_cell = path[0]
		cut_elapsed = 0.0
	else:
		var blocked_path: Array[Vector2i] = game.find_path(cell, target, true)
		if not blocked_path.is_empty():
			if game.trees.has(blocked_path[0]):
				cut_elapsed += delta
				game.trees[blocked_path[0]].cut_progress = cut_elapsed / game.settings.tree_cut_seconds
				if cut_elapsed >= game.settings.tree_cut_seconds:
					game.destroy_tree(blocked_path[0])
					cut_elapsed = 0.0
					game.notify_player("A trapped soldier cut a tree. Leave a route through a peace gate.")
			else:
				next_cell = blocked_path[0]

func visit_village(delta: float, game: Node) -> void:
	var home: Vector2i = game.village.home_cell(game.board)
	if carried_seeds > 0:
		if cell == home:
			game.deliver_seeds(self)
			wait_remaining = game.settings.peaceful_wait_min
		else:
			follow_path(game.find_path(cell, home))
		return
	if not reached_village:
		if cell != home:
			follow_path(game.find_path(cell, home))
			return
		game.record_arrival(self)
	# The player or another villager may have collected our reserved seed.
	if seed_target != Vector2i(-1, -1):
		if not game.seeds.has(seed_target):
			game.release_seed_claim(self)
		elif cell == seed_target:
			if game.take_seed(cell):
				carried_seeds = 1
			game.release_seed_claim(self)
			return
		else:
			var route: Array[Vector2i] = game.find_path(cell, seed_target)
			if not route.is_empty():
				follow_path(route)
				return
			game.release_seed_claim(self)
	if not game.village.within_home_area(cell, game.board):
		follow_path(game.find_path(cell, home))
		return
	wait_remaining -= delta
	if wait_remaining > 0.0:
		return
	if game.seeds.has(cell):
		if game.take_seed(cell):
			carried_seeds = 1
			return
	var seed_path: Array[Vector2i] = game.find_seed_path(self)
	if not seed_path.is_empty():
		seed_target = seed_path.back()
		follow_path(seed_path)
		return
	wander_near_village(game)

func follow_path(path: Array[Vector2i]) -> void:
	if not path.is_empty():
		next_cell = path[0]

func wander_near_village(game: Node) -> void:
	var options: Array[Vector2i] = []
	for direction in GridPathfinding.DIRECTIONS:
		var neighbor: Vector2i = cell + direction
		if game.board.inside(neighbor) and not game.trees.has(neighbor) and game.village.within_home_area(neighbor, game.board):
			options.append(neighbor)
	if not options.is_empty():
		next_cell = options[game.rng.randi_range(0, options.size() - 1)]
	wait_remaining = game.rng.randf_range(game.settings.peaceful_wait_min, maxf(game.settings.peaceful_wait_min, game.settings.peaceful_wait_max))

func move_anomaly(target: Vector2i, game: Node) -> void:
	if route_steps <= 0 or cell == waypoint:
		if game.rng.randf() < game.settings.detour_chance:
			waypoint = Vector2i(game.rng.randi_range(mini(cell.x, target.x), maxi(cell.x, target.x)), clampi(target.y + game.rng.randi_range(-game.settings.detour_rows, game.settings.detour_rows), 0, game.settings.grid_size.y - 1))
		else:
			waypoint = target
		route_steps = game.rng.randi_range(game.settings.route_steps_min, maxi(game.settings.route_steps_min, game.settings.route_steps_max))
	var route: Array[Vector2i] = game.find_anomaly_path(cell, waypoint)
	if route.is_empty():
		waypoint = target
		route = game.find_anomaly_path(cell, target)
	if not route.is_empty():
		next_cell = route[0]
		route_steps -= 1

