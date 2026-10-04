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
@onready var village: PeaceVillage = $Board/Village
@onready var waves: WaveSpawner = $Systems/Waves
@onready var seed_spawner: Node = $Systems/SeedSpawner
@onready var combat: Node = $Systems/Combat
@onready var hud = $HUD
var sound: Node
var started := false

var trees: Dictionary = {}
var seeds: Dictionary = {}
var seed_claims: Dictionary = {}
var soldiers: Array[PeacePerson] = []
var stock := 0
var level := 1
var converted := 0
var delivered := 0
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
var battle_winner := -1
var won := false
var rescued := 0
var failure_reason := ""
var anomaly_remaining := 1
var previous_layout: Array[Vector2i] = []

func _ready() -> void:
	sound = preload("res://scripts/systems/sound.gd").new()
	add_child(sound)
	rng.randomize()
	board.settings = settings
	stock = settings.starting_seeds
	goal = mini(settings.maximum_rescue_goal, settings.first_goal + (level - 1) * settings.goal_increment)
	preload("res://scripts/systems/level_director.gd").configure(self)
	preload("res://scripts/world/level_layout.gd").apply(self)
	waves.configure(settings)
	waves.level_offset = 0
	waves.spawn_remaining = waves.interval()
	waves.spawn_pair_requested.connect(spawn_pair)
	waves.message_requested.connect(notify_player)
	hud.march_pressed.connect(toggle_march)
	hud.restart_pressed.connect(reset_game)
	hud.next_level_pressed.connect(next_level)
	hud.speed_pressed.connect(cycle_speed)
	hud.sound_pressed.connect(func() -> void: sound.toggle())
	fit_playfield()
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
	notify_player("Rescue %d people: guide soldiers through their gate and into the village before a camp falls." % goal)
	hud.update_status(self)

func fit_playfield() -> void:
	# Preserve all authored grid entries while growing the board into the old side UI.
	var entries: Dictionary = {}
	for camp in $Camps.get_children():
		entries[camp] = camp_cell(camp)
	board.position = Vector2(122, 64)
	board.scale = Vector2.ONE * 1.1
	board.show_grid = true
	for camp in entries:
		camp.scale = Vector2.ONE * 1.1
		camp.position = Vector2(60 if camp.team == 0 else 1020, board.to_global(board.point(entries[camp])).y)
		camp.get_node("SpawnPoint").position = camp.to_local(board.to_global(board.point(entries[camp])))
		camp.get_node("Sprite2D").scale = Vector2.ONE * 0.8
		camp.get_node("NameLabel").hide()
		camp.get_node("Description").hide()
		camp.get_node("HealthBar").scale = Vector2.ONE * 0.75
	village.get_node("NameLabel").hide()

func reset_game() -> void:
	call_deferred("load_round", level)

func next_level() -> void:
	if won:
		call_deferred("load_round", level + 1)

func load_round(number: int) -> void:
	var fresh = load("res://main.tscn").instantiate()
	fresh.level = number
	fresh.settings = settings
	fresh.previous_layout.assign([village.home_cell(board), board.cell_at($Board/Gates/BlueGate.position)])
	var tree := get_tree()
	tree.root.add_child(fresh)
	tree.current_scene = fresh
	queue_free()

func record_arrival(person: PeacePerson) -> void:
	if person.peaceful and not person.dead and not person.reached_village:
		person.reached_village = true
		rescued = mini(goal, rescued + 1)
		sound.play("peace")
		emit_effect(village.position, Color("aaffab"))

func finish_round(success: bool, reason := "") -> void:
	if won or lost:
		return
	won = success
	lost = not success
	running = false
	failure_reason = reason
	sound.play("win" if success else "lose")
	notify_player("Peace restored! %d people reached the village." % rescued if won else reason)

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

func camp_cell(camp: ArmyCamp) -> Vector2i:
	return board.cell_at(board.to_local(camp.get_node("SpawnPoint").global_position))

func spawn_cell(team: int) -> Vector2i:
	var camp := get_camp(team)
	return camp_cell(camp) if camp != null else Vector2i.ZERO

func get_camps(team: int) -> Array[ArmyCamp]:
	var found: Array[ArmyCamp] = []
	for camp in $Camps.get_children():
		if camp is ArmyCamp and camp.team == team and not camp.defeated:
			found.append(camp)
	return found

func get_camp(team: int) -> ArmyCamp:
	var camps := get_camps(team)
	return camps[0] if not camps.is_empty() else null

func hostile_destination(team: int, from := Vector2i(-1, -1)) -> Vector2i:
	var camps := get_camps(1 - team)
	if from == Vector2i(-1, -1):
		return spawn_cell(1 - team)
	var targets: Dictionary = {}
	for camp in camps:
		targets[camp_cell(camp)] = true
	if targets.has(from):
		return from
	var route := GridPathfinding.find_path(board, from, targets, trees)
	if not route.is_empty():
		return route.back()
	var closest := spawn_cell(1 - team)
	for camp in camps:
		if from.distance_squared_to(camp_cell(camp)) < from.distance_squared_to(closest):
			closest = camp_cell(camp)
	return closest

func attack_destination(person: PeacePerson) -> void:
	if won or lost or person.peaceful or person.dead or person.retreated:
		return
	for camp in get_camps(1 - person.team):
		if person.cell == camp_cell(camp):
			var defeated := camp.take_damage(1)
			person.dead = true
			record_death(person)
			if defeated:
				declare_army_winner(person.team)
			return

func declare_army_winner(team: int) -> void:
	battle_winner = team
	finish_round(false, "A camp fell before the rescue was complete.")

func is_matching_gate(cell: Vector2i, team: int) -> bool:
	for gate in $Board/Gates.get_children():
		if gate is PeaceGate and gate.team == team and board.cell_at(gate.position) == cell:
			return true
	return false

func protected(cell: Vector2i) -> bool:
	for camp in $Camps.get_children():
		if camp is ArmyCamp and cell == camp_cell(camp):
			return true
	return village.is_building_cell(cell, board) or is_gate_cell(cell)

func is_gate_cell(cell: Vector2i) -> bool:
	return is_matching_gate(cell, 0) or is_matching_gate(cell, 1)

func peaceful_count() -> int:
	var count := 0
	for person in soldiers:
		if person.peaceful and not person.dead:
			count += 1
	return count

func notify_player(text: String) -> void:
	message = text

func cycle_speed() -> void:
	sound.play("click")
	speed = 2.0 if speed == 1.0 else (4.0 if speed == 2.0 else 1.0)
	hud.update_status(self)

func toggle_march() -> void:
	if won:
		next_level()
	elif lost:
		reset_game()
	else:
		started = true
		sound.play("click")
		running = not running
		notify_player("Guide each army through its color gate." if running else "Paused. You can still collect seeds and plant trees.")
	hud.update_status(self)

func collect_at(local_position: Vector2) -> void:
	if lost or won:
		return
	for cell in seeds.keys():
		var seed_node: PeaceSeed = seeds[cell]
		if seed_node.position.distance_to(local_position) < seed_node.collect_radius:
			emit_effect(seed_node.position, Color("ffd47b"))
			take_seed(cell)
			stock += 1
			sound.play("collect")

## Picking up a seed removes it; only village delivery credits villager stock.
func take_seed(cell: Vector2i) -> bool:
	if not seeds.has(cell):
		return false
	seeds[cell].queue_free()
	seeds.erase(cell)
	seed_claims.erase(cell)
	return true

func release_seed_claim(person: PeacePerson) -> void:
	if seed_claims.get(person.seed_target) == person:
		seed_claims.erase(person.seed_target)
	person.seed_target = Vector2i(-1, -1)

func find_seed_path(person: PeacePerson) -> Array[Vector2i]:
	var targets: Dictionary = {}
	for cell in seeds:
		var claimant = seed_claims.get(cell)
		if is_instance_valid(claimant) and not claimant.dead and claimant != person:
			continue
		targets[cell] = true
	var path := GridPathfinding.find_path(board, person.cell, targets, trees)
	if not path.is_empty():
		seed_claims[path.back()] = person
	return path

func deliver_seeds(person: PeacePerson) -> void:
	if not person.peaceful or person.dead or person.cell != village.home_cell(board) or person.carried_seeds <= 0:
		return
	stock += person.carried_seeds
	delivered += person.carried_seeds
	sound.play("collect")
	person.carried_seeds = 0
	emit_effect(village.position, Color("ffd47b"))

func plant(cell: Vector2i) -> bool:
	if lost or won or not board.inside(cell) or protected(cell) or trees.has(cell):
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
		take_seed(cell)
	var tree := tree_scene.instantiate() as PeaceTree
	tree.cell = cell
	tree.position = board.point(cell)
	$Board/Trees.add_child(tree)
	trees[cell] = tree
	sound.play("plant")
	tree.scale = Vector2.ONE * 0.3
	var pop := create_tween()
	pop.tween_property(tree, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return true

func destroy_tree(cell: Vector2i) -> bool:
	if not trees.has(cell):
		return false
	trees[cell].queue_free()
	trees.erase(cell)
	sound.play("chop")
	emit_effect(board.point(cell), Color("8de77a"))
	return true

func remove_tree(cell: Vector2i) -> bool:
	return false if lost or won else destroy_tree(cell)

func emit_effect(local_position: Vector2, color: Color) -> void:
	var effect := effect_scene.instantiate() as Node2D
	effect.position = local_position
	effect.modulate = color
	$Board/Effects.add_child(effect)

func find_path(from: Vector2i, target: Vector2i, ignore_trees := false) -> Array[Vector2i]:
	return GridPathfinding.find_path(board, from, {target: true}, trees, ignore_trees)

func emit_sword(local_position: Vector2, toward: Vector2) -> void:
	var swing := preload("res://scripts/entities/sword_swing.gd").new()
	swing.position = local_position
	swing.direction = toward.normalized() if toward.length_squared() > 0.0 else Vector2.RIGHT
	$Board/Effects.add_child(swing)
	sound.play("sword")

func find_anomaly_path(from: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var gates: Dictionary = {}
	for gate in $Board/Gates.get_children():
		if gate is PeaceGate:
			gates[board.cell_at(gate.position)] = true
	# Gates are obstacles for anomalies; trees are deliberately omitted.
	return GridPathfinding.find_path(board, from, {target: true}, gates)

func spawn_pair() -> void:
	if lost or won:
		return
	for camp in $Camps.get_children():
		if not camp is ArmyCamp or camp.defeated:
			continue
		var count := rng.randi_range(1, settings.maximum_spawn_group) if level > settings.burst_after_level else 1
		for index in range(count):
			spawned += 1
			var anomaly := false
			if level >= settings.anomaly_start_level:
				anomaly_remaining -= 1
				if anomaly_remaining <= 0:
					anomaly = true
					anomaly_remaining = rng.randi_range(settings.anomaly_gap_min, maxi(settings.anomaly_gap_min, settings.anomaly_gap_max))
			make_person(camp.team, camp_cell(camp), false, anomaly)
			if anomaly:
				anomaly_count += 1
				notify_player("Anomaly! Its unpredictable route breaks through trees.")

func record_death(person: PeacePerson) -> void:
	deaths += 1
	release_seed_claim(person)
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
	if not started and not event is InputEventKey:
		return
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
			KEY_F: cycle_speed()

func advance(delta: float) -> void:
	if won or lost:
		return
	waves.advance(delta)
	for person in soldiers:
		person.step(delta, self)
		if lost:
			break
	if lost:
		return
	combat.resolve(self)
	if peaceful_count() == 0:
		finish_round(false, "No peaceful people survived.")
	elif rescued >= goal:
		finish_round(true)

func _process(delta: float) -> void:
	if started and not lost and not won:
		seed_spawner.advance(delta, self)
	if running:
		advance(delta * speed)
	board.show_preview(hover, not protected(hover) and not trees.has(hover) and stock >= settings.tree_cost, started and not lost and not won)
	hud.update_status(self)
