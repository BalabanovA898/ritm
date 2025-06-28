extends Node3D

# Настройки меню
var menu_width = 400
var menu_height = 500
var button_height = 60

# Настройки игры
var game_settings = {
	"volume": 80.0,
	"sensitivity": 0.003,
	"auto_respawn": false
}

# Элементы UI
var canvas_layer: CanvasLayer
var menu_container: Control
var settings_container: Control
var levels_container: Control
var volume_slider: HSlider
var sensitivity_slider: HSlider
var auto_respawn_checkbox: CheckBox

var level_directories = []
var selected_level_index: int = -1

func _ready():
	load_settings()
	
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	var menu_size = Vector2(menu_width, menu_height)
	var viewport_size = Vector2(get_viewport().size)
	
	menu_container = Control.new()
	menu_container.size = menu_size
	menu_container.position = (viewport_size - menu_size) / 2
	canvas_layer.add_child(menu_container)
	
	var background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.2, 0.9)
	background.size = menu_size
	menu_container.add_child(background)
	
	var vbox = VBoxContainer.new()
	vbox.size = menu_size - Vector2(40, 40)
	vbox.position = Vector2(20, 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_container.add_child(vbox)
	
	var button_size = Vector2(300, 60)
	create_button(vbox, button_size, "Сюжет", _on_campaign_button_pressed)
	create_button(vbox, button_size, "Уровни", _on_levels_button_pressed)
	create_button(vbox, button_size, "Настройки", _on_settings_button_pressed)
	create_button(vbox, button_size, "Редактор уровней", _on_level_editor_button_pressed)
	create_button(vbox, button_size, "Выход", _on_exit_button_pressed)
	
	if vbox.get_child_count() > 0:
		vbox.get_child(0).grab_focus()

func create_button(container: VBoxContainer, size: Vector2, text: String, callback: Callable):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = size
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.LIGHT_BLUE)
	button.pressed.connect(callback)
	container.add_child(button)

func _on_settings_button_pressed():
	hide_all_panels()
	
	if settings_container == null:
		create_settings_ui()
	settings_container.visible = true

func _on_levels_button_pressed():
	hide_all_panels()
	
	if levels_container == null:
		create_levels_ui()
	levels_container.visible = true

func hide_all_panels():
	if settings_container:
		settings_container.visible = false
	if levels_container:
		levels_container.visible = false

func create_settings_ui():
	settings_container = Control.new()
	settings_container.size = Vector2(400, 300)
	settings_container.position = Vector2(50, 150)
	settings_container.visible = false
	
	canvas_layer.add_child(settings_container)
	
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.2, 0.95)
	bg.size = settings_container.size
	settings_container.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.size = settings_container.size - Vector2(20, 20)
	vbox.position = Vector2(10, 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	settings_container.add_child(vbox)
	
	var title = Label.new()
	title.text = "НАСТРОЙКИ"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	vbox.add_child(Control.new())
	
	var volume_container = HBoxContainer.new()
	volume_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(volume_container)
	
	var volume_label = Label.new()
	volume_label.text = "Громкость:"
	volume_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_container.add_child(volume_label)
	
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.value = game_settings["volume"]
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_container.add_child(volume_slider)
	
	var sensitivity_container = HBoxContainer.new()
	sensitivity_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(sensitivity_container)
	
	var sensitivity_label = Label.new()
	sensitivity_label.text = "Чувствительность:"
	sensitivity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sensitivity_container.add_child(sensitivity_label)
	
	sensitivity_slider = HSlider.new()
	sensitivity_slider.min_value = 0.001
	sensitivity_slider.max_value = 0.01
	sensitivity_slider.step = 0.0005
	sensitivity_slider.value = game_settings["sensitivity"]
	sensitivity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sensitivity_container.add_child(sensitivity_slider)
	
	var respawn_container = HBoxContainer.new()
	respawn_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(respawn_container)
	
	var respawn_label = Label.new()
	respawn_label.text = "Авто-респавн:"
	respawn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	respawn_container.add_child(respawn_label)
	
	auto_respawn_checkbox = CheckBox.new()
	auto_respawn_checkbox.button_pressed = game_settings["auto_respawn"]
	respawn_container.add_child(auto_respawn_checkbox)
	
	var close_button = Button.new()
	close_button.text = "Закрыть"
	close_button.custom_minimum_size = Vector2(150, 40)
	close_button.pressed.connect(func(): settings_container.visible = false)
	vbox.add_child(close_button)
	
	volume_slider.value_changed.connect(_on_volume_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	auto_respawn_checkbox.toggled.connect(_on_auto_respawn_toggled)

func create_levels_ui():
	levels_container = Control.new()
	levels_container.size = Vector2(450, 350)  # Больше по ширине
	levels_container.position = Vector2(50, 100)
	levels_container.visible = false
	
	canvas_layer.add_child(levels_container)
	
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.2, 0.95)
	bg.size = levels_container.size
	levels_container.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.size = levels_container.size - Vector2(20, 20)
	vbox.position = Vector2(10, 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	levels_container.add_child(vbox)
	
	var title = Label.new()
	title.text = "ВЫБОР УРОВНЯ"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var level_control = HBoxContainer.new()
	level_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_control.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(level_control)
	
	var play_button = Button.new()
	play_button.text = "Играть"
	play_button.custom_minimum_size = Vector2(150, 50)
	play_button.add_theme_font_size_override("font_size", 24)
	play_button.pressed.connect(_on_play_level_pressed)
	level_control.add_child(play_button)
	
	vbox.add_child(HSeparator.new())
	
	var levels_scroll = ScrollContainer.new()
	levels_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	levels_scroll.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(levels_scroll)
	
	var levels_list = VBoxContainer.new()
	levels_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	levels_scroll.add_child(levels_list)
	
	load_real_levels(levels_list)
	
	var close_button = Button.new()
	close_button.text = "Закрыть"
	close_button.custom_minimum_size = Vector2(150, 40)
	close_button.pressed.connect(func(): levels_container.visible = false)
	vbox.add_child(close_button)

func load_real_levels(container: VBoxContainer):
	for child in container.get_children():
		child.queue_free()
	
	var dir = DirAccess.open("user://levels")
	if not dir: 
		DirAccess.make_dir_absolute("user://levels")
		dir = DirAccess.open("user://levels")
	
	level_directories = dir.get_directories()
	if level_directories.is_empty():
		print("Уровни не найдены")
		create_empty_levels_message(container)
		return
	
	for i in range(level_directories.size()):
		var level_dir = level_directories[i]
		var button = Button.new()
		button.text = level_dir.replace("_", " ").capitalize()
		button.custom_minimum_size = Vector2(300, 40)
		button.add_theme_font_size_override("font_size", 20)
		button.connect("pressed", Callable(self, "_on_level_selected").bind(i))
		container.add_child(button)
		
		var separator = HSeparator.new()
		separator.custom_minimum_size.y = 5
		container.add_child(separator)

func create_empty_levels_message(container: VBoxContainer):
	var message = Label.new()
	message.text = "Уровни не найдены!\nПоместите .osu файлы в папку user://levels"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 22)
	container.add_child(message)

func _on_level_selected(index: int):
	selected_level_index = index
	print("Выбран уровень с индексом: ", index)

func _on_play_level_pressed():
	if selected_level_index >= 0:
		print("Запуск уровня с индексом: ", selected_level_index)
		Global.selected_level_index = selected_level_index
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		print("Уровень не выбран")

func _on_volume_changed(value: float):
	game_settings["volume"] = value
	apply_volume(value)
	save_settings()

func _on_sensitivity_changed(value: float):
	game_settings["sensitivity"] = value
	save_settings()

func _on_auto_respawn_toggled(toggled: bool):
	game_settings["auto_respawn"] = toggled
	save_settings()

func apply_volume(value: float):
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

func load_settings():
	if FileAccess.file_exists("user://settings.cfg"):
		var file = FileAccess.open("user://settings.cfg", FileAccess.READ)
		var config = file.get_var()
		if config:
			game_settings = config
			apply_volume(game_settings["volume"])
	else:
		save_settings()

func save_settings():
	var file = FileAccess.open("user://settings.cfg", FileAccess.WRITE)
	file.store_var(game_settings)

func _on_campaign_button_pressed():
	print("Запуск кампании...")

func _on_level_editor_button_pressed():
	print("Запуск редактора уровней...")

func _on_exit_button_pressed():
	save_settings()
	get_tree().quit()
