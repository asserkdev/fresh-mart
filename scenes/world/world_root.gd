extends Node3D
## WorldRoot — sets up the game world, spawns player, initializes all world systems.

@onready var environment_node: WorldEnvironment = $WorldEnvironment
@onready var directional_light: DirectionalLight3D = $DirectionalLight3D
@onready var chunk_manager: Node = $ChunkManager
@onready var npc_manager_node: Node = $NPCManager
@onready var player_spawn: Marker3D = $PlayerSpawn
var _pause_menu: Control = null

var _player: CharacterBody3D = null

func _ready() -> void:
	# Register world managers
	ServiceRegistry.register("ChunkManager", chunk_manager)
	ServiceRegistry.register("NPCManager", npc_manager_node)
	_pause_menu = $PauseMenu if has_node("PauseMenu") else null

	# Initialize supermarket systems
	var sm_node = $SupermarketManager
	if sm_node:
		sm_node.initialize_subsystems()

	# Spawn player
	_spawn_player()

	# Start quest auto-starts
	var qm = ServiceRegistry.get_service("QuestManager")
	if qm:
		qm._check_auto_starts()

	# Start day/night environment
	EventBus.time_of_day_changed.connect(_on_time_changed)
	_on_time_changed(GameClock.game_hour)

	# Load save data into world
	if GameManager.current_save_slot != "":
		_restore_world_state()

	print("[WorldRoot] World ready.")

func _spawn_player() -> void:
	var player_scene = load("res://scenes/player/player.tscn")
	if player_scene == null:
		push_error("[WorldRoot] Player scene not found!")
		return
	_player = player_scene.instantiate()
	add_child(_player)
	if player_spawn:
		_player.global_position = player_spawn.global_position
	else:
		_player.global_position = Vector3(0, 1, 0)
	ServiceRegistry.register("Player", _player)
	print("[WorldRoot] Player spawned at: " + str(_player.global_position))

func _restore_world_state() -> void:
	var data = SaveManager.load_game(GameManager.current_save_slot)
	if data.is_empty():
		return
	# Restore clock
	if data.has("clock"):
		GameClock.restore_state(data["clock"])
	# Restore player
	if data.has("player") and _player:
		_player.restore_save_data(data["player"])
	# Restore economy / supermarket
	var sm = ServiceRegistry.get_service("SupermarketManager")
	if sm and data.has("supermarket"):
		sm.restore_save_data(data["supermarket"])
	# Restore quests
	var qm = ServiceRegistry.get_service("QuestManager")
	if qm and data.has("quests"):
		qm.restore_save_data(data["quests"])
	# Restore chunks
	if data.has("chunks"):
		chunk_manager.restore_save_data(data["chunks"])

func _on_time_changed(hour: int) -> void:
	# Rotate sun/moon
	var angle = (hour / 24.0) * TAU - PI * 0.5
	directional_light.rotation.x = angle
	# Day/night tint
	var day_progress = GameClock.get_day_progress()
	var is_day = GameClock.is_daytime()
	if is_day:
		directional_light.light_color = Color(1.0, 0.95, 0.85)
		directional_light.light_energy = lerp(0.3, 1.2, sin(day_progress * PI))
	else:
		directional_light.light_color = Color(0.4, 0.4, 0.6)
		directional_light.light_energy = 0.15

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameManager.current_mode == GameManager.GameMode.PAUSED:
			if _pause_menu: _pause_menu.visible = false
		elif GameManager.current_mode == GameManager.GameMode.PLAYING:
			if _pause_menu: _pause_menu.visible = true
