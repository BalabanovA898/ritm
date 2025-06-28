extends HBoxContainer

@onready var metronome_divide_input = get_node("divide/MetronomeDivide")
@onready var metronome_on_toggle = get_node("on/MetronomeToggle")

func _ready() -> void:
	metronome_divide_input.text_submitted.connect(_set_divide);
	metronome_on_toggle.pressed.connect(_set_toggle_on);
	
func _set_divide(text):
	get_tree().root.get_child(1).metronome_divide = int(text);
	get_tree().root.get_child(1).set_metronome_delay()
	
func _set_toggle_on():
	get_tree().root.get_child(1).is_metronome_on = metronome_on_toggle.button_pressed;
	get_tree().root.get_child(1).set_metronome_delay()
