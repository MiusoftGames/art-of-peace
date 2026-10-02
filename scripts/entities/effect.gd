extends Node2D

@export var duration := 0.7
var elapsed := 0.0

func _process(delta: float) -> void:
	elapsed += delta
	var progress := clampf(elapsed / maxf(duration, 0.01), 0.0, 1.0)
	$Sprite2D.scale = Vector2.ONE * lerpf(0.4, 1.7, progress)
	$Sprite2D.modulate.a = 1.0 - progress
	if progress >= 1.0:
		queue_free()
