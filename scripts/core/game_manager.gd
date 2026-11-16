extends Node
## GameManager — tracks the current game session, mode, state transitions, and pause.

enum GameMode { NONE, MAIN_MENU, LOADING, PLAYING, PAUSED, CUTSCENE, GAME_OVER }
enum PlayMode { CAREER, FREE_PLAY, SANDBOX }

var current_mode: GameMode = GameMode.NONE
var play_mode: PlayMode = PlayMode.CAREER
var current_save_slot: String = ""
var session_start_time: float = 0.0
var total_playtime: float = 0.0  # seconds this session
var is_initialized: bool = false

func _ready() -> void:
	set_process(true)
	EventBus.save_completed.connect(_on_save_completed)

func _process(delta: float) -> void:
	if current_mode == GameMode.PLAYING:
		total_playtime += delta

func initialize() -> void:
	if is_initialized:
		return
	is_initialized = true
	session_start_time = Time.get_unix_time_from_system()
	print("[GameManager] Initialized")

func start_new_game(slot: String, mode: PlayMode = PlayMode.CAREER) -> void:
	current_save_slot = slot
	play_mode = mode
	set_mode(GameMode.LOADING)
	total_playtime = 0.0
	await SceneManager.load_scene("res://scenes/world/world_root.tscn")
	set_mode(GameMode.PLAYING)
	EventBus.game_loaded.emit(slot)

func load_game(slot: String) -> void:
	current_save_slot = slot
	set_mode(GameMode.LOADING)
	var data = SaveManager.load_game(slot)
	if data == null:
		push_error("[GameManager] Failed to load slot: " + slot)
		set_mode(GameMode.MAIN_MENU)
		return
	total_playtime = data.get("playtime", 0.0)
	play_mode = data.get("play_mode", PlayMode.CAREER) as PlayMode
	await SceneManager.load_scene("res://scenes/world/world_root.tscn")
	set_mode(GameMode.PLAYING)
	EventBus.game_loaded.emit(slot)

func pause_game() -> void:
	if current_mode != GameMode.PLAYING:
		return
	set_mode(GameMode.PAUSED)
	get_tree().paused = true

func resume_game() -> void:
	if current_mode != GameMode.PAUSED:
		return
	set_mode(GameMode.PLAYING)
	get_tree().paused = false

func return_to_main_menu() -> void:
	if current_mode == GameMode.PLAYING or current_mode == GameMode.PAUSED:
		get_tree().paused = false
		await SaveManager.save_game(current_save_slot)
	set_mode(GameMode.MAIN_MENU)
	SceneManager.load_scene("res://scenes/menus/main_menu.tscn")

func quit_game() -> void:
	if current_mode == GameMode.PLAYING or current_mode == GameMode.PAUSED:
		get_tree().paused = false
		await SaveManager.save_game(current_save_slot)
	get_tree().quit()

func set_mode(mode: GameMode) -> void:
	current_mode = mode
	print("[GameManager] Mode -> " + GameMode.keys()[mode])

func is_playing() -> bool:
	return current_mode == GameMode.PLAYING

func get_playtime_seconds() -> float:
	return total_playtime

func _on_save_completed(slot: String) -> void:
	print("[GameManager] Save completed for slot: " + slot)
