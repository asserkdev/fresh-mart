extends Node
## SettingsManager — loads, saves, and exposes all player settings.

const SETTINGS_PATH: String = "user://settings.cfg"

var settings: Dictionary = {}

const DEFAULTS: Dictionary = {
	# Display
	"resolution_width": 1280,
	"resolution_height": 720,
	"fullscreen": false,
	"vsync": true,
	"fps_limit": 60,
	# Graphics
	"texture_quality": 1,       # 0=low 1=med 2=high
	"shadow_quality": 1,
	"view_distance": 128.0,
	"lod_distance": 64.0,
	"npc_density": 1,           # 0=low 1=med 2=high
	"effects_quality": 1,
	"anti_aliasing": 1,         # 0=none 1=MSAA2x 2=MSAA4x
	"ambient_occlusion": false,
	# Audio
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 1.0,
	"ambient_volume": 0.8,
	"ui_volume": 0.9,
	# Gameplay
	"mouse_sensitivity": 0.5,    # 0.05-1.0 slider, maps to 0.0005-0.004 rad/px
	"camera_fov": 75.0,
	"camera_bob": true,
	"autosave_interval": 300,   # 5 real minutes
	"show_fps": false,
	# UI
	"ui_scale": 1.0,
	"subtitles": false,
}

func _ready() -> void:
	load_settings()
	ServiceRegistry.register("SettingsManager", self)

func load_settings() -> void:
	settings = DEFAULTS.duplicate(true)
	var cfg = ConfigFile.new()
	var err = cfg.load(SETTINGS_PATH)
	if err != OK:
		print("[Settings] No settings file found, using defaults.")
		return
	for key in DEFAULTS.keys():
		if cfg.has_section_key("settings", key):
			settings[key] = cfg.get_value("settings", key)
	print("[Settings] Loaded from " + SETTINGS_PATH)
	apply_settings()

func save_settings() -> void:
	var cfg = ConfigFile.new()
	for key in settings.keys():
		cfg.set_value("settings", key, settings[key])
	var err = cfg.save(SETTINGS_PATH)
	if err != OK:
		push_error("[Settings] Failed to save settings: " + str(err))
	else:
		print("[Settings] Saved.")

func get_setting(key: String) -> Variant:
	return settings.get(key, DEFAULTS.get(key))

func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	apply_setting(key, value)

func apply_settings() -> void:
	for key in settings.keys():
		apply_setting(key, settings[key])

func apply_setting(key: String, value: Variant) -> void:
	match key:
		"fullscreen":
			if value:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"vsync":
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)
		"fps_limit":
			Engine.max_fps = value
		"master_volume":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
		"music_volume":
			var idx = AudioServer.get_bus_index("Music")
			if idx >= 0:
				AudioServer.set_bus_volume_db(idx, linear_to_db(value))
		"sfx_volume":
			var idx = AudioServer.get_bus_index("SFX")
			if idx >= 0:
				AudioServer.set_bus_volume_db(idx, linear_to_db(value))
		"ambient_volume":
			var idx = AudioServer.get_bus_index("Ambient")
			if idx >= 0:
				AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func get_autosave_interval() -> int:
	return settings.get("autosave_interval", 300)
