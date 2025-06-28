extends Control

@onready var metronome = get_node("Metronome")
@onready var music_stream = get_node("Music")
@onready var timeline = get_node("UI/Timeline");

var is_playing = false

var is_metronome_on = false;
var metronome_bpm = 120;
var metronome_divide = 1;

var music_src_path = ""

var music_point = 0

var project_name = ""
var music_duration = 0

var timeline_scale = 1

var beatmap = [0]

var selected_circle

func set_metronome_delay():
	metronome.set_metronome_delay()

func _ready():
	pass
	
func _process(delta: float) -> void:
	if (beatmap and is_playing):
		if Input.is_action_just_pressed("editor_add_circle"):
			beatmap.append(music_point * 1000)
			beatmap.sort()
			timeline.setup();
			timeline._render_circles()
	if (beatmap and selected_circle):
		if Input.is_action_just_pressed("editor_circle_move_left"):
			beatmap.erase(selected_circle)
			beatmap.append(selected_circle - 200)
			selected_circle = selected_circle - 200
			print(selected_circle)
			beatmap.sort()
			timeline.setup();
			timeline._render_circles()
		if Input.is_action_just_pressed("editor_circle_move_right"):
			beatmap.erase(selected_circle)
			beatmap.append(selected_circle + 200)
			selected_circle = selected_circle + 200
			timeline.setup();
			timeline._render_circles()
			print(selected_circle)
			beatmap.sort()
		if Input.is_action_just_pressed("editor_circle_delete"):
			beatmap.erase(selected_circle)
			selected_circle = null
			timeline.setup();
			timeline._render_circles()
			print(selected_circle)
	if (beatmap):
		if Input.is_action_just_pressed("editor_move_timeline_cursor_forward"):
			music_point += 1.5
			music_stream.stop()
			music_stream.play(music_point)
			get_node("UI/TimelineControl/Controls/Timing").text = str("%10.2f" % music_point)
			timeline.setup();
			timeline._render_circles()
		if Input.is_action_just_pressed("editor_move_timeline_cursor_backward"):
			music_point -= 1.5
			get_node("UI/TimelineControl/Controls/Timing").text = str("%10.2f" % music_point)
			timeline.setup();
			music_stream.stop()
			music_stream.play(music_point)
			timeline._render_circles()
		if (is_playing):
			music_point += delta
			timeline.setup();
			get_node("UI/TimelineControl/Controls/Timing").text = str("%10.2f" % music_point)

func play():
	if (!is_playing):
		is_playing = true;
		music_stream.play(music_point)
		timeline.setup();
		if (is_metronome_on):
			metronome.start_metronome()

func pause():
	if (is_playing):
		is_playing = false;
		music_stream.stop()
		metronome.stop_metronome()

func reset():
	is_playing = false;
	music_stream.stop();
	metronome.stop_metronome();
	music_point = 0
	
	
func _on_song_select_file_selected(path: String) -> void:
	var stream = AudioStreamMP3.load_from_file(path)
	music_stream.stream = stream
	music_duration = stream.get_length()
	get_node("UI/Menu2/MarginContainer/HBoxContainer/Values/DurationLb").text = str(music_duration)
	get_node("UI/Menu2/MarginContainer/HBoxContainer/Values/FileSelectBTN").text = str(path)
	music_src_path = path

func load_level (path):
	var level = FileAccess.open(path, FileAccess.READ).get_as_text()
	beatmap = Array(level.get_slice("[HitObjects]", 1).split("\n")).map(func(x): return int( x.get_slice(",", 2)));
	var music_file_name = level.get_slice("AudioFilename: ", 1).get_slice("\n", 0).trim_prefix(" ").trim_suffix("\n");
	music_src_path = path.split("/")
	music_src_path.remove_at(music_src_path.size() - 1);
	music_src_path = "/".join(music_src_path) + "/" + music_file_name.erase(music_file_name.length() - 1)
	_on_song_select_file_selected(music_src_path)
	project_name = level.get_slice("Title:", 1).get_slice("\n", 0).trim_prefix(" ").trim_suffix("\n");
	get_node("UI/Menu2/MarginContainer/HBoxContainer/Values/FileNameLE").text = project_name

func _on_level_select_file_selected(path: String) -> void:
	load_level(path)

func select_circle(timing):
	selected_circle = timing

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				timeline_scale += 0.15
				get_node("UI/TimelineControl/ScaleBox/ScaleE").text = str(timeline_scale)
				timeline._render_circles()
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				timeline_scale = max(timeline_scale - 0.15, 0.1)
				get_node("UI/TimelineControl/ScaleBox/ScaleE").text = str(timeline_scale)
				timeline._render_circles()


func _on_save_dialog_dir_selected(dir: String) -> void:
	if (beatmap):
		var directory = DirAccess.open(dir);
		if (Array(directory.get_files()).size() != 0):
			get_node("SaveDialog/Error").visible = true;
		DirAccess.copy_absolute(music_src_path, dir + "/" +music_src_path.get_slice("/", music_src_path.split("/").size() - 1))
		var out = FileAccess.open(dir + "/" + project_name.trim_suffix("\n") + ".osu", FileAccess.WRITE);
		assert(out.is_open())
		var string_to_save = "osu file format v5\n[General]\nAudioFilename:" + music_src_path.get_slice("/", music_src_path.split("/").size() - 1 ) + "\nAudioLeadIn: 0\nPreviewTime: -1\nCountdown: 0\nSampleSet: Soft\n[HitObjects]\n"
	
		out.store_string(string_to_save);
		out.store_string("\n".join(beatmap.map(func (x): return "0,0," + str(x) + ",1")))
