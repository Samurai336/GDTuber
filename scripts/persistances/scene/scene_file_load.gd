class_name SceneFileLoad

static func validate_object_json(dict: Dictionary, version: String) -> bool:
	var valid = true
	var versions = {
		"0.1":{
			"scale.x":TYPE_FLOAT,
			"scale.y":TYPE_FLOAT,
			"position.x":TYPE_FLOAT,
			"position.y":TYPE_FLOAT,
			"texturepath":TYPE_STRING,
			"blinking":TYPE_BOOL,
			"reactive":TYPE_BOOL,
			"talking":TYPE_BOOL
		},
		"0.2":{
			"filter":TYPE_BOOL
		},
		"0.4":{
			"rotation":TYPE_FLOAT
		},
		"0.5":{
			"hidden":TYPE_BOOL
		},
		"0.6":{
			"name":TYPE_STRING,
		},
		"0.7":{
			"hue":TYPE_FLOAT,
			"sat":TYPE_FLOAT,
			"val":TYPE_FLOAT,
		},
		"0.8":{
			"height":TYPE_FLOAT,
			"speed":TYPE_FLOAT
		},
		"0.9":{
			"neutralpath":TYPE_STRING,
			"blinkingpath":TYPE_STRING,
			"talkingpath":TYPE_STRING,
			"talkingandblinkingpath":TYPE_STRING,
			"usesingleimage":TYPE_BOOL
		},
		"0.11":{
			"auto_toggle_enabled":TYPE_BOOL,
			"auto_toggle_time":TYPE_FLOAT
		},
		"0.13":{
			"min_blink_delay":TYPE_FLOAT,
			"max_blink_delay":TYPE_FLOAT,
			"blink_duration":TYPE_FLOAT
		}
	}
	for v in versions:
		if version.naturalnocasecmp_to(v) >= 0:
			for field in versions[v]:
				if field not in dict:
					push_error("FIELD NOT FOUND: " + field)
					valid = false
				elif !is_instance_of(dict[field], versions[v][field]):
					push_error("FIELD TYPE INCORRECT: " + field)
					push_error("Value: ", dict[field])
					push_error("Type: ", type_string(typeof(dict[field])))
					valid = false
	return valid


static func validate_save_json(dict: Dictionary, version: String) -> bool:
	var valid = true
	var versions = {
		"0.1":{
			"objects":TYPE_ARRAY,
			"version":TYPE_STRING
		},
		"0.4":{
			"profile_name":TYPE_STRING,
		},
		"0.8":{
			"background_transparent":TYPE_BOOL,
			"background_color":TYPE_STRING
		},
		"0.10":{
			"fixedWindowHeight":TYPE_INT,
			"fixedWindowWidth": TYPE_INT,
			"fixedWindowSize":TYPE_BOOL
		},
		"0.12":{
			"fpsCap": TYPE_BOOL,
			"fpsCapValue": TYPE_INT
		}
	}
	for v: String in versions:
		if version.naturalnocasecmp_to(v) >= 0:
			for field in versions[v]:
				if field not in dict:
					push_error("FIELD NOT FOUND: " + field)
					valid = false
				elif !is_instance_of(dict[field], versions[v][field]):
					push_error("FIELD TYPE INCORRECT: " + field)
					valid = false
	return valid


static func load_scene_from_file(
	path: String,
	main_menu: Menu
	):
		
	var tree_root: Window = main_menu.get_tree().get_root()
	var objects_root = main_menu.ObjectsRoot
	var menu_root = main_menu.MenusRoot
	var titleedit: LineEdit = main_menu.titleedit
	var profilename: String =  main_menu.profilename
	var background_color: Color = main_menu.background_color
	var bgcolorPicker: ColorPickerButton = main_menu.bgcolorPicker
	var background: ColorRect = main_menu.background
	var bgcolor: Panel = main_menu.bgcolor
	var background_transparent: bool = main_menu.background_transparent
	var bgTransparentToggle: CheckBox = main_menu.bgTransparentToggle
	var fixedWindowSizeToggle: CheckBox = main_menu.fixedWindowSizeToggle
	var fixedWindowWidthSpinbox: SpinBox = main_menu.fixedWindowWidthSpinbox
	var fixedWindowHeightSpinbox: SpinBox = main_menu.fixedWindowHeightSpinbox
	var maxFpsSpinbox: SpinBox = main_menu.maxFpsSpinbox
	var fpsCapToggle: CheckBox = main_menu.fpsCapToggle

	var save_json = FileAccess.get_file_as_string(path)
	if save_json == "":
		return
	var save_dict = JSON.parse_string(save_json)
	var version : String = "0.1.0"
	if save_dict:
		if "version" in save_dict:
			if save_dict["version"] is float:
				save_dict["version"] = str(save_dict["version"])
				version = save_dict["version"]
		if validate_save_json(save_dict, version):
			version = save_dict["version"]
			# Version Check
			if version.naturalnocasecmp_to(main_menu.project_version) > 0:
				push_warning("WARNING: save data is newer than current version, attempting to load data")

			# Generate Objects from Objects Array
			for obj in objects_root.get_children():
				obj.queue_free()
			for men in menu_root.get_children():
				men.queue_free()
			for obj in save_dict["objects"]:
				if validate_object_json(obj, version):
					var new_onscreen_object = OnScreenObjectCreator.make_new_screen_object()
					var new_onscreen_object_menu_controller = OnScreenObjectMenuController.new(
						menu_root,
						objects_root,
						new_onscreen_object,
						main_menu.file_dialog,
						main_menu.gizmo,
					)
					objects_root.add_child(new_onscreen_object)
					objects_root.add_child(new_onscreen_object_menu_controller)
					new_onscreen_object.user_position = menu_root.get_viewport_rect().size/2 
					menu_root.add_child(new_onscreen_object_menu_controller.screen_object_menu_ui)
					# 0.1
					new_onscreen_object.user_scale = Vector2(obj["scale.x"], obj["scale.y"])
					new_onscreen_object.user_position = Vector2(obj["position.x"], obj["position.y"])
					new_onscreen_object.blinking = obj["blinking"]
					new_onscreen_object.reactive = obj["reactive"]
					new_onscreen_object.talking = obj["talking"]
					if obj["texturepath"] != "":
						new_onscreen_object_menu_controller.openingfor = new_onscreen_object
						new_onscreen_object_menu_controller.objectimagefield = "texture"
						new_onscreen_object_menu_controller.objectimagepathfield = "texturepath"
						new_onscreen_object_menu_controller.open_image(obj["texturepath"])
					new_onscreen_object.usesingleimage = true
					# 0.2
					if version.naturalnocasecmp_to("0.2") >= 0:
						new_onscreen_object.filter = obj["filter"]
					# 0.4
					if version.naturalnocasecmp_to("0.4") >= 0:
						new_onscreen_object.user_rotation = obj["rotation"]
					# 0.5
					if version.naturalnocasecmp_to("0.5") >= 0:
						new_onscreen_object.user_hidden = obj["hidden"]
					# 0.6
					if version.naturalnocasecmp_to("0.6") >= 0:
						new_onscreen_object.user_name = obj["name"]
					# 0.7
					if version.naturalnocasecmp_to("0.7") >= 0:
						new_onscreen_object.user_hue = obj["hue"]
						new_onscreen_object.user_sat = obj["sat"]
						new_onscreen_object.user_val = obj["val"]
					# 0.8
					if version.naturalnocasecmp_to("0.8") >= 0:
						new_onscreen_object.user_height = obj["height"]
						new_onscreen_object.user_speed = obj["speed"]
					new_onscreen_object.update_menu.emit()
					# 0.9
					if version.naturalnocasecmp_to("0.9") >= 0:
						new_onscreen_object.usesingleimage = obj["usesingleimage"]
						for imgload in [
							["neutralpath", "neutral_texture", obj["neutralpath"]],
							["blinkingpath", "blinking_texture", obj["blinkingpath"]],
							["talkingpath", "talking_texture", obj["talkingpath"]],
							["talkingandblinkingpath", "talking_and_blinking_texture", obj["talkingandblinkingpath"]]
						]:
							if imgload[2] != "":
								new_onscreen_object_menu_controller.openingfor = new_onscreen_object
								new_onscreen_object_menu_controller.objectimagefield = imgload[1]
								new_onscreen_object_menu_controller.objectimagepathfield = imgload[0]
								new_onscreen_object_menu_controller.open_image(imgload[2])
					# 0.11
					if version.naturalnocasecmp_to("0.11") >= 0:
						new_onscreen_object.auto_toggle_enabled = obj["auto_toggle_enabled"]
						new_onscreen_object.auto_toggle_time = obj["auto_toggle_time"]
					# 0.13
					if version.naturalnocasecmp_to("0.13") >= 0:
						new_onscreen_object.min_blink_delay = obj["min_blink_delay"] if obj.has("min_blink_delay") else 2 
						new_onscreen_object.max_blink_delay = obj["max_blink_delay"] if obj.has("max_blink_delay") else 4 
						new_onscreen_object.blink_duration = obj["blink_duration"] if obj.has("blink_duration") else 2 
					
					new_onscreen_object.update_menu.emit()
				else:
					push_error("ERROR: object does not contain required fields")
			# Load Program Settings
			#0.4
			if version.naturalnocasecmp_to("0.4") >= 0:
				var profile_name = save_dict["profile_name"]
				titleedit.text = profile_name
				profilename = profile_name
				tree_root.title = profile_name 
			# 0.8
			if version.naturalnocasecmp_to("0.8") >= 0:
				background_color = Color.from_string(save_dict["background_color"], background_color)
				background.color = background_color
				bgcolorPicker.color = background_color

				var transparent_toggle = save_dict["background_transparent"]
				bgcolor.visible = !transparent_toggle
				background.visible = !transparent_toggle
				background_transparent = transparent_toggle
				bgTransparentToggle.button_pressed = save_dict["background_transparent"]
			if version.naturalnocasecmp_to("0.10") >= 0:
				fixedWindowSizeToggle.button_pressed = save_dict["fixedWindowSize"]
				fixedWindowWidthSpinbox.value = save_dict["fixedWindowWidth"]
				fixedWindowHeightSpinbox.value = save_dict["fixedWindowHeight"]
			if version.naturalnocasecmp_to("0.12") >= 0:
				maxFpsSpinbox.set_value_no_signal(save_dict["fpsCapValue"] if save_dict["fpsCap"] else 60)
				fpsCapToggle.set_pressed(save_dict["fpsCap"])
		else:
			push_error("ERROR: Required Fields for Save File Version not Found")
	else:
		push_error("ERROR: JSON file is invalid")
