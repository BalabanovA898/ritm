extends MenuButton

func _ready() -> void:
	get_popup().id_pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed(id : int) -> void:
	match id:
		0: get_tree().root.get_child(1).get_child(3).visible = true;
		1: get_tree().root.get_child(1).get_child(7).visible = true;
