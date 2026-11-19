extends Node
## Bootstrap — initializes all systems and launches the main menu.

func _ready() -> void:
	print("[Bootstrap] Starting Fresh Mart v7...")
	await _initialize_all()
	print("[Bootstrap] Initialization complete. Loading main menu.")
	SceneManager.load_scene("res://scenes/menus/main_menu.tscn")

func _initialize_all() -> void:
	await get_tree().process_frame

	SettingsManager.load_settings()
	GameManager.initialize()

	# Apply global theme
	_apply_global_theme()

	# Check for crash recovery
	var slots = SaveManager.get_save_slots()
	if slots.size() > 0:
		var latest = slots[slots.size() - 1]
		var data = SaveManager.load_game(latest)
		if not data.is_empty():
			print("[Bootstrap] Save data valid for slot: " + latest)

	_setup_audio_buses()
	print("[Bootstrap] Systems initialized.")

func _apply_global_theme() -> void:
	var theme_script = load("res://ui/themes/fresh_mart_theme.gd")
	if theme_script:
		var theme = theme_script.create()
		get_tree().root.theme = theme
		print("[Bootstrap] Global theme applied.")

func _setup_audio_buses() -> void:
	var required_buses = ["Master", "Music", "SFX", "Ambient", "UI"]
	for bus_name in required_buses:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var idx = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(idx, bus_name)
			if bus_name != "Master":
				AudioServer.set_bus_send(idx, "Master")
