extends Control

# Элементы UI
@onready var volume_slider = $VBoxContainer/VolumeContainer/VolumeSlider
@onready var sensitivity_slider = $VBoxContainer/SensitivityContainer/SensitivitySlider
@onready var auto_respawn_checkbox = $VBoxContainer/AutoRespawnContainer/AutoRespawnCheckBox

# Ссылка на главное меню
var main_menu

func _ready():
	# Получаем ссылку на главное меню
	main_menu = get_parent().get_parent().get_parent().get_parent()

func init_settings(volume: float, sensitivity: float, auto_respawn: bool):
	# Устанавливаем значения из главного меню
	volume_slider.value = volume
	sensitivity_slider.value = sensitivity
	auto_respawn_checkbox.button_pressed = auto_respawn
	
	# Применяем начальные настройки звука
	apply_volume(volume)
	
	# Подключаем сигналы
	volume_slider.connect("value_changed", Callable(self, "_on_volume_changed"))
	sensitivity_slider.connect("value_changed", Callable(self, "_on_sensitivity_changed"))
	auto_respawn_checkbox.connect("toggled", Callable(self, "_on_auto_respawn_toggled"))

func _on_volume_changed(value):
	apply_volume(value)
	save_current_settings()

func apply_volume(value):
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

func _on_sensitivity_changed(value):
	save_current_settings()

func _on_auto_respawn_toggled(toggled):
	save_current_settings()

func save_current_settings():
	# Формируем словарь текущих настроек
	var current_settings = {
		"volume": volume_slider.value,
		"sensitivity": sensitivity_slider.value,
		"auto_respawn": auto_respawn_checkbox.button_pressed
	}
	
	# Обновляем настройки в главном меню
	main_menu.update_settings(current_settings)
