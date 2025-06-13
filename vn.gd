extends Node2D
var VN_SCRIPT_SOURCE = "res://VN/vnscenes/main.vnscript"

var vn_script
var script_line = 0
var script_state = "START"
var states = ["START", "[LOAD]", "[VARIABLES]", "[DEFAULT]",  "[REFRESH]"]
var player_interactive_actions = ["SAY", "OPTION"]

var last_dialog
var charecters = [null, null, null];

var PRELOADS = Dictionary()
var VARIABLES

@onready var background = $background
@onready var ambient_sound: AudioStreamPlayer = $ambient_sound

var dialog_window = preload("res://dialog.tscn")
var option_window = preload("res://options.tscn")

var backgorund_width = 0;
var background_height = 0;

var is_waiting_for_player = false
var is_option_window_open = false

func _preload():
	if  FileAccess.file_exists("res://vn_globals.cfg"):
		var file = FileAccess.open("res://vn_globals.cfg", FileAccess.READ)
		VARIABLES = JSON.parse_string(file.get_line())
		print(VARIABLES)
	else:
		VARIABLES = Dictionary()
	get_viewport().connect("size_changed", _on_viewport_resize)
	vn_script = Array(FileAccess.get_file_as_string(VN_SCRIPT_SOURCE).split("\n"))
	while script_line < vn_script.size():
		if vn_script[script_line] in states:
			script_state = vn_script[script_line]
			script_line += 1
		if script_state == "START":
			pass
		if script_state == "[REFRESH]":
			VARIABLES = Dictionary()
		if script_state == "[LOAD]":
			var splited_line = Array(vn_script[script_line].split(' '))
			PRELOADS[splited_line[0]] = splited_line[1]
		if script_state == "[VARIABLES]":
			if not VARIABLES.has(vn_script[script_line]):
				VARIABLES[vn_script[script_line]] = 0
		if script_state == "[DEFAULT]":
			var splited_line = Array(vn_script[script_line].split(' '))
			if splited_line[0] == "BACKGROUND":
				var image = Image.load_from_file(splited_line[1])
				backgorund_width = image.get_width()
				background_height = image.get_height()
				var window = get_window().size
				print(window.x, ' ', window.y,' ',  backgorund_width,' ', background_height)
				background.texture = ImageTexture.create_from_image(image)
				background.scale.x = float(window.x) / float(backgorund_width)
				background.scale.y = float(window.y) / float(background_height)
				background.position.x = float(window.x) / float(backgorund_width) * backgorund_width / 2
				background.position.y = float(window.y) / float(background_height) * background_height / 2
			elif splited_line[0] == "AMBIENTSOUND":
				ambient_sound.stream = AudioStreamMP3.load_from_file(splited_line[1])
				ambient_sound.stream.loop= 1
				ambient_sound.play()
		if vn_script[script_line] == "[MAIN]":
			script_line += 1
			break
		script_line += 1
	
func _on_viewport_resize():
	var window = get_window().size
	background.scale.x = float(window.x) / float(backgorund_width)
	background.scale.y = float(window.y) / float(background_height)
	background.position.x = float(window.x) / float(backgorund_width) * backgorund_width / 2
	background.position.y = float(window.y) / float(background_height) * background_height / 2
	update_charecters()

func _process(delta):
	while (not is_waiting_for_player and script_line < vn_script.size()):
		if handle_line() == false: break
		script_line += 1
	
	if Input.is_action_just_pressed("jump") and not is_option_window_open:
		is_waiting_for_player = false

func handle_line():
	print(vn_script[script_line])
	var splited_line = Array(vn_script[script_line].split(" "))
	if splited_line[0] == "SAY":
		var scene = dialog_window.instantiate()
		if (last_dialog):
			last_dialog.delete()
			
		last_dialog = scene;
		var image
		if PRELOADS.has(splited_line[1]):
			image = Image.load_from_file(PRELOADS[splited_line[1]])
		else:
			image = Image.new()
		scene.set_text_and_image(" ".join(splited_line.slice(2)), image)
		add_child(scene)
		is_waiting_for_player = true
	if splited_line[0] == "IF":
		if splited_line[2] == "=" and int(VARIABLES[splited_line[1]]) == int(splited_line[3]):		
			return
		elif splited_line[2] == "<" and int(VARIABLES[splited_line[1]]) < int(splited_line[3]):		
			return
		elif splited_line[2] == ">" and int(VARIABLES[splited_line[1]]) > int(splited_line[3]):		
			return
		else:
			while vn_script[script_line] != "ENDIF" and script_line < vn_script.size():
				script_line += 1
				
	if splited_line[0] == "OPTIONS":
		last_dialog.delete()
		is_waiting_for_player = true
		is_option_window_open = true
		var buttons = []
		script_line += 1
		while vn_script[script_line] != "ENDOPTIONS" and script_line < vn_script.size():
			var option = Array(vn_script[script_line].split(" "))
			print(option)
			var button = ["", "", "", ""]
			button[0] = option[0]
			button[1] = option[1]
			button[2] = option[2]
			button[3] = " ".join(option.slice(3))
			buttons.push_back(button)
			script_line += 1
		var scene = option_window.instantiate();
		add_child(scene)
		print(buttons)
		scene.buttons = buttons
		scene._create_choose_ui();
		
	if splited_line[0] == "PLAY":
		if  splited_line[1] == "SOUND":
			var audio_stream = AudioStreamPlayer.new()
			if PRELOADS[splited_line[2]].find(".mp3") != -1:
				audio_stream.stream = AudioStreamMP3.load_from_file(PRELOADS[splited_line[2]])
			elif PRELOADS[splited_line[2]].find(".wav") != -1:
				audio_stream.stream = AudioStreamWAV.load_from_file(PRELOADS[splited_line[2]])
			add_child(audio_stream)
			audio_stream.play()
			audio_stream.finished.connect(func (): audio_stream.queue_free())
	
	if splited_line[0] == "LOAD":
		_save_globals()
		get_parent().load_scene(splited_line[1])
		queue_free()
		return false
		
	if splited_line[0] == "LOADGDSCENE":
		_save_globals()
		get_parent().load_gd_scene(splited_line[1])
		return false
	
	if splited_line[0] == "POSITION":
		if splited_line[1] == "LEFT":
			if charecters[0]:
				charecters[0].queue_free()
			if splited_line[2] == "NULL":
				charecters[0] = null
			else:
				var scene = Sprite2D.new()
				scene.texture = ImageTexture.create_from_image(Image.load_from_file(PRELOADS[splited_line[2]]))
				charecters[0] = scene;
				add_child(scene);
		if splited_line[1] == "CENTER":
			if charecters[1]:
				charecters[1].queue_free()
			if splited_line[2] == "NULL":
				charecters[1] = null
			else:
				var scene = Sprite2D.new()
				scene.texture = ImageTexture.create_from_image(Image.load_from_file(PRELOADS[splited_line[2]]))
				charecters[1] = scene;
				add_child(scene);
		if splited_line[1] == "RIGHT":
			if charecters[2]:
				charecters[2].queue_free()
			if splited_line[2] == "NULL":
				charecters[2] = null
			else:
				var scene = Sprite2D.new()
				scene.texture = ImageTexture.create_from_image(Image.load_from_file(PRELOADS[splited_line[2]]))
				charecters[2] = scene;
				add_child(scene);
		update_charecters()
	if splited_line[0] == "BACKGROUND":
		var image = Image.load_from_file(PRELOADS[splited_line[1]])
		backgorund_width = image.get_width()
		background_height = image.get_height()
		var window = get_window().size
		print(window.x, ' ', window.y,' ',  backgorund_width,' ', background_height)
		background.texture = ImageTexture.create_from_image(image)
		background.scale.x = float(window.x) / float(backgorund_width)
		background.scale.y = float(window.y) / float(background_height)
		background.position.x = float(window.x) / float(backgorund_width) * backgorund_width / 2
		background.position.y = float(window.y) / float(background_height) * background_height / 2
		
func update_charecters():
	var window = get_window().size
	var charecter_width = float(window.x)/3
	
	if charecters[0]:
		var texture_width =  float(charecters[0].texture.get_width())
		var texture_height = float(charecters[0].texture.get_height())
		charecters[0].scale.x = float(charecter_width)/float(texture_width)
		charecters[0].scale.y = float(charecter_width)/float(texture_width)
		charecters[0].position.x = charecter_width/2.0
		charecters[0].position.y = window.y - charecter_width/texture_width * texture_height/2
	if charecters[1]:
		var texture_width = charecters[1].texture.get_width()
		var texture_height = charecters[1].texture.get_height()
		charecters[1].scale.x = charecter_width/texture_width
		charecters[1].scale.y = charecter_width/texture_width
		charecters[1].position.x = window.x / 2.0 
		charecters[1].position.y = window.y - charecter_width/texture_width * texture_height/2
	if charecters[2]:
		var texture_width = charecters[2].texture.get_width()
		var texture_height = charecters[2].texture.get_height()
		charecters[2].scale.x = charecter_width/texture_width
		charecters[2].scale.y = charecter_width/texture_width
		charecters[2].position.x = window.x - charecter_width/2
		charecters[2].position.y = window.y - charecter_width/texture_width * texture_height/2
	for item in charecters:
		if item:
			print(item.position)
			print(item.scale)

func _save_globals():
	var file = FileAccess.open("res://vn_globals.cfg", FileAccess.WRITE);
	file.store_line(JSON.stringify(VARIABLES))
