extends MenuButton

func _ready() -> void:
	get_popup().id_pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed(id : int) -> void:
	match id:
		0: get_tree().root.get_child(1).get_child(6).visible=true

func _on_file_dialog_file_selected(path: String) -> void:
	var abs_path = ProjectSettings.globalize_path("res://Script")
	var output = []
	OS.execute("-c",[abs_path + "get_beatmap",path, "out.osu"], output)
	print(output)
