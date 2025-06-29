extends Node3D

const DEBUG_DIFFICULTY = "hard"
var DEBUG_SPEED = 5.0;
const JUMP_TIME = 0.4;
const MIN_PLATFORM_LENGTH = 0.6; #TODO: FIX TS
const DEBUG_NOOB_COEFICIENT = 1;
var level_index: int = Global.selected_level_index

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

var player_hp = 100;
var is_ready_to_respawn = false;

var combo = 0
var max_combo = 0
var score = 0;
var score_mult = 1;
var stat = [0, 0, 0, 0, 0]; #X, 50, 100, 200, 300
var acc_sum = 0;
var acc_cnt = 0;

@onready var Player = get_node("PlayerController").get_child(0)
@onready var sky: WorldEnvironment = get_node("Sky")
@onready var light = get_node("Light")
@onready var borders = [get_node("Border"), get_node("Border2"), get_node("Border3"), get_node("Border4")]
@onready var timer: Sprite2D = get_node("UI/Timer")
@onready var ui_manager = $UIManager

var time_mult = 1

var A;
var B;
var D;
var S;
var SS;
var SSS;

var container: MarginContainer;
var score_lb: Label;
var combo_lb: Label;
var acc_lb: Label;
var rank_sprite: Sprite2D; 

func _ready():
	if (!Global.FTM_MODE):
		platform = preload("res://platform.tscn");
	else:
		platform = preload("res://platfrom_ftm.tscn")
	# Инициализация UI Manager

	print("Загрузка уровня с индексом: ", level_index)
	timer.global_position.y = 0
	
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

	ui_manager.init(Player, $MusicController, SENSETIVITY)
	ui_manager.connect("retry_pressed", reset_game)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if (Global.DT_MODE):
		time_mult = 1.25
		DEBUG_SPEED = 5 * 1.25
	elif Global.HT_MODE:
		time_mult = 0.75
		DEBUG_SPEED = 5 * 0.75
	else:
		time_mult = 1
	
	Player.SPEED *= time_mult
	$MusicController.pitch_scale = time_mult
	load_level(level_index)
	$MusicController.load_music(current_directory + "/" + path_to_music.erase(path_to_music.length() -1) if path_to_music[-1] != "3" else path_to_music);
	
	score_mult *= 2 if Global.DRUNK_MODE else 1 *\
	4 if Global.FTM_MODE else 1 *\
	2 if Global.DT_MODE else 1 *\
	0.5 if Global.HT_MODE else 1;
	
	A = Image.load_from_file("res://textures/A.png")
	B = Image.load_from_file("res://textures/B.png")
	D = Image.load_from_file("res://textures/D.png")
	S = Image.load_from_file("res://textures/S.png")
	SS = Image.load_from_file("res://textures/SS.png")
	SSS = Image.load_from_file("res://textures/SSS.png")

	_init_ui();
	
	$UI/FinalScore/VBoxContainer/Controls/Back.connect("pressed", func (): get_tree().change_scene_to_file("res://main_menu_scene.tscn"))
	$UI/FinalScore/VBoxContainer/Controls/Restart.connect("pressed", func(): get_tree().reload_current_scene())
func _process(delta: float) -> void:
	timer.scale.x = (1.0 - time / beatmap[-1]) * get_viewport().size.x
	if player_hp <= 0:
		ui_manager.show_death_screen()
		
	player_hp = min(player_hp + 2 * delta, 100);
	
	if (Player.global_transform.origin.y <= -1) and not (is_ready_to_respawn):
		player_hp -= 20;
		if Global.NF_MODE: player_hp -= 100;
		combo = 0;
		is_ready_to_respawn = true;
		stat[0] += 1;
		acc_cnt += 1;
		_update_stats_ui();
		
	if (Player.global_transform.origin.y <= -1) and (beatmap_index == beatmap.size() - 1):
		_show_stats();
		
	if beatmap_index < beatmap.size() - 1:
		time += delta * 1000
		if time > beatmap[beatmap_index]:
			beatmap_index += 1
			if is_ready_to_respawn:
				Player.global_transform.origin.y = 1.5;
				if (Global.FIVE_TILE_MODE or Global.SEVEN_TILE_MODE):
					Player.global_transform.origin.z = last_platform_position / 2;
				else:
					Player.global_transform.origin.z = last_platform_position / 2;
				is_ready_to_respawn = false;
			create_platform(beatmap_index)
			
			var r = randi_range(0, 1) * 255
			var g = randi_range(0, 1) * 255
			var b =  randi_range(0, 1) * 255
			
			if r == 255 and g == 255 and b == 255:
				light.light_color = Color(250, 160, 150)
			else:
				sky.environment.sky.sky_material.set("shader_parameter/sun_color", Vector3(r + 1, g  + 1, b + 1));
				light.light_color = Color(255 - r, 255 - g, 255 - b);
	if Global.DRUNK_MODE:
		Player.get_child(2).get_child(0).rotation.z += 3600.0 / float(beatmap[-2]) * delta 
		print(Player.get_child(2).get_child(0).rotation.y)

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
		level = FileAccess.open(current_directory + "/" + levels.filter(func(x): return x.to_lower().find(DEBUG_DIFFICULTY) != -1)[0], FileAccess.READ).get_as_text();
	else :
		level = FileAccess.open(current_directory + "/" + levels[0], FileAccess.READ).get_as_text();
	beatmap = Array(level.get_slice("[HitObjects]", 1).split("\n")).map(func(x): return int( x.get_slice(",", 2)));
	beatmap = beatmap.map(func(x): return  (x if x else 0) / time_mult);
	var i = 1
	print(beatmap)
	while (i < beatmap.size()):
		if float(beatmap[i] - beatmap[i - 1])/1000.0 * DEBUG_SPEED < MIN_PLATFORM_LENGTH + (DEBUG_SPEED * JUMP_TIME) * (1 / DEBUG_NOOB_COEFICIENT):
			beatmap.remove_at(i)
			i -= 1
		i += 1;
	
	path_to_music = level.get_slice("AudioFilename:", 1).get_slice("\n", 0).trim_prefix(" ").trim_suffix("\n")
	print("Загружен уровень: ", list_of_levels[index], " | Музыка: ", path_to_music)

func create_platform(index: int) -> void:
	var scene = platform.instantiate()
	scene.add_to_group("platform")
	var time_between_platforms = (beatmap[beatmap_index] - beatmap[beatmap_index - 1])
	var duration_as_distance = time_between_platforms / 1000.0 * DEBUG_SPEED 
	add_child(scene)
	scene.scale.x = duration_as_distance - DEBUG_SPEED * JUMP_TIME * DEBUG_NOOB_COEFICIENT;
	var c = duration_as_distance/2 + DEBUG_SPEED * JUMP_TIME * DEBUG_NOOB_COEFICIENT;
	var a = 1 if abs(last_platform_position - next_platform_position) == 2 else 0;
	var distance_to_next_platform = sqrt(max((c ** 2 - a ** 2) * DEBUG_NOOB_COEFICIENT, 0));
	last_platform_position = next_platform_position;
	if (Global.FIVE_TILE_MODE or Global.SEVEN_TILE_MODE):
		scene.position = Vector3(Player.position.x + distance_to_next_platform , 0, float(next_platform_position)/2);
	else:
		scene.position = Vector3(Player.position.x + distance_to_next_platform , 0, next_platform_position);
	scene.id = beatmap_index;
	if (Global.FIVE_TILE_MODE):
		next_platform_position = randi_range(-2, 2);
	elif (Global.SEVEN_TILE_MODE):
		var rand_value = randi_range(-3, 3);
		while (abs(rand_value - next_platform_position) > 2):
			rand_value = randi_range(-3, 3);
		next_platform_position = rand_value;
	else:
		next_platform_position = randi_range(-1, 1);
	highlight_next_position(next_platform_position);
	
func highlight_next_position(next_position: int):
	if (Global.FIVE_TILE_MODE):
		next_position += 2;
	if Global.SEVEN_TILE_MODE:
		next_position += 3
	else: 
		next_position += 1;

	for x in borders:
		var a: MeshInstance3D = x.get_child(0)
		var material = a.get_surface_override_material(0)
		if material:
			material.shading_mode = 0
			material.transparency = 1
			material.albedo_color = Color(255, 255, 255, 0.4)
			a.set_surface_override_material(0, material)
			a.material_overlay = material
	if(!Global.FIVE_TILE_MODE and !Global.SEVEN_TILE_MODE):
		for x in range(next_position, next_position + 2):
			var a: MeshInstance3D =  borders[x].get_child(0)
			var material = a.get_surface_override_material(0);
			material.shading_mode = 0;
			material.transparency = 1;
			material.albedo_color = Color(255, 0, 0, 0.4);
			a.set_surface_override_material(0, material);
			a.material_overlay = material;
	else:
		if(next_position%2 != 0):
			for x in range(next_position-1, next_position+2):
				var a: MeshInstance3D =  borders[x/2].get_child(0)
				var material = a.get_surface_override_material(0);
				material.shading_mode = 0;
				material.transparency = 1;
				material.albedo_color = Color(255, 0, 0, 0.4);
				a.set_surface_override_material(0, material);
				a.material_overlay = material;
		else:
			var a: MeshInstance3D =  borders[next_position/2].get_child(0)
			var material = a.get_surface_override_material(0);
			material.shading_mode = 0;
			material.transparency = 1;
			material.albedo_color = Color(255, 0, 0, 0.4);
			a.set_surface_override_material(0, material);
			a.material_overlay = material;
			
func difficulty_to_rotation_speed(difficulty: String):
	if difficulty == "easy": return 0.4
	if difficulty == "normal": return 0.6
	if difficulty == "hard": return 0.8
	if difficulty == "insane": return 1
	return 0.5

func reset_game():
	get_tree().reload_current_scene();

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		ui_manager.toggle_pause_menu()

func add_score():
	var acc = max(1 - abs(beatmap[beatmap_index - 1] - time)/1000, 0) * 100 
	if (acc > 95): stat[4] += 1;
	elif (acc > 90): stat[3] += 1;
	elif (acc > 70): stat[2] += 1;
	elif (acc > 20): stat[1] += 1;
	else: stat[0] += 1;
	
	if (acc >= 20):
		combo += 1;
		max_combo = max(max_combo, combo);
		acc_cnt += 1;
	
	score += 1000 * score_mult * acc;
	acc_sum += acc;
	_update_stats_ui()
	
func _show_stats():
	$UI/FinalScore.visible = true;
	$UI/FinalScore/VBoxContainer/AccuracyContainer/AccuracyValueLB.text = str(int(acc_sum / acc_cnt));

	if (int(acc_sum / acc_cnt if acc_cnt else 0) == 100):
		$UI/FinalScore/VBoxContainer/Rank.texture = ImageTexture.create_from_image(SSS);
	elif (int(acc_sum / acc_cnt if acc_cnt else 0) > 95):
		$UI/FinalScore/VBoxContainer/Rank.texture = ImageTexture.create_from_image(SS);
	elif (int(acc_sum / acc_cnt if acc_cnt else 0) > 90):
		$UI/FinalScore/VBoxContainer/Rank.texture = ImageTexture.create_from_image(S);
	elif (int(acc_sum / acc_cnt if acc_cnt else 0) > 70):
		$UI/FinalScore/VBoxContainer/Rank.texture = ImageTexture.create_from_image(A);
	elif (int(acc_sum / acc_cnt if acc_cnt else 0) > 50):
		$UI/FinalScore/VBoxContainer/Rank.texture = ImageTexture.create_from_image(B);
	else:
		$UI/FinalScore/VBoxContainer/Rank.texture = ImageTexture.create_from_image(D);

	$UI/FinalScore/VBoxContainer/ScoreContainer/ScoreValueLB.text = str(score)
	$UI/FinalScore/VBoxContainer/MaxComboConatiner/MaxComboValueLB.text = str(max_combo)
	$UI/FinalScore/VBoxContainer/HBoxContainer4/MissContainer/MissValueLB.text = str(stat[0])
	get_node("UI/FinalScore/VBoxContainer/HBoxContainer4/50Container/a50ValueLB").text = str(stat[1])
	get_node("UI/FinalScore/VBoxContainer/HBoxContainer4/100Container/a100ValueLB").text = str(stat[2])
	get_node("UI/FinalScore/VBoxContainer/HBoxContainer4/200Container/a200ValueLB").text = str(stat[3])
	get_node("UI/FinalScore/VBoxContainer/HBoxContainer4/300Container/a300ValueLB").text = str(stat[4])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;

func _init_ui():
	var window = get_window().size;
	container = MarginContainer.new();
	container.global_position.x = window.x - 300;
	container.global_position.y = window.y / 2 - 150;
	container.size.x = 300;
	container.size.y = 300;
	get_tree().root.get_child(1).add_child(container)
	
	var vbox = VBoxContainer.new();
	container.add_child(vbox);
	
	var score_hbox = HBoxContainer.new();
	vbox.add_child(score_hbox)
	
	var score_lable = Label.new();
	score_lable.text = "Score: " 
	score_lable.add_theme_font_size_override("font_size", 28)
	score_hbox.add_child(score_lable)
	
	score_lb = Label.new();
	score_lb.text = "0";
	score_lb.add_theme_font_size_override("font_size", 28)
	score_hbox.add_child(score_lb)

	var combo_hbox = HBoxContainer.new();
	vbox.add_child(combo_hbox)
	
	var combo_lable = Label.new();
	combo_lable.text = "Combo: " 
	combo_lable.add_theme_font_size_override("font_size", 28)
	combo_hbox.add_child(combo_lable)
	
	combo_lb = Label.new();
	combo_lb.text = "0";
	combo_lb.add_theme_font_size_override("font_size", 28)
	combo_hbox.add_child(combo_lb)
	
	var acc_hbox = HBoxContainer.new();
	vbox.add_child(acc_hbox)
	
	var acc_lable = Label.new();
	acc_lable.text = "Accuracy: "
	acc_lable.add_theme_font_size_override("font_size", 28) 
	acc_hbox.add_child(acc_lable)
	
	acc_lb = Label.new();
	acc_lb.text = "0";
	acc_lb.add_theme_font_size_override("font_size", 28)
	acc_hbox.add_child(acc_lb)
	
	rank_sprite = Sprite2D.new()
	vbox.add_child(rank_sprite);
	

func _resize_ui ():
	var window = get_window().size;
	container.position.x = window.x - 300;
	container.position.y = window.y / 2 - 150;
	
func _update_stats_ui():
	score_lb.text = str(int(score))
	acc_lb.text = str(int(acc_sum / acc_cnt if acc_cnt else 0))
	combo_lb.text = str(combo);
	var rank_image;
	if (int(acc_sum / acc_cnt if acc_cnt else 0) == 100):
		rank_image = ImageTexture.create_from_image(SSS);
	elif (int(acc_sum / acc_cnt if acc_cnt else 0) > 95):
		rank_image = ImageTexture.create_from_image(SS);
	elif (int(acc_sum / acc_cnt if acc_cnt else 0) > 90):
		rank_image = ImageTexture.create_from_image(S);
	elif (int(acc_sum / acc_cnt if acc_cnt else 0) > 70):
		rank_image = ImageTexture.create_from_image(A);
	elif (int(acc_sum / acc_cnt if acc_cnt else 0) > 50):
		rank_image = ImageTexture.create_from_image(B);
	else:
		rank_image = ImageTexture.create_from_image(D);
	rank_sprite.texture = rank_image;
	rank_sprite.scale.x = 3;
	rank_sprite.scale.y = 3;
