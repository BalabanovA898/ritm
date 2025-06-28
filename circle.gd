extends Node2D

var timing

func _on_button_pressed() -> void:
	get_tree().root.get_child(1).select_circle(timing)
