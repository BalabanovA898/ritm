extends Node3D

var id;

func _process(delta: float) -> void:
	if (id + 1 < get_parent().beatmap_index):
		queue_free();
