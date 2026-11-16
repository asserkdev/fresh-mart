extends Node
## SceneManager — handles scene transitions with loading screen support.

signal scene_loaded(scene_path: String)
signal scene_unloaded(scene_path: String)

var _current_scene: Node = null
var _current_path: String = ""
var _loading: bool = false

func _ready() -> void:
	ServiceRegistry.register("SceneManager", self)

func load_scene(path: String) -> void:
	if _loading:
		push_warning("[SceneManager] Already loading a scene.")
		return
	_loading = true
	# Show loading screen if one exists
	_show_loading_screen(true)
	await _do_load_scene(path)
	_show_loading_screen(false)
	_loading = false
	scene_loaded.emit(path)

func _do_load_scene(path: String) -> void:
	# Unload existing scene
	if _current_scene != null:
		scene_unloaded.emit(_current_path)
		_current_scene.queue_free()
		await get_tree().process_frame
		_current_scene = null

	# Load new scene
	var loader = ResourceLoader.load_threaded_request(path)
	if loader != OK:
		push_error("[SceneManager] Failed to request load: " + path)
		return

	var progress = []
	while true:
		await get_tree().process_frame
		var status = ResourceLoader.load_threaded_get_status(path, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("[SceneManager] Load failed: " + path)
			return
		elif status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("[SceneManager] Invalid resource: " + path)
			return

	var resource = ResourceLoader.load_threaded_get(path)
	if resource == null:
		push_error("[SceneManager] Null resource: " + path)
		return

	var scene = resource.instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	_current_scene = scene
	_current_path = path
	print("[SceneManager] Loaded: " + path)

func _show_loading_screen(visible: bool) -> void:
	# Loading screen is handled via UI overlay — emit signal for HUD
	if visible:
		EventBus.menu_opened.emit("loading")
	else:
		EventBus.menu_closed.emit("loading")

func get_current_path() -> String:
	return _current_path
