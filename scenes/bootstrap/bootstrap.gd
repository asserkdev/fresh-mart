extends Node
## Bootstrap — initializes all systems and launches the main menu.

func _ready() -> void:
	print("[Bootstrap] Starting Fresh Mart v7...")
	await _initialize_all()
	print("[Bootstrap] Initialization complete. Loading main menu.")
	SceneManager.load_scene("res://scenes/menus/main_menu.tscn")

func _initialize_all() -> void:
	# Wait one frame for all autoloads to be ready
	await get_tree().process_frame

	# Initialize systems in order
	SettingsManager.load_settings()
	GameManager.initialize()

	# Check for crash recovery
	var slots = SaveManager.get_save_slots()
	if slots.size() > 0:
		# Validate most recent save
		var latest = slots[slots.size() - 1]
		var data = SaveManager.load_game(latest)
		if not data.is_empty():
			print("[Bootstrap] Save data valid for slot: " + latest)
		else:
			print("[Bootstrap] No valid save data found.")

	# Audio buses setup
	_setup_audio_buses()

	print("[Bootstrap] Systems initialized.")

func _setup_audio_buses() -> void:
	# Ensure required audio buses exist
	var required_buses = ["Master", "Music", "SFX", "Ambient", "UI"]
	for bus_name in required_buses:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var idx = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(idx, bus_name)
			if bus_name != "Master":
				AudioServer.set_bus_send(idx, "Master")
