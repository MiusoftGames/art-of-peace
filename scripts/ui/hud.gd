class_name PeaceHUD
extends CanvasLayer

signal march_pressed
signal restart_pressed
signal next_level_pressed
signal speed_pressed

func _ready() -> void:
	$Root/TopBar/SpeedButton.pressed.connect(func() -> void: speed_pressed.emit())
	$Root/TopBar/MarchButton.pressed.connect(func() -> void: march_pressed.emit())
	$Root/TopBar/RestartButton.pressed.connect(func() -> void: restart_pressed.emit())

	$Root/GameOver/ContinueButton.pressed.connect(func() -> void: next_level_pressed.emit())
	$Root/GameOver/RetryButton.pressed.connect(func() -> void: restart_pressed.emit())

func update_status(game: Node) -> void:
	$Root/ThreatHelp.visible = not game.settings.vary_level_layout
	$Root/Anomaly.position.y = 610.0 if game.get_node("Camps").get_child_count() > 2 else 500.0
	$Root/Delivered.position.y = 695.0
	var living: int = game.peaceful_count()
	$Root/TopBar/SpeedButton.text = "Normal 1x" if game.speed == 1.0 else ("Fast 2x" if game.speed == 2.0 else "Ultra 4x")
	$Root/TopBar/Seeds.text = "SEEDS  %d" % game.stock
	$Root/TopBar/Alive.text = "RESCUED %d / %d" % [game.rescued, game.goal]
	$Root/TopBar/Progress.max_value = game.goal
	$Root/TopBar/Progress.value = game.rescued
	$Root/TopBar/Level.text = "LEVEL %d" % game.level
	$Root/TopBar/Wave.text = "WAVE %d" % game.waves.wave
	$Root/TopBar/MarchButton.text = "Next level" if game.won else ("Try again" if game.lost else ("Pause" if game.running else "Begin march"))
	$Root/Population/Count.text = str(living)
	$Root/Population/Converted.text = "Converted: %d" % game.converted
	$Root/Population/Deaths.text = "Lost: %d" % game.deaths
	$Root/Population/Goal.text = "Rescue: %d" % game.goal
	$Root/Population/Spawned.text = "Spawned: %d" % game.spawned
	$Root/Delivered.text = "Delivered: %d" % game.delivered
	$Root/WaveStatus/Wave.text = "Wave %d" % game.waves.wave
	$Root/WaveStatus/Phase.text = "Protect camps"
	$Root/WaveStatus/Countdown.text = "Rest: %.0fs" % ceilf(game.waves.rest_remaining) if game.waves.rest_remaining > 0 else "Next: %.0fs" % ceilf(game.waves.spawn_remaining)
	$Root/Controls/TreeCost.text = "%d seed / tree" % game.settings.tree_cost
	$Root/Controls/Speed.text = "F: speed %dx" % int(game.speed)
	$Root/Anomaly/Description.text = "From level %d\nRandom arrivals" % game.settings.anomaly_start_level
	$Root/Message.text = game.message
	$Root/GameOver.visible = game.lost or game.won
	$Root/GameOver/Title.text = "PEACE RESTORED!" if game.won else "RESCUE FAILED"
	if not game.won:
		$Root/GameOver/Details.text = game.failure_reason
	elif game.level >= game.settings.random_goal_after_level:
		$Root/GameOver/Details.text = "%d people reached the village.\nNext level: a random goal of %d-%d." % [game.rescued, game.settings.random_goal_min, game.settings.maximum_rescue_goal]
	else:
		$Root/GameOver/Details.text = "%d people reached the village.\nNext level: rescue %d people." % [game.rescued, mini(game.settings.maximum_rescue_goal, game.goal + game.settings.goal_increment)]
	$Root/GameOver/Hint.text = "Level %d  /  %d rescued  /  %d lost" % [game.level, game.rescued, game.deaths]
	$Root/GameOver/ContinueButton.visible = game.won
	$Root/GameOver/RetryButton.visible = game.lost
