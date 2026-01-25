class_name MainMenuControl extends PanelContainer

signal pop_out_requested()
signal hide_menu_requested()
signal program_quit_requested()

var localization = Localization.new()

# Audio Management
@onready var device_dropdown = %DeviceDropdown.get_popup()

### Ready
func _ready():
	# Get Audio Devices for Menu
	for device_name in AudioManager.get_audio_devices(): device_dropdown.add_item(device_name)
	device_dropdown.index_pressed.connect(_on_popup_menu_index_pressed)

	AudioManager.audio_changed.connect(_update_audio_ui)

	# Version Number for display 
	%VersionLabel.text = "Version: " + ProjectSettings.get_setting("application/config/version")

	# Initialize Localization
	localization.language_dropdown = %LanguageDropdown
	localization.setup()


func _process(_delta):
	var magnitude_avg = AudioManager.mag_throbber_value
	%VolumeVisual.value = magnitude_avg

func _set_profile_name(pname: String):
	%TitleEdit.text = pname
	# In main it sets `get_tree().get_root().title = pname` idk if will need an event? 

func _open_settings():
	%SettingsMenu.visible = true
	%MainMenu.visible = false

func _close_settings():
	%SettingsMenu.visible = false
	%MainMenu.visible = true

### Audio Management
func _on_popup_menu_index_pressed(index: int):
	var input_device = device_dropdown.get_item_text(index)
	AudioManager.set_input_source(input_device)

func _on_v_slider_drag_ended(value_changed):
	AudioManager.set_threshold(value_changed)

func _on_input_gain_change(_new_input_gain: float):
	AudioManager.set_input_gain(_new_input_gain)

func _update_audio_ui(input_device: String, threshold: float, input_gain: float)-> void:
	%ThresholdSlider.value = threshold
	%InputGainSlider.value = input_gain
	%DeviceDropdown.text = input_device


func _on_pop_out_toggle_pressed() -> void:
	pop_out_requested.emit()

func _hide_menu_pressed() -> void:
	hide_menu_requested.emit()

func _on_quit_button_button_down() -> void:
	program_quit_requested.emit()
