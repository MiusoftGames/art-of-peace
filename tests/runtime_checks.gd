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
	check_resources_and_layout()
	check_seed_and_trees()
	check_waves()
	check_hunting_and_combat()
	check_goals_and_loss()
	check_anomalies_and_gates()
	check_normal_cutting()
	return results.duplicate()

func fresh_game() -> Node:
	var game := template.instantiate()
	game.settings = game.settings.duplicate(true)
	host.add_child(game)
	game.set_process(false)
	game.set_process_unhandled_input(false)
	return game

func check_initial_state() -> void:
	var game := fresh_game()
	results["five initial peaceful people"] = game.peaceful_count() == 5 and game.soldiers.size() == 5
	results["empty forest and paused start"] = game.trees.is_empty() and not game.running and game.goal == 10
	results["authored seeds and spawn markers"] = game.seeds.size() == 8 and game.spawn_cell(0) == Vector2i(0, 7) and game.spawn_cell(1) == Vector2i(18, 7)
	results["PNG sprites"] = game.soldiers[0].get_node("Sprite2D").texture.resource_path.ends_with(".png")
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
	game.waves.advance(4.9)
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
	game.waves.advance(7.0)
	results["wave rest blocks spawning"] = game.spawned == count and game.waves.rest_remaining == 1.0
	game.waves.advance(1.0)
	results["next wave starts"] = game.waves.wave == 2 and game.waves.pairs_sent == 0
	game.free()

func check_hunting_and_combat() -> void:
	for team in range(2):
		var game := fresh_game()
		clear_people(game)
		var prey: PeacePerson = game.make_person(team, Vector2i(9, 4), true)
		var hunter: PeacePerson = game.make_person(team, Vector2i(8, 4))
		hunter.step(0.0, game)
		results["team %d hunts its own peaceful people" % team] = hunter.next_cell == prey.cell
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
	game.advance(0.0)
	results["goals count living people"] = game.level == 1
	for i in range(5):
		game.make_person(-1, Vector2i(9, 7), true)
	game.stock = 7
	game.plant(Vector2i(1, 1))
	game.advance(0.0)
	results["10 survivors advance to goal 20"] = game.level == 2 and game.goal == 20 and game.peaceful_count() == 10
	results["level keeps people and forest"] = game.stock == 6 and game.trees.has(Vector2i(1, 1))
	for i in range(10):
		game.make_person(-1, Vector2i(9, 7), true)
	game.advance(0.0)
	results["20 survivors advance to goal 30"] = game.level == 3 and game.goal == 30
	clear_people(game)
	game.running = true
	game.advance(0.0)
	results["zero peaceful people ends game"] = game.lost and not game.running
	game.free()

func check_anomalies_and_gates() -> void:
	var game := fresh_game()
	clear_people(game)
	for i in range(50):
		game.spawn_pair()
	var indices: Array[int] = []
	var teams: Array[int] = []
	for i in range(game.soldiers.size()):
		if game.soldiers[i].anomaly:
			indices.append(i + 1)
			teams.append(game.soldiers[i].team)
	results["every 20th spawn is anomaly"] = indices == [20, 40, 60, 80, 100]
	results["anomalies alternate camps"] = teams == [1, 0, 1, 0, 1]
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
	breaker.step(0.5, game)
	results["anomaly destroys tree on contact"] = not game.trees.has(Vector2i(6, 7))
	var walker: PeacePerson = game.make_person(0, Vector2i(4, 12), false, true)
	walker.step(0.0, game)
	results["gate converts anomaly on contact"] = walker.peaceful and game.converted == 1
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
