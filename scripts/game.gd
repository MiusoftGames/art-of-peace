extends Node2D
## Session coordinator. Objects, AI, spawning, pathfinding and HUD have their own files.

@export var settings: PeaceSettings = preload("res://resources/default_settings.tres")
@export_group("Spawnable Scenes")
@export var blue_soldier_scene: PackedScene = preload("res://scenes/entities/blue_soldier.tscn")
@export var red_soldier_scene: PackedScene = preload("res://scenes/entities/red_soldier.tscn")
@export var peaceful_person_scene: PackedScene = preload("res://scenes/entities/peaceful_person.tscn")
@export var anomaly_scene: PackedScene = preload("res://scenes/entities/anomaly.tscn")
@export var tree_scene: PackedScene = preload("res://scenes/entities/tree.tscn")
@export var seed_scene: PackedScene = preload("res://scenes/entities/seed.tscn")
@export var effect_scene: PackedScene = preload("res://scenes/entities/ripple.tscn")

@onready var board: ForestBoard = $Board
@onready var waves: WaveSpawner = $Systems/Waves
@onready var seed_spawner: Node = $Systems/SeedSpawner
@onready var combat: Node = $Systems/Combat
@onready var hud: PeaceHUD = $HUD

var trees: Dictionary = {}
var seeds: Dictionary = {}
var soldiers: Array[PeacePerson] = []
var stock := 0
var level := 1
var converted := 0
var deaths := 0
var spawned := 0
var goal := 10
var running := false
var lost := false
var speed := 1.0
var message := ""
var hover := Vector2i(-1, -1)
var rng := RandomNumberGenerator.new()
var anomaly_count := 0

func _ready() -> void:
	rng.randomize()
	board.settings = settings
	goal = settings.first_goal
	waves.configure(settings)
	waves.spawn_pair_requested.connect(spawn_pair)
	waves.message_requested.connect(notify_player)
	hud.march_pressed.connect(toggle_march)
	hud.restart_pressed.connect(reset_game)
	# Objects placed in main.tscn are the actual initial game state.
	for person in $Board/People.get_children():
		if person is PeacePerson:
			register_person(person)
	for tree in $Board/Trees.get_children():
		if tree is PeaceTree:
			tree.cell = board.cell_at(tree.position)
			trees[tree.cell] = tree
	for seed_node in $Board/Seeds.get_children():
		if seed_node is PeaceSeed:
			seed_node.cell = board.cell_at(seed_node.position)
			seeds[seed_node.cell] = seed_node
	notify_player("Protect the %d peaceful people. Grow their living population to %d." % [peaceful_count(), goal])
	hud.update_status(self)

func reset_game() -> void:
	# Reloading preserves every change made to the authored scenes.
	get_tree().call_deferred("reload_current_scene")

func register_person(person: PeacePerson) -> void:
	person.cell = board.cell_at(person.position)
	person.next_cell = person.cell
	person.position = board.point(person.cell)
	soldiers.append(person)

func make_person(team: int, cell: Vector2i, peaceful := false, anomaly := false) -> PeacePerson:
	var template := peaceful_person_scene if peaceful else (anomaly_scene if anomaly else (blue_soldier_scene if team == 0 else red_soldier_scene))
	var person := template.instantiate() as PeacePerson
	person.team = team
	person.peaceful = peaceful
	person.anomaly = anomaly
	person.position = board.point(cell)
	$Board/People.add_child(person)
	register_person(person)
	return person

func spawn_cell(team: int) -> Vector2i:
	for camp in $Camps.get_children():
		if camp is ArmyCamp and camp.team == team:
			return board.cell_at(board.to_local(camp.get_node("SpawnPoint").global_position))
	return Vector2i.ZERO

func is_matching_gate(cell: Vector2i, team: int) -> bool:
	for gate in $Board/Gates.get_children():
		if gate is PeaceGate and gate.team == team and board.cell_at(gate.position) == cell:
			return true
	return false

func protected(cell: Vector2i) -> bool:
	return cell == spawn_cell(0) or cell == spawn_cell(1) or is_matching_gate(cell, 0) or is_matching_gate(cell, 1)

func peaceful_count() -> int:
	var count := 0
	for person in soldiers:
		if person.peaceful and not person.dead:
			count += 1
	return count

func notify_player(text: String) -> void:
	message = text

func toggle_march() -> void:
	if lost:
		reset_game()
	else:
		running = not running
		notify_player("The armies are marching. Protect peaceful people." if running else "Paused. You can still collect seeds and plant trees.")
	hud.update_status(self)

func collect_at(local_position: Vector2) -> void:
	if lost:
		return
	for cell in seeds.keys():
		var seed_node: PeaceSeed = seeds[cell]
		if seed_node.position.distance_to(local_position) < seed_node.collect_radius:
			emit_effect(seed_node.position, Color("ffd47b"))
			seed_node.queue_free()
			seeds.erase(cell)
			stock += 1

func plant(cell: Vector2i) -> bool:
	if lost or not board.inside(cell) or protected(cell) or trees.has(cell):
		return false
	if stock < settings.tree_cost:
		notify_player("Find a golden seed first: hover over it to collect.")
		return false
	for person in soldiers:
		if person.cell == cell or person.next_cell == cell:
			notify_player("Someone is on that tile. Plant beside their path.")
			return false
	stock -= settings.tree_cost
	if seeds.has(cell):
		seeds[cell].queue_free()
		seeds.erase(cell)
	var tree := tree_scene.instantiate() as PeaceTree
	tree.cell = cell
	tree.position = board.point(cell)
	$Board/Trees.add_child(tree)
	trees[cell] = tree
	return true

func destroy_tree(cell: Vector2i) -> bool:
	if not trees.has(cell):
		return false
	trees[cell].queue_free()
	trees.erase(cell)
	return true

func remove_tree(cell: Vector2i) -> bool:
	return false if lost else destroy_tree(cell)

func emit_effect(local_position: Vector2, color: Color) -> void:
	var effect := effect_scene.instantiate() as Node2D
	effect.position = local_position
	effect.modulate = color
	$Board/Effects.add_child(effect)

func find_path(from: Vector2i, target: Vector2i, ignore_trees := false) -> Array[Vector2i]:
	return GridPathfinding.find_path(board, from, {target: true}, trees, ignore_trees)

func find_hunt_path(from: Vector2i) -> Array[Vector2i]:
	var targets: Dictionary = {}
	for person in soldiers:
		if person.peaceful and not person.dead:
			targets[person.cell] = true
	return GridPathfinding.find_path(board, from, targets, trees)

func spawn_pair() -> void:
	# If this pair contains an anomaly, choose its team alternately.
	var teams := [0, 1]
	var frequency := maxi(1, settings.anomaly_every)
	var first_is_anomaly := (spawned + 1) % frequency == 0
	var second_is_anomaly := (spawned + 2) % frequency == 0
	var preferred_team := 1 if anomaly_count % 2 == 0 else 0
	if (first_is_anomaly and preferred_team == 1) or (not first_is_anomaly and second_is_anomaly and preferred_team == 0):
		teams = [1, 0]
	for team in teams:
		spawned += 1
		var anomaly := spawned % frequency == 0
		make_person(team, spawn_cell(team), false, anomaly)
		if anomaly:
			anomaly_count += 1
			notify_player("Anomaly! Its unpredictable route breaks through trees.")

func record_death(person: PeacePerson) -> void:
	deaths += 1
	emit_effect(person.position, Color("f3a99a"))

func spawn_seed() -> void:
	if seeds.size() >= settings.maximum_seeds:
		return
	for attempt in range(50):
		var cell := Vector2i(rng.randi_range(1, settings.grid_size.x - 2), rng.randi_range(1, settings.grid_size.y - 2))
		if not trees.has(cell) and not seeds.has(cell) and not protected(cell):
			var seed_node := seed_scene.instantiate() as PeaceSeed
			seed_node.cell = cell
			seed_node.position = board.point(cell)
			$Board/Seeds.add_child(seed_node)
			seeds[cell] = seed_node
			return

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var local_position := board.to_local(event.position)
		hover = board.cell_at(local_position)
		collect_at(local_position)
	if event is InputEventMouseButton and event.pressed:
		var cell := board.cell_at(board.to_local(event.position))
		if event.button_index == MOUSE_BUTTON_LEFT:
			plant(cell)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			remove_tree(cell)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: toggle_march()
			KEY_R: reset_game()
			KEY_F: speed = 2.0 if speed == 1.0 else 1.0

func advance(delta: float) -> void:
	waves.advance(delta)
	for person in soldiers:
		person.step(delta, self)
	combat.resolve(self)
	var living := peaceful_count()
	if living == 0:
		lost = true
		running = false
		notify_player("No peaceful people survived. Restart to try again.")
	elif living >= goal:
		level += 1
		goal = settings.first_goal + (level - 1) * settings.goal_increment
		notify_player("Level %d! Protect and grow the peaceful population to %d." % [level, goal])

func _process(delta: float) -> void:
	if not lost:
		seed_spawner.advance(delta, self)
	if running:
		advance(delta * speed)
	board.show_preview(hover, not protected(hover) and not trees.has(hover) and stock >= settings.tree_cost, not lost)
	hud.update_status(self)
