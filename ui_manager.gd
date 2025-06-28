extends Node3D

# Сигналы
signal retry_pressed

# Настройки
var auto_respawn: bool = false

# Ссылки на узлы
var Player: Node
var MusicController: Node
var SENSETIVITY: float

# Элементы UI
var pause_menu: CanvasLayer
var continue_button: Button
var settings_button: Button
var exit_button: Button
var settings_menu_container: VBoxContainer
var volume_slider: HSlider
var sensitivity_slider: HSlider
var back_button: Button
var main_menu_container: VBoxContainer

var death_screen: CanvasLayer
var death_label: Label
var retry_button: Button
var death_exit_button: Button
var auto_respawn_checkbox: CheckBox
var death_sound: AudioStreamPlayer

func init(player_node: Node, music_controller: Node, sensitivity: float):
	Player = player_node
	MusicController = music_controller
	SENSETIVITY = sensitivity
	
	create_ui_elements()
	connect_signals()
	load_settings()

func create_ui_elements():
	death_screen = CanvasLayer.new()
	death_screen.layer = 2
	death_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(death_screen)
	death_screen.hide()
	
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 1)
	background.size = Vector2(2000, 2000)
	death_screen.add_child(background)
	
	death_label = Label.new()
	death_label.text = "ПРОБЛЕМА С НАВЫКОМ"
	death_label.add_theme_color_override("font_color", Color.RED)
	death_label.add_theme_font_size_override("font_size", 72)
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	death_label.size = Vector2(1000, 200)
	death_screen.add_child(death_label)
	
	retry_button = Button.new()
	retry_button.text = "Ещё раз"
	retry_button.custom_minimum_size = Vector2(400, 100)
	death_screen.add_child(retry_button)
	
	# Кнопка выхода на экране смерти
	death_exit_button = Button.new()
	death_exit_button.text = "Выйти"
	death_exit_button.custom_minimum_size = Vector2(400, 100)
	death_screen.add_child(death_exit_button)
	
	# Создание меню паузы
	pause_menu = CanvasLayer.new()
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_menu)
	
	main_menu_container = VBoxContainer.new()
	main_menu_container.alignment = BoxContainer.ALIGNMENT_CENTER
	main_menu_container.custom_minimum_size = Vector2(400, 430) # Увеличили высоту для новой кнопки
	pause_menu.add_child(main_menu_container)
	main_menu_container.name = "MainMenu"
	
	continue_button = Button.new()
	continue_button.text = "Продолжить"
	continue_button.custom_minimum_size = Vector2(300, 100)
	main_menu_container.add_child(continue_button)
	
	settings_button = Button.new()
	settings_button.text = "Настройки"
	settings_button.custom_minimum_size = Vector2(300, 100)
	main_menu_container.add_child(settings_button)
	
	# Кнопка выхода в меню паузы
	exit_button = Button.new()
	exit_button.text = "Выйти"
	exit_button.custom_minimum_size = Vector2(300, 100)
	main_menu_container.add_child(exit_button)
	
	settings_menu_container = VBoxContainer.new()
	settings_menu_container.alignment = BoxContainer.ALIGNMENT_CENTER
	settings_menu_container.custom_minimum_size = Vector2(400, 300)
	settings_menu_container.name = "SettingsMenu"
	pause_menu.add_child(settings_menu_container)
	settings_menu_container.hide()
	
	var settings_label = Label.new()
	settings_label.text = "НАСТРОЙКИ"
	settings_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_label.add_theme_font_size_override("font_size", 32)
	settings_menu_container.add_child(settings_label)
	
	var volume_container = HBoxContainer.new()
	settings_menu_container.add_child(volume_container)
	
	var volume_label = Label.new()
	volume_label.text = "Громкость:"
	volume_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_container.add_child(volume_label)
	
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.value = 80 
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_container.add_child(volume_slider)
	
	var sensitivity_container = HBoxContainer.new()
	settings_menu_container.add_child(sensitivity_container)
	
	var sensitivity_label = Label.new()
	sensitivity_label.text = "Чувствительность мыши:"
	sensitivity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sensitivity_container.add_child(sensitivity_label)
	
	sensitivity_slider = HSlider.new()
	sensitivity_slider.min_value = 0.001
	sensitivity_slider.max_value = 0.01
	sensitivity_slider.step = 0.0005
	sensitivity_slider.value = SENSETIVITY
	sensitivity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sensitivity_container.add_child(sensitivity_slider)
	
	var respawn_container = HBoxContainer.new()
	settings_menu_container.add_child(respawn_container)
	
	var respawn_label = Label.new()
	respawn_label.text = "Автоматическое возрождение:"
	respawn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	respawn_container.add_child(respawn_label)
	
	auto_respawn_checkbox = CheckBox.new()
	auto_respawn_checkbox.button_pressed = auto_respawn
	auto_respawn_checkbox.tooltip_text = "При включении игра автоматически перезапускается после смерти"
	respawn_container.add_child(auto_respawn_checkbox)
	
	back_button = Button.new()
	back_button.text = "Назад"
	back_button.custom_minimum_size = Vector2(200, 50)
	settings_menu_container.add_child(back_button)
	
	death_sound = AudioStreamPlayer.new()
	death_sound.stream = preload("res://sounds/dead.wav")
	add_child(death_sound)
	
	apply_volume_settings()
	main_menu_container.hide()

func connect_signals():
	retry_button.connect("pressed", _on_retry_button_pressed)
	continue_button.connect("pressed", _on_continue_button_pressed)
	settings_button.connect("pressed", _on_settings_button_pressed)
	exit_button.connect("pressed", _on_exit_button_pressed)  # Новая кнопка
	death_exit_button.connect("pressed", _on_exit_button_pressed)  # Новая кнопка
	back_button.connect("pressed", _on_back_button_pressed)
	volume_slider.connect("value_changed", _on_volume_changed)
	sensitivity_slider.connect("value_changed", _on_sensitivity_changed)
	auto_respawn_checkbox.connect("toggled", _on_auto_respawn_toggled)

func show_death_screen():
	var sound = AudioStreamPlayer.new()
	sound.stream = preload("res://sounds/dead.wav")
	sound.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sound)
	sound.play()
	sound.finished.connect(func(): sound.queue_free())
	
	if auto_respawn:
		emit_signal("retry_pressed")
		return
	
	get_tree().paused = true
	MusicController.stop() 
	
	var viewport_size = get_viewport().size
	death_label.position = Vector2(
		(viewport_size.x - death_label.size.x) / 2,
		(viewport_size.y - death_label.size.y) / 2 - 100
	)
	
	retry_button.position = Vector2(
		(viewport_size.x - retry_button.size.x) / 2,
		(viewport_size.y - retry_button.size.y) / 2 + 100
	)
	
	death_exit_button.position = Vector2(
		(viewport_size.x - death_exit_button.size.x) / 2,
		(viewport_size.y - death_exit_button.size.y) / 2 + 230
	)
	
	death_screen.show()
	retry_button.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func toggle_pause_menu():
	if death_screen.visible:
		return
		
	if get_tree().paused:
		if settings_menu_container.visible:
			_on_back_button_pressed()
		else:
			_on_continue_button_pressed()
	else:
		get_tree().paused = true
		MusicController.set_process(false)
		_update_menu_position()
		main_menu_container.show()
		continue_button.grab_focus() 
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_retry_button_pressed():
	death_screen.hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("retry_pressed")

func _on_continue_button_pressed():
	get_tree().paused = false
	MusicController.set_process(true)
	main_menu_container.hide()
	settings_menu_container.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_settings_button_pressed() -> void:
	main_menu_container.hide()
	settings_menu_container.show()
	back_button.grab_focus()

func _update_menu_position():
	if not is_instance_valid(main_menu_container) or not is_instance_valid(settings_menu_container):
		return
	var viewport_size = get_viewport().size
	
	main_menu_container.position = Vector2(
		(viewport_size.x - main_menu_container.size.x) / 2,
		(viewport_size.y - main_menu_container.size.y) / 2
	)
	settings_menu_container.position = Vector2(
		(viewport_size.x - settings_menu_container.size.x) / 2,
		(viewport_size.y - settings_menu_container.size.y) / 2
	)

func _on_back_button_pressed():
	settings_menu_container.hide()
	main_menu_container.show()
	settings_button.grab_focus()

func _on_exit_button_pressed():
	get_tree().paused = false
	
	if MusicController:
		MusicController.stop()
	
	get_tree().change_scene_to_file("res://main_menu_scene.tscn")

func _on_auto_respawn_toggled(button_pressed: bool):
	auto_respawn = button_pressed
	save_settings()

func _on_volume_changed(value: float):
	apply_volume_settings()
	save_settings()

func _on_sensitivity_changed(value: float):
	SENSETIVITY = value
	if Player.has_method("set_mouse_sensitivity"):
		Player.set_mouse_sensitivity(SENSETIVITY)
		save_settings()

func apply_volume_settings():
	var volume_db = linear_to_db(volume_slider.value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)
	MusicController.update_volume(volume_slider.value / 100.0)

func save_settings():
	var config = {
		"volume": volume_slider.value,
		"sensitivity": sensitivity_slider.value,
		"auto_respawn": auto_respawn
	}
	var file = FileAccess.open("user://settings.cfg", FileAccess.WRITE)
	file.store_var(config)

func load_settings():
	if FileAccess.file_exists("user://settings.cfg"):
		var file = FileAccess.open("user://settings.cfg", FileAccess.READ)
		var config = file.get_var()
		volume_slider.value = config.get("volume", 80)
		sensitivity_slider.value = config.get("sensitivity", 0.003)
		auto_respawn = config.get("auto_respawn", false)
		
		if auto_respawn_checkbox:
			auto_respawn_checkbox.button_pressed = auto_respawn
		
		apply_volume_settings()
		_on_sensitivity_changed(sensitivity_slider.value)
