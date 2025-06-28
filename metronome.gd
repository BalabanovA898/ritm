extends AudioStreamPlayer

var timer = 0;
var delay = 0

@onready var settings = get_tree().root.get_child(1);
var is_on = false;

func _ready():
	delay = 60 * 1000 / settings.metronome_bpm * settings.metronome_divide;

func set_metronome_delay():
	delay = 60 * 1000 / settings.metronome_bpm * settings.metronome_divide;

func start_metronome():
	is_on = true;
	timer = 0

func stop_metronome():
	is_on = false;
	timer = 0;

func _process(delta: float) -> void:
	timer += delta * 1000
	if (timer >= delay):
		if (is_on):
			timer -= delay
			play()
