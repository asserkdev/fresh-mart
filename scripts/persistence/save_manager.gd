extends Node
## SaveManager — handles all save/load operations, autosave, backups, and dirty tracking.

const SAVE_DIR: String = "user://saves/"
const BACKUP_DIR: String = "user://saves/backups/"
const MAX_BACKUPS: int = 3
const SAVE_VERSION: int = 7

var _dirty_flags: Dictionary = {
	"player": false, "inventory": false, "economy": false, "npc": false,
	"business": false, "chunks": [], "quests": false, "world_events": false
}
var _autosave_timer: float = 0.0
var _autosave_interval: float = 300.0  # 5 real minutes
var _is_saving: bool = false

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BACKUP_DIR))
	ServiceRegistry.register("SaveManager", self)
	# Connect dirty signals
	EventBus.player_moved.connect(func(_p): mark_dirty("player"))
	EventBus.player_inventory_changed.connect(func(): mark_dirty("inventory"))
	EventBus.player_money_changed.connect(func(_m): mark_dirty("economy"))
	EventBus.inventory_changed.connect(func(_s): mark_dirty("business"))
	EventBus.employee_hired.connect(func(_id): mark_dirty("business"))
	EventBus.employee_fired.connect(func(_id): mark_dirty("business"))
	EventBus.quest_started.connect(func(_id): mark_dirty("quests"))
	EventBus.quest_completed.connect(func(_id): mark_dirty("quests"))
	EventBus.object_placed.connect(func(_id, _pos): mark_dirty("chunks"))
	EventBus.object_removed.connect(func(_id): mark_dirty("chunks"))

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	_autosave_interval = float(SettingsManager.get_autosave_interval())
	_autosave_timer += delta
	if _autosave_timer >= _autosave_interval:
		_autosave_timer = 0.0
		if _is_world_dirty():
			autosave()

func mark_dirty(flag: String) -> void:
	if flag == "chunks":
		pass  # chunk-level tracking handled by ChunkManager
	else:
		_dirty_flags[flag] = true

func _is_world_dirty() -> bool:
	for key in _dirty_flags:
		if _dirty_flags[key] == true:
			return true
	# Also check chunk manager
	if ServiceRegistry.has_service("ChunkManager"):
		var cm = ServiceRegistry.get_service("ChunkManager")
		if cm and cm.has_dirty_chunks():
			return true
	return false

func _clear_dirty_flags() -> void:
	for key in _dirty_flags:
		_dirty_flags[key] = false

func autosave() -> void:
	if GameManager.current_save_slot == "":
		return
	EventBus.autosave_started.emit()
	await save_game(GameManager.current_save_slot)
	EventBus.autosave_completed.emit(GameManager.current_save_slot)
	EventBus.notification_requested.emit("Game autosaved.", "info", 2.0)

func save_game(slot: String) -> bool:
	if _is_saving:
		push_warning("[SaveManager] Save already in progress.")
		return false
	_is_saving = true

	var data = _collect_save_data(slot)
	var path = SAVE_DIR + slot + ".json"
	var backup_created = _create_backup(slot)

	var json_str = JSON.stringify(data, "\t")
	var file = FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Cannot open save file: " + path)
		EventBus.save_failed.emit("Cannot open file: " + path)
		_is_saving = false
		return false

	file.store_string(json_str)
	file.close()

	# Verify write
	var verify = FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.READ)
	if verify == null:
		push_error("[SaveManager] Save verification failed: " + path)
		EventBus.save_failed.emit("Verification failed")
		_is_saving = false
		return false
	verify.close()

	_clear_dirty_flags()
	_is_saving = false
	EventBus.save_completed.emit(slot)
	print("[SaveManager] Saved slot: " + slot)
	return true

func load_game(slot: String) -> Dictionary:
	var path = SAVE_DIR + slot + ".json"
	var full_path = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(full_path):
		push_error("[SaveManager] Save not found: " + path)
		return {}

	var file = FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		return _try_load_backup(slot)

	var json_str = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(json_str)
	if err != OK:
		push_error("[SaveManager] JSON parse error: " + json.get_error_message())
		return _try_load_backup(slot)

	var data = json.get_data()
	if not _validate_save(data):
		return _try_load_backup(slot)

	print("[SaveManager] Loaded slot: " + slot)
	return data

func _try_load_backup(slot: String) -> Dictionary:
	for i in range(MAX_BACKUPS):
		var bp = BACKUP_DIR + slot + "_backup_" + str(i) + ".json"
		var full = ProjectSettings.globalize_path(bp)
		if FileAccess.file_exists(full):
			var f = FileAccess.open(full, FileAccess.READ)
			if f:
				var txt = f.get_as_text()
				f.close()
				var json = JSON.new()
				if json.parse(txt) == OK:
					var d = json.get_data()
					if _validate_save(d):
						print("[SaveManager] Loaded backup: " + bp)
						EventBus.notification_requested.emit("Loaded from backup save.", "warning", 5.0)
						return d
	push_error("[SaveManager] All backups failed for slot: " + slot)
	return {}

func _create_backup(slot: String) -> bool:
	var src = ProjectSettings.globalize_path(SAVE_DIR + slot + ".json")
	if not FileAccess.file_exists(src):
		return false
	# Rotate backups
	for i in range(MAX_BACKUPS - 1, 0, -1):
		var old = ProjectSettings.globalize_path(BACKUP_DIR + slot + "_backup_" + str(i - 1) + ".json")
		var new_path = ProjectSettings.globalize_path(BACKUP_DIR + slot + "_backup_" + str(i) + ".json")
		if FileAccess.file_exists(old):
			DirAccess.copy_absolute(old, new_path)
	DirAccess.copy_absolute(src, ProjectSettings.globalize_path(BACKUP_DIR + slot + "_backup_0.json"))
	return true

func _validate_save(data: Dictionary) -> bool:
	if not data.has("version"):
		return false
	if not data.has("metadata"):
		return false
	return true

func _collect_save_data(slot: String) -> Dictionary:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"metadata": {
			"slot": slot,
			"created": Time.get_datetime_string_from_system(),
			"playtime": GameManager.get_playtime_seconds(),
			"play_mode": GameManager.play_mode,
		},
		"clock": GameClock.get_state(),
	}

	# Player state
	var player = ServiceRegistry.get_service("Player")
	if player and player.has_method("get_save_data"):
		data["player"] = player.get_save_data()

	# Economy
	var economy = ServiceRegistry.get_service("EconomyManager")
	if economy and economy.has_method("get_save_data"):
		data["economy"] = economy.get_save_data()

	# Supermarket
	var sm = ServiceRegistry.get_service("SupermarketManager")
	if sm and sm.has_method("get_save_data"):
		data["supermarket"] = sm.get_save_data()

	# Quests
	var qm = ServiceRegistry.get_service("QuestManager")
	if qm and qm.has_method("get_save_data"):
		data["quests"] = qm.get_save_data()

	# Chunks
	var cm = ServiceRegistry.get_service("ChunkManager")
	if cm and cm.has_method("get_save_data"):
		data["chunks"] = cm.get_save_data()

	return data

func get_save_slots() -> Array:
	var slots = []
	var dir = DirAccess.open(ProjectSettings.globalize_path(SAVE_DIR))
	if dir:
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if f.ends_with(".json") and not f.begins_with("backup"):
				slots.append(f.replace(".json", ""))
			f = dir.get_next()
	return slots

func delete_save(slot: String) -> void:
	var path = ProjectSettings.globalize_path(SAVE_DIR + slot + ".json")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	print("[SaveManager] Deleted slot: " + slot)
