class_name PeaceHUD
extends CanvasLayer

signal march_pressed
signal restart_pressed
signal next_level_pressed
signal speed_pressed
signal sound_pressed

var message_remaining := 0.0
var last_message := ""
var previous_stock := -1
var previous_rescued := -1

func _ready() -> void:
	$Root/TopBar/SpeedButton.pressed.connect(func() -> void: speed_pressed.emit())
	$Root/TopBar/MarchButton.pressed.connect(func() -> void: march_pressed.emit())
	$Root/TopBar/RestartButton.pressed.connect(func() -> void: restart_pressed.emit())
	$Root/TopBar/SoundButton.pressed.connect(func() -> void: sound_pressed.emit())
	$Root/StartPanel/Card/StartButton.pressed.connect(func() -> void: march_pressed.emit())
	$Root/GameOver/ContinueButton.pressed.connect(func() -> void: next_level_pressed.emit())
	$Root/GameOver/RetryButton.pressed.connect(func() -> void: restart_pressed.emit())

func update_status(game: Node) -> void:
	$Root/TopBar/SpeedButton.text = "%dx" % int(game.speed)
	$Root/TopBar/Seeds.text = "Seeds  %d" % game.stock
	$Root/TopBar/Alive.text = "Rescued  %d / %d" % [game.rescued, game.goal]
	$Root/TopBar/Progress.max_value = game.goal
	$Root/TopBar/Progress.value = game.rescued
	$Root/TopBar/Level.text = "LEVEL %d" % game.level
	$Root/TopBar/MarchButton.text = "Pause" if game.running else "Resume"
	$Root/TopBar/MarchButton.disabled = not game.started or game.won or game.lost
	$Root/TopBar/SoundButton.text = "Sound off" if game.sound.muted else "Sound on"
	$Root/StartPanel.visible = not game.started and not game.won and not game.lost
	$Root/StartPanel/Card/Goal.text = "Guide %d people home." % game.goal
	if game.stock != previous_stock and previous_stock >= 0:
		pulse($Root/TopBar/Seeds)
	if game.rescued != previous_rescued and previous_rescued >= 0:
		pulse($Root/TopBar/Alive)
	previous_stock = game.stock
	previous_rescued = game.rescued
	if game.message != last_message:
		last_message = game.message
		message_remaining = 4.0
	$Root/Message.text = game.message if message_remaining > 0.0 else "Hover: collect seeds   ·   Click: plant   ·   Right-click: remove   ·   Space: pause"
	$Root/GameOver.visible = game.lost or game.won
	$Root/GameOver/Title.text = "PEACE RESTORED!" if game.won else "RESCUE FAILED"
	$Root/GameOver/Details.text = "%d people made it home." % game.rescued if game.won else game.failure_reason
	$Root/GameOver/Hint.text = "Level %d  ·  %d rescued  ·  %d lost" % [game.level, game.rescued, game.deaths]
	$Root/GameOver/ContinueButton.visible = game.won
	$Root/GameOver/RetryButton.visible = game.lost

func pulse(label: Label) -> void:
	label.modulate = Color("36a653")
	create_tween().tween_property(label, "modulate", Color.WHITE, 0.35)

func _process(delta: float) -> void:
	message_remaining = maxf(0.0, message_remaining - delta)
