extends Node
## ChunkManager — fixed city with deterministic chunk IDs, circular streaming.

const CHUNK_SIZE: float = 64.0
const LOAD_RADIUS: float = 128.0
const UNLOAD_RADIUS: float = 160.0
const INNER_RADIUS: float = 64.0

enum ChunkState { UNLOADED, LOADING, LOADED, UNLOADING }

var _chunks: Dictionary = {}          # chunk_id -> ChunkData
var _loaded_scenes: Dictionary = {}   # chunk_id -> Node
var _dirty_chunks: Array[String] = []
var _load_queue: Array[String] = []
var _loading: bool = false

var _player_ref: CharacterBody3D = null
var _last_player_chunk: String = ""

func _ready() -> void:
	ServiceRegistry.register("ChunkManager", self)
	_load_chunk_manifest()

func _process(_delta: float) -> void:
	var player = ServiceRegistry.get_service("Player") if ServiceRegistry.has_service("Player") else null
	if player == null:
		return
	_update_chunks(player.global_position)
	if not _loading and _load_queue.size() > 0:
		_process_load_queue()

func _load_chunk_manifest() -> void:
	# Register all authored chunks with their definitions
	var manifest_path = "res://data/districts/chunk_manifest.json"
	if not ResourceLoader.exists(manifest_path):
		_generate_default_manifest()
		return
	var file = FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		_generate_default_manifest()
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var manifest = json.get_data()
		for chunk_def in manifest:
			_register_chunk(chunk_def)
	file.close()

func _generate_default_manifest() -> void:
	# Generate a grid of chunks for each district
	var districts = {
		"downtown": Vector2(0, 0),
		"old_town": Vector2(5, 0),
		"residential_west": Vector2(-5, 0),
		"residential_east": Vector2(5, 5),
		"university": Vector2(0, 5),
		"industrial": Vector2(-5, 5),
		"waterfront": Vector2(0, -5),
		"suburban": Vector2(-5, -5),
	}
	for district_name in districts:
		var origin = districts[district_name]
		for x in range(4):
			for y in range(4):
				var cx = int(origin.x) + x
				var cy = int(origin.y) + y
				var chunk_id = "district_%s_%d_%d" % [district_name, cx, cy]
				_register_chunk({
					"id": chunk_id,
					"district": district_name,
					"grid_x": cx,
					"grid_y": cy,
					"world_x": (origin.x + x) * CHUNK_SIZE,
					"world_z": (origin.y + y) * CHUNK_SIZE,
					"scene": "",  # will use procedural fallback
				})

func _register_chunk(def: Dictionary) -> void:
	var chunk_id = def.get("id", "")
	if chunk_id == "":
		return
	_chunks[chunk_id] = {
		"id": chunk_id,
		"district": def.get("district", ""),
		"grid_x": def.get("grid_x", 0),
		"grid_y": def.get("grid_y", 0),
		"world_x": def.get("world_x", 0.0),
		"world_z": def.get("world_z", 0.0),
		"scene": def.get("scene", ""),
		"state": ChunkState.UNLOADED,
		"persistent_state": {},
	}

func get_chunk_id(world_pos: Vector3) -> String:
	var gx = int(floor(world_pos.x / CHUNK_SIZE))
	var gz = int(floor(world_pos.z / CHUNK_SIZE))
	# Find which district this falls in
	for chunk_id in _chunks:
		var c = _chunks[chunk_id]
		if c["grid_x"] == gx and c["grid_y"] == gz:
			return chunk_id
	return ""

func get_required_chunks(player_pos: Vector3) -> Array[String]:
	var required: Array[String] = []
	for chunk_id in _chunks:
		var c = _chunks[chunk_id]
		var cx = c["world_x"] + CHUNK_SIZE * 0.5
		var cz = c["world_z"] + CHUNK_SIZE * 0.5
		var dist = Vector2(player_pos.x - cx, player_pos.z - cz).length()
		if dist <= LOAD_RADIUS:
			required.append(chunk_id)
	return required

func _update_chunks(player_pos: Vector3) -> void:
	var required = get_required_chunks(player_pos)

	# Request loads for required unloaded chunks
	for chunk_id in required:
		if _chunks[chunk_id]["state"] == ChunkState.UNLOADED:
			request_chunk_load(chunk_id)

	# Unload chunks outside range
	for chunk_id in _loaded_scenes.keys():
		var c = _chunks[chunk_id]
		var cx = c["world_x"] + CHUNK_SIZE * 0.5
		var cz = c["world_z"] + CHUNK_SIZE * 0.5
		var dist = Vector2(player_pos.x - cx, player_pos.z - cz).length()
		if dist > UNLOAD_RADIUS:
			request_chunk_unload(chunk_id)

func request_chunk_load(chunk_id: String) -> void:
	if not _chunks.has(chunk_id):
		return
	var c = _chunks[chunk_id]
	if c["state"] != ChunkState.UNLOADED:
		return
	c["state"] = ChunkState.LOADING
	if not _load_queue.has(chunk_id):
		_load_queue.append(chunk_id)
		# Sort by distance to player (closest first)
		var player = ServiceRegistry.get_service("Player")
		if player:
			_load_queue.sort_custom(func(a, b):
				var ca = _chunks[a]; var cb = _chunks[b]
				var pp = player.global_position
				var da = Vector2(pp.x - ca["world_x"], pp.z - ca["world_z"]).length()
				var db = Vector2(pp.x - cb["world_x"], pp.z - cb["world_z"]).length()
				return da < db
			)
	EventBus.chunk_requested.emit(chunk_id)

func request_chunk_unload(chunk_id: String) -> void:
	if not _chunks.has(chunk_id):
		return
	var c = _chunks[chunk_id]
	if c["state"] != ChunkState.LOADED:
		return
	c["state"] = ChunkState.UNLOADING
	save_chunk_state(chunk_id)
	if _loaded_scenes.has(chunk_id):
		_loaded_scenes[chunk_id].queue_free()
		_loaded_scenes.erase(chunk_id)
	c["state"] = ChunkState.UNLOADED
	EventBus.chunk_unloaded.emit(chunk_id)

func _process_load_queue() -> void:
	if _load_queue.is_empty():
		return
	var chunk_id = _load_queue.pop_front()
	_loading = true
	_do_load_chunk.call_deferred(chunk_id)

func _do_load_chunk(chunk_id: String) -> void:
	var c = _chunks.get(chunk_id)
	if c == null:
		_loading = false
		return

	var scene_path = c.get("scene", "")
	var chunk_node: Node3D

	if scene_path != "" and ResourceLoader.exists(scene_path):
		var res = load(scene_path)
		if res:
			chunk_node = res.instantiate()
	else:
		# Fallback: create a minimal ground plane for this chunk
		chunk_node = _create_fallback_chunk(c)

	if chunk_node == null:
		c["state"] = ChunkState.UNLOADED
		_loading = false
		return

	chunk_node.name = chunk_id
	chunk_node.position = Vector3(c["world_x"], 0, c["world_z"])
	add_child(chunk_node)
	_loaded_scenes[chunk_id] = chunk_node

	# Restore persistent state
	restore_chunk_state(chunk_id)

	c["state"] = ChunkState.LOADED
	_loading = false
	EventBus.chunk_loaded.emit(chunk_id)

func _create_fallback_chunk(c: Dictionary) -> Node3D:
	var root = Node3D.new()
	# Ground mesh
	var mesh_inst = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	mesh_inst.mesh = plane
	mesh_inst.position = Vector3(CHUNK_SIZE * 0.5, 0, CHUNK_SIZE * 0.5)
	# Material by district
	var mat = StandardMaterial3D.new()
	var district = c.get("district", "")
	match district:
		"downtown":       mat.albedo_color = Color(0.4, 0.4, 0.45)   # grey concrete
		"industrial":     mat.albedo_color = Color(0.35, 0.33, 0.3)
		"waterfront":     mat.albedo_color = Color(0.3, 0.45, 0.5)
		"residential_west", "residential_east": mat.albedo_color = Color(0.4, 0.5, 0.35)
		"suburban":       mat.albedo_color = Color(0.45, 0.55, 0.38)
		_:                mat.albedo_color = Color(0.42, 0.52, 0.38)
	mat.roughness = 0.9
	mesh_inst.set_surface_override_material(0, mat)
	root.add_child(mesh_inst)
	# Static body for collision
	var sb = StaticBody3D.new()
	var coll = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(CHUNK_SIZE, 0.1, CHUNK_SIZE)
	coll.shape = box
	coll.position = Vector3(CHUNK_SIZE * 0.5, -0.05, CHUNK_SIZE * 0.5)
	sb.add_child(coll)
	root.add_child(sb)
	return root

func save_chunk_state(chunk_id: String) -> void:
	if not _loaded_scenes.has(chunk_id):
		return
	var node = _loaded_scenes[chunk_id]
	var state: Dictionary = {}
	# Ask all persistent objects in chunk to save themselves
	for child in node.get_children():
		if child.has_method("get_persistent_state"):
			state[child.name] = child.get_persistent_state()
	_chunks[chunk_id]["persistent_state"] = state
	if not _dirty_chunks.has(chunk_id):
		_dirty_chunks.append(chunk_id)

func restore_chunk_state(chunk_id: String) -> void:
	if not _loaded_scenes.has(chunk_id):
		return
	var node = _loaded_scenes[chunk_id]
	var state = _chunks[chunk_id].get("persistent_state", {})
	for child in node.get_children():
		if state.has(child.name) and child.has_method("restore_persistent_state"):
			child.restore_persistent_state(state[child.name])

func is_chunk_loaded(chunk_id: String) -> bool:
	return _chunks.get(chunk_id, {}).get("state", ChunkState.UNLOADED) == ChunkState.LOADED

func has_dirty_chunks() -> bool:
	return _dirty_chunks.size() > 0

func get_save_data() -> Dictionary:
	var data: Dictionary = {}
	for chunk_id in _chunks:
		var c = _chunks[chunk_id]
		if c["persistent_state"].size() > 0 or _dirty_chunks.has(chunk_id):
			data[chunk_id] = c["persistent_state"]
	return data

func restore_save_data(data: Dictionary) -> void:
	for chunk_id in data:
		if _chunks.has(chunk_id):
			_chunks[chunk_id]["persistent_state"] = data[chunk_id]
