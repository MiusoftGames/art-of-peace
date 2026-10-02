@tool
class_name PeaceTree
extends Node2D

var cell := Vector2i.ZERO
var cut_progress := 0.0:
	set(value):
		cut_progress = clampf(value, 0.0, 1.0)
		if is_inside_tree():
			$CutProgress.visible = cut_progress > 0.0
			$CutProgress.value = cut_progress * 100.0
