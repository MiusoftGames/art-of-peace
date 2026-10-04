extends Node2D
## Lives on the board so the attack remains visible after a soldier is removed.

var elapsed := 0.0
var duration := 0.28
var direction := Vector2.RIGHT
var sword: Sprite2D

func _ready() -> void:
	z_index = 10
	rotation = direction.angle()
	sword = Sprite2D.new()
	sword.texture = preload("res://assets/sprites/sword.svg")
	sword.scale = Vector2.ONE * 0.7
	add_child(sword)
	update_pose()

func update_pose() -> void:
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var angle := lerpf(-1.0, 1.0, sin(progress * PI * 0.5))
	sword.position = Vector2(21, 0).rotated(angle)
	sword.rotation = angle + PI * 0.5
	modulate.a = minf(1.0, (1.0 - progress) * 4.0)
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, 27.0, -0.9, lerpf(-0.8, 1.0, elapsed / duration), 14, Color(1, 1, 0.9, 0.6), 2.0, true)

func _process(delta: float) -> void:
	var game := get_tree().current_scene
	if game != null and "running" in game and not game.running and not game.won and not game.lost:
		return
	elapsed += delta
	update_pose()
	if elapsed >= duration:
		queue_free()
