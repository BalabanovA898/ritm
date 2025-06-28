extends Node3D

var level_index: int = Global.selected_level_index


const DEBUG_DIFFICULTY = "hard"
const DEBUG_SPEED = 5.0
const MIN_PLATFORM_LENGTH = 0.6
const DEBUG_NOOB_COEFICIENT = 0.7
const JUMP_TIME = 0.4

var current_directory
var list_of_levels
var beatmap
var time = 0
var beatmap_index = 0
var platform
var path_to_music = ""
var SENSETIVITY = 0.003

var last_platform_position = 0
var next_platform_position = 0

@onready var Player = get_node("PlayerController").get_child(0)
@onready var sky: WorldEnvironment = get_node("Sky")
@onready var light = get_node("Light")
@onready var borders = [get_node("Border"), get_node("Border2"), get_node("Border3"), get_node("Border4")]
@onready var timer: Sprite2D = get_node("UI").get_child(0)
@onready var ui_manager = $UIManager

func _ready():
	print("Загрузка уровня с индексом: ", level_index)
	timer.global_position.y = 0
	load_level(level_index)
	
	for x in borders:
		x.Player = Player
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(255, 255, 255, 0)
		material.shading_mode = 1
		x.get_child(0).set_surface_override_material(0, material) 
	
	if path_to_music != "":
		var music_path = current_directory + "/" + path_to_music
		
		music_path = music_path.replace("\n", "").replace("\r", "")
		
		if FileAccess.file_exists(music_path):
			print("Загрузка музыки: ", music_path)
			$MusicController.load_music(music_path)
			$MusicController.play() 
		else:
			push_error("Файл музыки не найден: " + music_path)
			print("Попытка найти файл в: ", DirAccess.get_files_at(current_directory))
	
	sky.environment.sky.sky_material.set("shader_parameter/rotation_speed", difficulty_to_rotation_speed(DEBUG_DIFFICULTY))
	platform = preload("res://platform.tscn")

	ui_manager.init(Player, $MusicController, SENSETIVITY)
	ui_manager.connect("retry_pressed", reset_game)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	timer.scale.x = (1.0 - time / beatmap[-1]) * get_viewport().size.x
	if Player.global_transform.origin.y <= -1:
		ui_manager.show_death_screen()
	if beatmap_index < beatmap.size() - 1:
		time += delta * 1000
		if time > beatmap[beatmap_index]:
			beatmap_index += 1
			
			create_platform(beatmap_index)
			
			var r = randi_range(0, 1) * 255
			var g = randi_range(0, 1) * 255
			var b =  randi_range(0, 1) * 255
			
			if r == 255 and g == 255 and b == 255:
				light.light_color = Color(250, 160, 150)
			else:
				sky.environment.sky.sky_material.set("shader_parameter/sun_color", Vector3(r + 1, g  + 1, b + 1))
				light.light_color = Color(255 - r, 255 - g, 255 - b)

func load_level(index: int):
	var dir: DirAccess = DirAccess.open("user://levels")
	if not dir: 
		DirAccess.make_dir_absolute("user://levels")
		dir = DirAccess.open("user://levels")
	
	list_of_levels = dir.get_directories()
	if index < 0 or index >= list_of_levels.size():
		push_error("Неверный индекс уровня: ", index)
		index = 0 
	
	current_directory = "user://levels/" + list_of_levels[index]
	dir = DirAccess.open(current_directory)
	var files = dir.get_files()
	var levels = Array(files).filter(func(x): return x.find(".osu") != -1)
	
	var level
	
	if levels.any(func(x): return x.to_lower().find(DEBUG_DIFFICULTY) != -1):
		level = FileAccess.open(current_directory + "/" + levels.filter(func(x): return x.to_lower().find(DEBUG_DIFFICULTY) != -1)[0], FileAccess.READ).get_as_text()
	else:
		level = FileAccess.open(current_directory + "/" + levels[0], FileAccess.READ).get_as_text()
	
	beatmap = Array(level.get_slice("[HitObjects]", 1).split("\n")).map(func(x): return int(x.get_slice(",", 2)))
	
	var i = 1
	while i < beatmap.size():
		if float(beatmap[i] - beatmap[i - 1])/1000.0 * DEBUG_SPEED < MIN_PLATFORM_LENGTH + (DEBUG_SPEED * JUMP_TIME) * DEBUG_NOOB_COEFICIENT:
			beatmap.remove_at(i)
		else:
			i += 1
	
	path_to_music = level.get_slice("AudioFilename: ", 1).get_slice("\n", 0).trim_prefix(" ").trim_suffix("\n")
	print("Загружен уровень: ", list_of_levels[index], " | Музыка: ", path_to_music)

func create_platform(index: int) -> void:
	var scene = platform.instantiate()
	scene.add_to_group("platform")
	var time_between_platforms = (beatmap[beatmap_index] - beatmap[beatmap_index - 1])
	var duration_as_distance = time_between_platforms / 1000.0 * DEBUG_SPEED 
	add_child(scene)
	scene.scale.x = duration_as_distance - DEBUG_SPEED * JUMP_TIME * DEBUG_NOOB_COEFICIENT
	var c = duration_as_distance/2 + DEBUG_SPEED * JUMP_TIME * DEBUG_NOOB_COEFICIENT
	var a = 1 if abs(last_platform_position - next_platform_position) == 2 else 0
	var distance_to_next_platform = sqrt(max(c ** 2 - a ** 2 * DEBUG_NOOB_COEFICIENT, 0))
	last_platform_position = next_platform_position
	scene.position = Vector3(Player.position.x + distance_to_next_platform, 0, next_platform_position)
	scene.id = beatmap_index
	next_platform_position = randi_range(-1, 1)
	highlight_next_position(next_platform_position)
	
func highlight_next_position(next_position: int):
	next_position += 1
	for x in borders:
		var a: MeshInstance3D = x.get_child(0)
		var material = a.get_surface_override_material(0)
		if material:
			material.shading_mode = 0
			material.transparency = 1
			material.albedo_color = Color(255, 255, 255, 0.4)
			a.set_surface_override_material(0, material)
			a.material_overlay = material
	
	for x in range(next_position, next_position + 2):
		if x < borders.size():
			var a: MeshInstance3D = borders[x].get_child(0)
			var material = a.get_surface_override_material(0)
			if material:
				material.shading_mode = 0
				material.transparency = 1
				material.albedo_color = Color(255, 0, 0, 0.4)
				a.set_surface_override_material(0, material)
				a.material_overlay = material
		
func difficulty_to_rotation_speed(difficulty: String):
	if difficulty == "easy": return 0.4
	if difficulty == "normal": return 0.6
	if difficulty == "hard": return 0.8
	if difficulty == "insane": return 1
	return 0.5

func reset_game():
	for child in get_children():
		if child.is_in_group("platform"):
			child.queue_free()
	
	time = 0
	beatmap_index = 0
	last_platform_position = 0
	next_platform_position = 0

	Player.global_transform.origin = Vector3(0, 2, 0)
	Player.velocity = Vector3.ZERO
	
	load_level(level_index)
	
	$MusicController.play()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		ui_manager.toggle_pause_menu()
