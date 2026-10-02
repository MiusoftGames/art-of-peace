class_name PeaceHUD
extends CanvasLayer

signal march_pressed
signal restart_pressed

func _ready() -> void:
	$Root/TopBar/MarchButton.pressed.connect(func() -> void: march_pressed.emit())
	$Root/TopBar/RestartButton.pressed.connect(func() -> void: restart_pressed.emit())

func update_status(game: Node) -> void:
	var living: int = game.peaceful_count()
	$Root/TopBar/Seeds.text = "SEEDS  %d" % game.stock
	$Root/TopBar/Alive.text = "ALIVE  %d / %d" % [living, game.goal]
	$Root/TopBar/Progress.max_value = game.goal
	$Root/TopBar/Progress.value = living
	$Root/TopBar/Level.text = "LEVEL %d" % game.level
	$Root/TopBar/Wave.text = "WAVE %d" % game.waves.wave
	$Root/TopBar/MarchButton.text = "Try again" if game.lost else ("Pause" if game.running else "Begin march")
	$Root/Population/Count.text = str(living)
	$Root/Population/Converted.text = "Converted: %d" % game.converted
	$Root/Population/Deaths.text = "Lost: %d" % game.deaths
	$Root/Population/Goal.text = "Goal: %d alive" % game.goal
	$Root/Population/Spawned.text = "Spawned: %d" % game.spawned
	$Root/WaveStatus/Wave.text = "Wave %d" % game.waves.wave
	$Root/WaveStatus/Countdown.text = "Rest: %.0fs" % ceilf(game.waves.rest_remaining) if game.waves.rest_remaining > 0 else "Next: %.0fs" % ceilf(game.waves.spawn_remaining)
	$Root/Controls/TreeCost.text = "%d seed / tree" % game.settings.tree_cost
	$Root/Controls/Speed.text = "F: speed %dx" % int(game.speed)
	$Root/Anomaly/Description.text = "Every %dth\nspawn breaks\nthrough trees." % game.settings.anomaly_every
	$Root/Message.text = game.message
	$Root/GameOver.visible = game.lost
	$Root/GameOver/Details.text = "Level %d  /  wave %d  /  %d converted" % [game.level, game.waves.wave, game.converted]
