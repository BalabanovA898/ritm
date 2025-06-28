extends LineEdit

func _ready():
	text_submitted.connect(_set_bpm)

func _set_bpm(text):
	get_tree().root.get_child(1).metronome_bpm = int(text);
	get_tree().root.get_child(1).set_metronome_delay()
