extends LineEdit

func _ready():
	text_submitted.connect(_on_change)
	
func _on_change(text):
	get_tree().root.get_child(1).timeline_scale = float(text)
