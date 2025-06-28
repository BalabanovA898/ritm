extends Control

# Сигналы для взаимодействия с другими частями игры
signal campaign_selected
signal levels_selected
signal settings_opened
signal level_editor_opened
signal game_exited

func _ready():
	# Создаем контейнер для кнопок
	var container = VBoxContainer.new()
	container.size = Vector2(400, 500)
	container.position = Vector2(100, 100)
	container.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(container)
	container.name = "VBoxContainer"
	
	# Создаем кнопки
	create_button(container, "CampaignButton", "Кампания", _on_campaign_button_pressed)
	create_button(container, "LevelsButton", "Уровни", _on_levels_button_pressed)
	create_button(container, "SettingsButton", "Настройки", _on_settings_button_pressed)
	create_button(container, "LevelEditorButton", "Редактор уровней", _on_level_editor_button_pressed)
	create_button(container, "ExitButton", "Выход", _on_exit_button_pressed)
	
	# Устанавливаем фокус на первую кнопку
	await get_tree().process_frame  # Ждем создания кнопок
	$VBoxContainer/CampaignButton.grab_focus()
	
	# Добавляем фон для лучшей видимости
	add_background()

# Создает кнопку с настройками
func create_button(container: VBoxContainer, name: String, text: String, callback: Callable):
	var button = Button.new()
	button.name = name
	button.text = text
	button.custom_minimum_size = Vector2(300, 60)
	button.add_theme_font_size_override("font_size", 24)
	button.focus_mode = Control.FOCUS_ALL
	
	# Стилизация кнопки
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.LIGHT_BLUE)
	button.add_theme_color_override("font_pressed_color", Color.DARK_BLUE)
	
	# Подключаем сигналы
	button.pressed.connect(callback)
	button.mouse_entered.connect(_on_button_hover.bind(button))
	button.mouse_exited.connect(_on_button_unhover.bind(button))
	
	container.add_child(button)

# Добавляет фоновое изображение или цвет
func add_background():
	var bg: Control
	
	# Пытаемся загрузить текстуру фона
	var texture_path = "res://background.png"
	if FileAccess.file_exists(texture_path):
		var texture = load(texture_path)
		var tex_rect = TextureRect.new()
		tex_rect.texture = texture
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		bg = tex_rect
	else:
		# Если текстуры нет, создаем цветной фон
		var color_rect = ColorRect.new()
		color_rect.color = Color(0.1, 0.1, 0.2, 0.9)  # Темно-синий с прозрачностью
		bg = color_rect
	
	bg.size = size
	bg.z_index = -1
	add_child(bg)

# Обработчики для визуальной обратной связи
func _on_button_hover(button: Button):
	button.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	# Можно добавить звук наведения

func _on_button_unhover(button: Button):
	button.add_theme_color_override("font_color", Color.WHITE)

# Основные обработчики кнопок
func _on_campaign_button_pressed():
	print("Запуск кампании...")
	emit_signal("campaign_selected")
	# Здесь будет переход к кампании

func _on_levels_button_pressed():
	print("Открытие выбора уровней...")
	emit_signal("levels_selected")
	# Здесь будет переход к выбору уровней

func _on_settings_button_pressed():
	print("Открытие настроек...")
	emit_signal("settings_opened")
	# Здесь будет открытие меню настроек

func _on_level_editor_button_pressed():
	print("Запуск редактора уровней...")
	emit_signal("level_editor_opened")
	# Здесь будет переход в редактор уровней

func _on_exit_button_pressed():
	print("Выход из игры...")
	emit_signal("game_exited")
	get_tree().quit()

# Дополнительные функции для управления меню
func show_menu():
	visible = true
	# Возвращаем фокус на первую кнопку при показе
	$VBoxContainer/CampaignButton.grab_focus()

func hide_menu():
	visible = false
