extends HBoxContainer

@onready var play_btn = get_child(2)
@onready var pause_btn = get_child(1)
@onready var reset_btn = get_child(0)

func _ready():
	play_btn.pressed.connect(get_tree().root.get_child(1).play)
	pause_btn.pressed.connect(get_tree().root.get_child(1).pause)	
	reset_btn.pressed.connect(get_tree().root.get_child(1).reset)
