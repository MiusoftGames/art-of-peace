@tool
class_name PeaceSeed
extends Node2D

@export_range(1.0, 60.0) var collect_radius := 22.0
@export var bob_height := 2.0
@export var bob_speed := 3.0
var cell := Vector2i.ZERO
var elapsed := 0.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	elapsed += delta
	$Sprite2D.position.y = sin(elapsed * bob_speed + position.x) * bob_height
