extends RefCounted
## Runs against fresh instances of the real main scene, without changing it.

var results: Dictionary = {}
var host: Node
var template: PackedScene

func run(parent: Node) -> Dictionary:
	host = parent
	template = load("res://main.tscn")
	results.clear()
	check_initial_state()
	check_match_presentation()
	check_resources_and_layout()
	check_seed_and_trees()
	check_waves()
	check_easy_opening()
	check_level_layouts()
	check_speed_and_distant_seeds()
	check_later_variety()
	check_single_camp_hit()
	check_targets_and_combat()
	check_goals_and_loss()
	check_anomalies_and_gates()
	check_normal_cutting()
	check_village_and_deliveries()
	check_camp_victory_and_village_attack()
	return results.duplicate()

func fresh_game() -> Node:
	var game := template.instantiate()
	game.settings = game.settings.duplicate(true)
	game.settings.vary_level_layout = false
	host.add_child(game)
	game.set_process(false)
	game.set_process_unhandled_input(false)
	return game

func check_match_presentation() -> void:
	var game := fresh_game()
	var panel: Control = game.hud.get_node("Root/StartPanel")
	var seed_count: int = game.seeds.size()
	var instructions: Label = game.hud.get_node("Root/StartPanel/Card/Instructions")
	var start_button: Button = game.hud.get_node("Root/StartPanel/Card/StartButton")
	results["start instructions stay above the button"] = instructions.position.y + instructions.get_minimum_size().y < start_button.position.y
	game._process(30.0)
	results["start panel freezes the initial match"] = panel.visible and not game.started and not game.running and game.spawned == 0 and game.seeds.size() == seed_count
	game.hud.get_node("Root/StartPanel/Card/StartButton").pressed.emit()
	results["center start button begins match"] = game.started and game.running and not panel.visible
	game.toggle_march()
	results["pause does not reopen start panel"] = not game.running and not panel.visible
	var person: PeacePerson = game.make_person(0, game.board.cell_at(game.get_node("Board/Gates/BlueGate").position))
	person.step(0.0, game)
	results["conversion switches matching vector character art"] = person.peaceful and person.get_node("Sprite2D").texture.resource_path.ends_with("person_peaceful.svg") and person.get_node("Sprite2D").visible
	person.next_cell = person.cell + Vector2i.RIGHT
	person.step(0.05, game)
	results["walking adds a small rotation"] = absf(person.get_node("Sprite2D").rotation) > 0.0
	var attacker: PeacePerson = game.make_person(0, game.spawn_cell(1))
	attacker.step(1.0, game)
	var sword_visible := false
	for effect in game.get_node("Board/Effects").get_children():
		if effect.get_script().resource_path.ends_with("sword_swing.gd"):
			sword_visible = effect.sword.texture.resource_path.ends_with("sword.svg")
	results["camp attacks show a sword independent of soldier lifetime"] = attacker.dead and sword_visible
	results["board is enlarged and essential UI fits above it"] = is_equal_approx(game.board.scale.x, 1.1) and game.hud.get_node("Root/TopBar").size.y == 48.0
	game.sound.toggle()
	results["sound toggle mutes all voices"] = game.sound.muted
	for voice in game.sound.voices:
		results["sound toggle mutes all voices"] = results["sound toggle mutes all voices"] and not voice.playing
	game.free()
	game = fresh_game()
	results["mute preference survives restart"] = game.sound.muted
	game.sound.toggle()
	game.free()

func check_initial_state() -> void:
	var game := fresh_game()
	results["three initial peaceful people"] = game.peaceful_count() == 3 and game.soldiers.size() == 3
	results["empty forest and paused start"] = game.trees.is_empty() and not game.running and game.goal == 5
	results["authored seeds and spawn markers"] = game.seeds.size() == 8 and game.spawn_cell(0) == Vector2i(0, 7) and game.spawn_cell(1) == Vector2i(18, 7)
	results["matching vector sprites"] = game.soldiers[0].get_node("Sprite2D").texture.resource_path.ends_with(".svg")
	game.free()

func check_resources_and_layout() -> void:
	var game := fresh_game()
	var gate: PeaceGate = game.get_node("Board/Gates/BlueGate")
	gate.position = game.board.point(Vector2i(5, 12))
	results["gate positions come from scene"] = game.is_matching_gate(Vector2i(5, 12), 0) and not game.is_matching_gate(Vector2i(4, 12), 0)
	game.get_node("Camps/BlueCamp/SpawnPoint").position.x += game.settings.cell_size
	results["camp markers control spawn tile"] = game.spawn_cell(0) == Vector2i(1, 7)
	game.settings.tree_cost = 3
	game.stock = 3
	results["Inspector settings control tree cost"] = game.plant(Vector2i(6, 8)) and game.stock == 0
	var person: PeacePerson = game.soldiers[0]
	var replacement := load("res://assets/sprites/person_red.png") as Texture2D
	person.peaceful_texture = replacement
	results["texture changes update sprite"] = person.get_node("Sprite2D").texture == replacement
	game.free()

func check_seed_and_trees() -> void:
	var game := fresh_game()
	game.stock = 0
	game.collect_at(game.board.point(Vector2i(2, 5)))
	results["hover collection"] = game.stock == 1 and not game.seeds.has(Vector2i(2, 5))
	results["tree scene instantiation"] = game.plant(Vector2i(6, 8)) and game.trees[Vector2i(6, 8)] is PeaceTree and game.stock == 0
	results["tree removal without refund"] = game.remove_tree(Vector2i(6, 8)) and game.stock == 0 and not game.trees.has(Vector2i(6, 8))
	results["safe removal of empty tile"] = not game.remove_tree(Vector2i(6, 8))
	game.stock = 5
	results["gates and people protected from planting"] = not game.plant(Vector2i(4, 12)) and not game.plant(Vector2i(9, 7))
	game.free()

func check_waves() -> void:
	var game := fresh_game()
	game.waves.advance(9.9)
	results["slow first spawn"] = game.spawned == 0
	game.waves.advance(0.1)
	results["both armies spawn"] = game.spawned == 2
	var first_gap: float = game.waves.interval()
	for i in range(1200):
		game.waves.advance(0.5)
		clear_people(game)
	results["endless spawning past 100"] = game.spawned > 100
	results["waves get faster"] = game.waves.wave > 1 and game.waves.interval() < first_gap
	game.waves.configure(game.settings)
	game.waves.pairs_sent = game.settings.pairs_per_wave - 1
	game.waves.spawn_remaining = 0.0
	game.waves.advance(0.0)
	var count: int = game.spawned
	game.waves.advance(9.0)
	results["wave rest blocks spawning"] = game.spawned == count and game.waves.rest_remaining == 1.0
	game.waves.advance(1.0)
	results["next wave starts"] = game.waves.wave == 2 and game.waves.pairs_sent == 0
	game.free()

func check_targets_and_combat() -> void:
	for team in range(2):
		var game := fresh_game()
		clear_people(game)
		var prey: PeacePerson = game.make_person(team, Vector2i(9, 4), true)
		var hunter: PeacePerson = game.make_person(team, Vector2i(8, 4))
		hunter.step(0.0, game)
		var enemy_path: Array[Vector2i] = game.find_path(hunter.cell, game.spawn_cell(1 - team))
		results["team %d aims for enemy camp, not peaceful people" % team] = hunter.next_cell == enemy_path[0] and hunter.next_cell != prey.cell
		hunter.position = prey.position
		game.combat.resolve(game)
		results["team %d kills peaceful person and survives" % team] = game.soldiers.size() == 1 and game.soldiers[0] == hunter and not hunter.dead
		game.free()
	var combat_game := fresh_game()
	clear_people(combat_game)
	combat_game.make_person(0, Vector2i(9, 7))
	combat_game.make_person(1, Vector2i(9, 7))
	combat_game.combat.resolve(combat_game)
	results["opposing hostile soldiers fight"] = combat_game.soldiers.is_empty() and combat_game.deaths == 2
	combat_game.free()

func check_goals_and_loss() -> void:
	var game := fresh_game()
	game.converted = 100
	for i in range(5):
		game.make_person(-1, Vector2i(9, 7), true)
	game.advance(0.0)
	results["conversion alone does not win"] = not game.won and game.rescued < game.goal
	for person in game.soldiers:
		person.cell = game.village.home_cell(game.board)
		person.next_cell = person.cell
		person.position = game.board.point(person.cell)
		person.step(0.0, game)
	results["arrivals count once"] = game.rescued == 5
	game.soldiers[0].step(0.0, game)
	results["returning villager is not counted twice"] = game.rescued == 5
	game.running = true
	game.advance(0.0)
	results["goal freezes round and shows success"] = game.won and not game.running and not game.lost and game.level == 1
	var count: int = game.spawned
	game.spawn_pair()
	game.advance(10.0)
	results["completed round stops spawning"] = game.spawned == count
	game.hud.update_status(game)
	results["success offers next level"] = game.hud.get_node("Root/GameOver").visible and game.hud.get_node("Root/GameOver/ContinueButton").visible
	game.free()
	game = fresh_game()
	clear_people(game)
	game.running = true
	game.advance(0.0)
	results["zero peaceful people ends game"] = game.lost and not game.running
	game.free()
	var next = template.instantiate()
	next.level = 2
	host.add_child(next)
	next.set_process(false)
	results["fresh level two goal and state"] = next.goal == 6 and next.peaceful_count() == 3 and next.trees.is_empty() and next.stock == next.settings.starting_seeds and next.rescued == 0 and not next.running
	results["each level has a slow opening"] = next.waves.interval() == next.settings.initial_spawn_gap
	next.free()

func check_anomalies_and_gates() -> void:
	var game := fresh_game()
	clear_people(game)
	game.level = game.settings.anomaly_start_level
	for i in range(50):
		game.spawn_pair()
	var indices: Array[int] = []
	var teams: Array[int] = []
	for i in range(game.soldiers.size()):
		if game.soldiers[i].anomaly:
			indices.append(i + 1)
			teams.append(game.soldiers[i].team)
	results["anomalies appear early after unlock"] = not indices.is_empty() and indices[0] <= 3
	var gaps: Dictionary = {}
	var bounded := true
	for i in range(1, indices.size()):
		var gap: int = indices[i] - indices[i - 1]
		gaps[gap] = true
		bounded = bounded and gap >= 3 and gap <= 8
	results["anomaly intervals are random and bounded"] = gaps.size() > 1 and bounded
	clear_people(game)
	var steps: Dictionary = {}
	for i in range(40):
		game.rng.seed = i + 1
		var anomaly: PeacePerson = game.make_person(0, Vector2i(0, 7), false, true)
		anomaly.step(0.0, game)
		steps[anomaly.next_cell] = true
		clear_people(game)
	results["anomalies use varied routes"] = steps.size() > 1
	game.stock = 1
	game.plant(Vector2i(6, 7))
	var breaker: PeacePerson = game.make_person(0, Vector2i(5, 7), false, true)
	breaker.waypoint = Vector2i(6, 7)
	breaker.route_steps = 3
	breaker.step(0.0, game)
	breaker.step(1.0, game)
	results["anomaly destroys tree on contact"] = not game.trees.has(Vector2i(6, 7))
	var gate: PeaceGate = game.get_node("Board/Gates/BlueGate")
	gate.position = game.board.point(Vector2i(6, 7))
	var avoider: PeacePerson = game.make_person(0, Vector2i(5, 7), false, true)
	avoider.waypoint = Vector2i(6, 7)
	avoider.route_steps = 3
	avoider.step(0.0, game)
	var gate_route: Array[Vector2i] = game.find_anomaly_path(Vector2i(5, 7), game.spawn_cell(1))
	results["anomaly detours around gate in its way"] = avoider.next_cell != Vector2i(6, 7) and not gate_route.has(Vector2i(6, 7)) and not avoider.peaceful
	var avoided_all_gates := true
	for i in range(600):
		avoider.step(0.1, game)
		if game.is_gate_cell(avoider.next_cell) or avoider.peaceful:
			avoided_all_gates = false
	results["anomaly route never crosses either gate"] = avoided_all_gates
	gate.position = game.board.point(Vector2i(4, 12))
	var walker: PeacePerson = game.make_person(0, Vector2i(4, 12), false, true)
	walker.step(0.0, game)
	results["gate converts anomaly on contact"] = walker.peaceful and game.converted == 1
	game.free()

func check_village_and_deliveries() -> void:
	var game := fresh_game()
	clear_people(game)
	clear_seeds(game)
	var home: Vector2i = game.village.home_cell(game.board)
	results["village destination follows authored position"] = home == game.board.cell_at(game.village.position)
	game.village.position = game.board.point(Vector2i(9, 1))
	home = game.village.home_cell(game.board)
	game.stock = 1
	results["village delivery tile cannot be blocked"] = not game.plant(home)
	game.stock = 0
	var seed_node := game.seed_scene.instantiate() as PeaceSeed
	seed_node.cell = Vector2i(9, 3)
	seed_node.position = game.board.point(seed_node.cell)
	game.get_node("Board/Seeds").add_child(seed_node)
	game.seeds[seed_node.cell] = seed_node
	var person: PeacePerson = game.make_person(-1, Vector2i(9, 5), true)
	person.step(0.0, game)
	results["peaceful person heads to village first"] = person.next_cell == Vector2i(9, 4) and not person.reached_village and person.carried_seeds == 0
	var picked_up := false
	for i in range(200):
		person.step(0.1, game)
		if person.carried_seeds > 0:
			picked_up = true
			break
	results["villager picks up seed after visiting village"] = picked_up and person.reached_village and not game.seeds.has(Vector2i(9, 3))
	results["pickup waits for delivery to credit stock"] = game.stock == 0 and game.delivered == 0 and person.get_node("CarriedSeed").visible
	for i in range(150):
		person.step(0.1, game)
		if game.delivered > 0:
			break
	results["return to village credits exactly one seed"] = game.stock == 1 and game.delivered == 1 and person.carried_seeds == 0 and person.cell == home and not person.get_node("CarriedSeed").visible
	var stayed_near := true
	for i in range(200):
		person.step(0.1, game)
		if not game.village.within_home_area(person.next_cell, game.board):
			stayed_near = false
	results["idle villagers stay around village"] = stayed_near
	game.free()
	game = fresh_game()
	clear_people(game)
	clear_seeds(game)
	game.stock = 0
	var collector: PeacePerson = game.make_person(-1, Vector2i(9, 3), true)
	collector.reached_village = true
	collector.carried_seeds = 1
	game.make_person(0, Vector2i(9, 3))
	game.combat.resolve(game)
	results["dead carrier does not credit undelivered seed"] = game.stock == 0 and game.delivered == 0 and game.peaceful_count() == 0
	game.free()
	game = fresh_game()
	clear_people(game)
	clear_seeds(game)
	game.village.position = game.board.point(home)
	game.stock = 0
	var reserved_seed := game.seed_scene.instantiate() as PeaceSeed
	reserved_seed.cell = Vector2i(9, 3)
	reserved_seed.position = game.board.point(reserved_seed.cell)
	game.get_node("Board/Seeds").add_child(reserved_seed)
	game.seeds[reserved_seed.cell] = reserved_seed
	var first: PeacePerson = game.make_person(-1, home, true)
	var second: PeacePerson = game.make_person(-1, home, true)
	first.reached_village = true
	second.reached_village = true
	first.step(0.0, game)
	second.step(0.0, game)
	results["villagers reserve different seeds"] = first.seed_target == Vector2i(9, 3) and second.seed_target == Vector2i(-1, -1)
	game.collect_at(reserved_seed.position)
	for i in range(30):
		first.step(0.1, game)
	results["player pickup safely cancels villager reservation"] = first.seed_target == Vector2i(-1, -1) and first.carried_seeds == 0 and game.stock == 1 and game.delivered == 0
	game.free()

func check_normal_cutting() -> void:
	var game := fresh_game()
	clear_people(game)
	game.stock = 3
	game.plant(Vector2i(1, 7))
	var person: PeacePerson = game.make_person(0, Vector2i(0, 7))
	person.step(0.1, game)
	results["normal soldier detours without cutting"] = person.next_cell != Vector2i(1, 7) and game.trees.has(Vector2i(1, 7))
	person.next_cell = person.cell
	game.plant(Vector2i(0, 6))
	game.plant(Vector2i(0, 8))
	for i in range(21):
		person.step(0.1, game)
	results["trapped soldier cuts blocking tree"] = game.trees.size() == 2
	game.free()

func clear_people(game: Node) -> void:
	for person in game.soldiers:
		person.free()
	game.soldiers.clear()
	game.seed_claims.clear()

func check_camp_victory_and_village_attack() -> void:
	for team in range(2):
		var game := fresh_game()
		var camp: ArmyCamp = game.get_camp(1 - team)
		camp.health = 2
		var attacker: PeacePerson = game.make_person(team, game.spawn_cell(1 - team))
		attacker.step(0.5, game)
		results["team %d respects attack interval" % team] = camp.health == 2
		attacker.step(0.5, game)
		results["team %d damages opposing camp" % team] = camp.health == 1 and not game.lost
		attacker.step(100.0, game)
		game.attack_destination(attacker)
		results["team %d attacker dies after one damage" % team] = attacker.dead and camp.health == 1 and game.deaths == 1
		var anomaly: PeacePerson = game.make_person(team, game.spawn_cell(1 - team), false, true)
		anomaly.step(100.0, game)
		results["team %d anomaly attacks once then dies" % team] = anomaly.dead and camp.health == 0 and game.deaths == 2
		results["team %d camp fall fails rescue" % team] = camp.defeated and game.lost and not game.running
		results["team %d never invades village" % team] = game.village.health == game.village.max_health and game.hostile_destination(team) == game.spawn_cell(1 - team)
		game.hud.update_status(game)
		results["team %d failure offers retry" % team] = game.hud.get_node("Root/GameOver/RetryButton").visible and not game.hud.get_node("Root/GameOver/ContinueButton").visible
		game.free()

func clear_seeds(game: Node) -> void:
	for seed_node in game.seeds.values():
		seed_node.free()
	game.seeds.clear()
	game.seed_claims.clear()

func check_easy_opening() -> void:
	var game := fresh_game()
	var initial_gap: float = game.waves.interval()
	game.waves.pairs_sent = 9
	results["opening wave keeps steady slow gaps"] = game.waves.interval() == initial_gap and initial_gap == 10.0
	for i in range(20):
		game.spawn_pair()
	var anomaly_found := false
	for person in game.soldiers:
		anomaly_found = anomaly_found or person.anomaly
	results["opening wave has no anomalies"] = not anomaly_found
	game.waves.wave = 2
	game.waves.pairs_sent = 0
	results["difficulty increases between waves"] = game.waves.interval() < initial_gap
	clear_people(game)
	game.waves.wave = 1
	for team in range(2):
		var person: PeacePerson = game.make_person(team, game.spawn_cell(team))
		person.step(0.0, game)
		var route: Array[Vector2i] = game.find_path(person.cell, game.spawn_cell(1 - team))
		results["opening team %d targets opposing camp" % team] = person.next_cell == route[0]
		var gate_route: Array[Vector2i] = game.find_path(person.cell, game.board.cell_at(game.get_node("Board/Gates/BlueGate" if team == 0 else "Board/Gates/RedGate").position))
		results["opening team %d does not seek its gate" % team] = person.next_cell != gate_route[0]
		clear_people(game)
	game.free()

func check_level_layouts() -> void:
	var previous: Array[Vector2i] = []
	for number in range(1, 5):
		var game = template.instantiate()
		game.level = number
		game.previous_layout = previous
		host.add_child(game)
		game.set_process(false)
		var positions: Array[Vector2i] = [game.village.home_cell(game.board)]
		for gate in game.get_node("Board/Gates").get_children():
			positions.append(game.board.cell_at(gate.position))
		if not previous.is_empty():
			results["level %d moves village and both gates" % number] = positions[0] != previous[0] and positions[1] != previous[1] and positions[2] != previous[2]
		results["level %d centered village and mirrored gates" % number] = positions[0].x == 9 and positions[1].x + positions[2].x == 18 and positions[1].y + positions[2].y == 14
		results["level %d gates move inward" % number] = positions[1].x == mini(number + 1, 7) and positions[1].y < 7 and positions[2].y > 7
		previous = positions
		for i in range(10):
			game.spawn_pair()
		results["level %d anomaly eligibility" % number] = game.anomaly_count == 0
		results["level %d starts with slow spawns and original movement" % number] = game.waves.interval() == 10.0 and game.settings.movement_speed == 48.0
		var retry = template.instantiate()
		retry.level = number
		retry.previous_layout = positions
		host.add_child(retry)
		retry.set_process(false)
		results["level %d retry changes layout" % number] = retry.village.position != game.village.position and retry.get_node("Board/Gates/BlueGate").position != game.get_node("Board/Gates/BlueGate").position
		retry.free()
		game.free()

func check_speed_and_distant_seeds() -> void:
	var game := fresh_game()
	game.cycle_speed()
	results["fast mode is 2x"] = game.speed == 2.0
	game.cycle_speed()
	results["ultra mode is 4x"] = game.speed == 4.0
	game.cycle_speed()
	results["speed returns to normal"] = game.speed == 1.0
	clear_people(game)
	clear_seeds(game)
	game.stock = 0
	var seed_node: PeaceSeed = game.seed_scene.instantiate()
	seed_node.cell = Vector2i(0, 1)
	seed_node.position = game.board.point(seed_node.cell)
	game.get_node("Board/Seeds").add_child(seed_node)
	game.seeds[seed_node.cell] = seed_node
	var person: PeacePerson = game.make_person(-1, game.village.home_cell(game.board), true)
	var collected := false
	for i in range(1800):
		person.step(0.1, game)
		collected = collected or person.carried_seeds > 0
		if game.delivered > 0:
			break
	results["villager collects distant seed and returns"] = collected and game.delivered == 1 and game.stock == 1
	game.rescued = game.goal
	person.reached_village = false
	game.record_arrival(person)
	results["rescue counter does not exceed goal"] = game.rescued == game.goal
	game.free()
	var later = template.instantiate()
	later.level = 100
	host.add_child(later)
	later.set_process(false)
	results["late level goal random within six to fifteen"] = later.goal >= 6 and later.goal <= 15
	later.free()

func check_later_variety() -> void:
	var director = preload("res://scripts/systems/level_director.gd")
	var goals: Dictionary = {}
	for seed_value in range(20):
		var game := fresh_game()
		game.level = 9
		game.rng.seed = seed_value + 10
		director.configure(game)
		goals[game.goal] = true
		results["random goal %d within bounds" % seed_value] = game.goal >= 6 and game.goal <= 15
		game.free()
	results["later goals vary"] = goals.size() > 1
	var game := fresh_game()
	game.level = 5
	game.rng.seed = 42
	for i in range(2):
		game.spawn_pair()
	results["level five gets anomaly within first two pulses"] = game.anomaly_count >= 1
	game.free()
	game = fresh_game()
	game.level = 8
	game.rng.seed = 42
	var group_sizes: Dictionary = {}
	var bounded := true
	for i in range(20):
		clear_people(game)
		game.spawn_pair()
		for team in range(2):
			var count := 0
			for person in game.soldiers:
				if person.team == team:
					count += 1
			bounded = bounded and count >= 1 and count <= 3
			group_sizes[count] = true
	results["level eight has varied one to three person groups"] = bounded and group_sizes.size() == 3
	game.free()
	game = fresh_game()
	game.level = 9
	game.settings.vary_level_layout = true
	game.settings.extra_camp_chance = 0.0
	director.configure(game)
	results["extra camp is optional"] = game.get_node("Camps").get_child_count() == 2
	game.settings.extra_camp_chance = 1.0
	director.configure(game)
	results["extra camp adds only one reinforcement"] = game.get_node("Camps").get_child_count() == 3
	var extra: ArmyCamp = game.get_node("Camps").get_child(2)
	var entry: Vector2i = game.camp_cell(extra)
	results["extra camp entry safe and distinct"] = game.board.inside(entry) and game.protected(entry) and entry != game.spawn_cell(extra.team)
	var attacker: PeacePerson = game.make_person(1 - extra.team, entry)
	results["soldiers can target reinforcement camp"] = game.hostile_destination(attacker.team, entry) == entry
	var hp: int = extra.health
	game.attack_destination(attacker)
	results["reinforcement camp takes damage"] = extra.health == hp - 1
	clear_people(game)
	game.spawn_pair()
	var at_extra := false
	for person in game.soldiers:
		at_extra = at_extra or person.cell == entry
	results["reinforcement camp spawns soldiers"] = at_extra
	game.free()

func check_single_camp_hit() -> void:
	for is_anomaly in [false, true]:
		var game := fresh_game()
		var camp: ArmyCamp = game.get_camp(1)
		var attacker: PeacePerson = game.make_person(0, game.spawn_cell(1), false, is_anomaly)
		attacker.step(100.0, game)
		attacker.step(100.0, game)
		game.attack_destination(attacker)
		results["single camp hit anomaly=%s" % is_anomaly] = camp.health == camp.max_health - 1 and attacker.dead and game.deaths == 1
		game.combat.resolve(game)
		results["dead attacker removed anomaly=%s" % is_anomaly] = not game.soldiers.has(attacker) and game.deaths == 1
		game.free()
