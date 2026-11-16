extends Control

@onready var vbox: VBoxContainer = $Panel/ScrollContainer/VBox
@onready var btn_close: Button = $Panel/BtnClose

func _ready() -> void:
	btn_close.pressed.connect(func(): queue_free())
	_build_settings_ui()

func _build_settings_ui() -> void:
	_add_section("GRAPHICS")
	_add_slider("Resolution Scale", "ui_scale", 0.5, 2.0, 0.1)
	_add_checkbox("Fullscreen", "fullscreen")
	_add_checkbox("VSync", "vsync")
	_add_slider("FPS Limit", "fps_limit", 30, 144, 1)
	_add_option("Texture Quality", "texture_quality", ["Low", "Medium", "High"])
	_add_option("Shadow Quality", "shadow_quality", ["Low", "Medium", "High"])
	_add_slider("View Distance", "view_distance", 64, 512, 16)
	_add_option("Anti-Aliasing", "anti_aliasing", ["None", "MSAA 2x", "MSAA 4x"])
	_add_checkbox("Ambient Occlusion", "ambient_occlusion")

	_add_section("AUDIO")
	_add_slider("Master Volume", "master_volume", 0.0, 1.0, 0.05)
	_add_slider("Music Volume", "music_volume", 0.0, 1.0, 0.05)
	_add_slider("SFX Volume", "sfx_volume", 0.0, 1.0, 0.05)
	_add_slider("Ambient Volume", "ambient_volume", 0.0, 1.0, 0.05)
	_add_slider("UI Volume", "ui_volume", 0.0, 1.0, 0.05)

	_add_section("GAMEPLAY")
	_add_slider("Mouse Sensitivity", "mouse_sensitivity", 0.05, 1.0, 0.05)
	_add_slider("Camera FOV", "camera_fov", 50.0, 110.0, 5.0)
	_add_checkbox("Camera Bob", "camera_bob")
	_add_slider("Autosave Interval (seconds)", "autosave_interval", 60, 600, 60)
	_add_checkbox("Show FPS", "show_fps")

	_add_btn_save()

func _add_section(title: String) -> void:
	var lbl = Label.new()
	lbl.text = title
	lbl.theme_override_font_sizes = {"font_size": 20}
	lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.5))
	vbox.add_child(lbl)

func _add_slider(label: String, key: String, min_val: float, max_val: float, step: float) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(300, 0)
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.value = SettingsManager.get_setting(key)
	slider.custom_minimum_size = Vector2(300, 0)
	var val_lbl = Label.new()
	val_lbl.text = str(slider.value)
	val_lbl.custom_minimum_size = Vector2(60, 0)
	slider.value_changed.connect(func(v):
		val_lbl.text = "%.2f" % v
		SettingsManager.set_setting(key, v)
	)
	hbox.add_child(lbl)
	hbox.add_child(slider)
	hbox.add_child(val_lbl)
	vbox.add_child(hbox)

func _add_checkbox(label: String, key: String) -> void:
	var cb = CheckBox.new()
	cb.text = label
	cb.button_pressed = SettingsManager.get_setting(key)
	cb.toggled.connect(func(v): SettingsManager.set_setting(key, v))
	vbox.add_child(cb)

func _add_option(label: String, key: String, options: Array) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(300, 0)
	var opt = OptionButton.new()
	for o in options:
		opt.add_item(o)
	opt.selected = SettingsManager.get_setting(key)
	opt.item_selected.connect(func(idx): SettingsManager.set_setting(key, idx))
	hbox.add_child(lbl)
	hbox.add_child(opt)
	vbox.add_child(hbox)

func _add_btn_save() -> void:
	var btn = Button.new()
	btn.text = "Save Settings"
	btn.pressed.connect(func():
		SettingsManager.save_settings()
		EventBus.notification_requested.emit("Settings saved.", "info", 2.0)
	)
	vbox.add_child(btn)
