class_name MainMenuControl extends PanelContainer

signal pop_out_requested()

# Audio Management
@onready var device_dropdown = %DeviceDropdown.get_popup()

### Ready
func _ready():
	for device_name in AudioManager.get_audio_devices(): device_dropdown.add_item(device_name)
	device_dropdown.index_pressed.connect(_on_popup_menu_index_pressed)
	%VersionLabel.text = "Version: " + ProjectSettings.get_setting("application/config/version")


### Audio Management
func _on_popup_menu_index_pressed(index: int):
	var input_device = device_dropdown.get_item_text(index)
	AudioManager.set_input_source(input_device)

func _on_pop_out_toggle_pressed() -> void:
	pop_out_requested.emit()
