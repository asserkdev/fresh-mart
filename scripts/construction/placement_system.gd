extends Node3D
## PlacementSystem — grid-based construction with preview, validation, placement.

signal object_placed_signal(object_id: String, position: Vector3, rotation_y: float)
signal object_removed_signal(object_id: String)

const GRID_SIZE: float = 1.0

var is_active: bool = false
var selected_object_id: String = ""
var _preview_node: Node3D = null
var _preview_valid: bool = false
var _rotate_y: float = 0.0
var _placed_objects: Dictionary = {}   # unique_id -> {id, position, rotation, node}

@export var preview_valid_color: Color = Color(0.3, 1.0, 0.3, 0.5)
@export var preview_invalid_color: Color = Color(1.0, 0.3, 0.3, 0.5)

func _ready() -> void:
	if not ServiceRegistry.has_service("PlacementSystem"):
		ServiceRegistry.register("PlacementSystem", self)
	set_process(false)

func enter_construction_mode() -> void:
	is_active = true
	set_process(true)
	EventBus.construction_mode_entered.emit()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func exit_construction_mode() -> void:
	is_active = false
	set_process(false)
	_clear_preview()
	EventBus.construction_mode_exited.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func select_object(object_id: String) -> void:
	selected_object_id = object_id
	_clear_preview()
	_create_preview(object_id)

func _process(_delta: float) -> void:
	if not is_active or selected_object_id == "":
		return
	_update_preview_position()

func _update_preview_position() -> void:
	if _preview_node == null:
		return
	var camera = _get_active_camera()
	if camera == null:
		return
	var from = camera.project_ray_origin(get_viewport().get_mouse_position())
	var dir = camera.project_ray_normal(get_viewport().get_mouse_position())
	var dist = 10.0
	# Raycast to ground
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, from + dir * dist)
	var result = space.intersect_ray(params)
	if result:
		var snapped = _snap_to_grid(result["position"])
		_preview_node.global_position = snapped
		_preview_node.rotation.y = _rotate_y
		_preview_valid = _validate_placement(snapped)
		_set_preview_color(_preview_valid)

func _snap_to_grid(pos: Vector3) -> Vector3:
	return Vector3(
		round(pos.x / GRID_SIZE) * GRID_SIZE,
		pos.y,
		round(pos.z / GRID_SIZE) * GRID_SIZE
	)

func _validate_placement(pos: Vector3) -> bool:
	if _preview_node == null:
		return false
	# Simple AABB overlap check
	var space = get_world_3d().direct_space_state
	var shape_query = PhysicsShapeQueryParameters3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.8, 1.8, 0.8)
	shape_query.shape = box
	shape_query.transform = Transform3D(Basis(), pos + Vector3(0, 0.9, 0))
	shape_query.collision_mask = 1  # world_static only
	shape_query.exclude = [_preview_node]
	var collisions = space.intersect_shape(shape_query, 1)
	return collisions.is_empty()

func _set_preview_color(valid: bool) -> void:
	if _preview_node == null:
		return
	var color = preview_valid_color if valid else preview_invalid_color
	for child in _preview_node.get_children():
		if child is MeshInstance3D:
			var mat = child.get_surface_override_material(0)
			if mat == null:
				mat = StandardMaterial3D.new()
			mat.albedo_color = color
			mat.flags_transparent = true
			child.set_surface_override_material(0, mat)

func confirm_placement() -> bool:
	if _preview_node == null or not _preview_valid:
		return false
	var pos = _preview_node.global_position
	var rot = _rotate_y
	# Check cost
	var catalog = ServiceRegistry.get_service("ConstructionCatalog")
	if catalog:
		var cost = catalog.get_object_cost(selected_object_id)
		var sm = ServiceRegistry.get_service("SupermarketManager")
		if sm and sm.business_money < cost:
			EventBus.notification_requested.emit("Not enough funds!", "error", 2.0)
			return false
		if sm:
			sm.add_expense("construction", cost)
	var uid = "%s_%d" % [selected_object_id, Time.get_unix_time_from_system()]
	_spawn_placed_object(uid, selected_object_id, pos, rot)
	EventBus.object_placed.emit(uid, pos)
	object_placed_signal.emit(uid, pos, rot)
	return true

func _spawn_placed_object(uid: String, object_id: String, pos: Vector3, rot_y: float) -> void:
	var catalog = ServiceRegistry.get_service("ConstructionCatalog")
	var scene_path = catalog.get_scene_path(object_id) if catalog else ""
	var node: Node3D
	if scene_path != "" and ResourceLoader.exists(scene_path):
		node = load(scene_path).instantiate()
	else:
		node = _create_fallback_mesh(object_id)
	node.global_position = pos
	node.rotation.y = rot_y
	node.name = uid
	add_child(node)
	_placed_objects[uid] = {"id": object_id, "position": pos, "rotation_y": rot_y, "node": node}

func _create_fallback_mesh(object_id: String) -> Node3D:
	var root = Node3D.new()
	var mi = MeshInstance3D.new()
	var dims = _get_object_dims(object_id)
	var box = BoxMesh.new()
	box.size = dims
	mi.mesh = box
	mi.position = Vector3(0, dims.y * 0.5, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = _get_object_color(object_id)
	mat.roughness = 0.7
	mi.set_surface_override_material(0, mat)
	root.add_child(mi)
	# Collision
	var sb = StaticBody3D.new()
	var coll = CollisionShape3D.new()
	var cshape = BoxShape3D.new()
	cshape.size = dims
	coll.shape = cshape
	coll.position = Vector3(0, dims.y * 0.5, 0)
	sb.add_child(coll)
	root.add_child(sb)
	return root

func _get_object_dims(object_id: String) -> Vector3:
	match object_id:
		"shelf_standard": return Vector3(1.0, 1.8, 0.5)
		"shelf_refrigerated": return Vector3(1.0, 2.0, 0.8)
		"checkout_counter": return Vector3(1.5, 1.0, 0.8)
		"display_table": return Vector3(1.2, 0.9, 0.8)
		"storage_rack": return Vector3(1.0, 2.0, 0.6)
		"floor_light": return Vector3(0.3, 2.5, 0.3)
		_: return Vector3(1.0, 1.0, 1.0)

func _get_object_color(object_id: String) -> Color:
	match object_id:
		"shelf_standard": return Color(0.75, 0.65, 0.45)
		"shelf_refrigerated": return Color(0.6, 0.75, 0.9)
		"checkout_counter": return Color(0.6, 0.55, 0.5)
		"display_table": return Color(0.65, 0.6, 0.55)
		"storage_rack": return Color(0.5, 0.55, 0.6)
		"floor_light": return Color(0.9, 0.9, 0.5)
		_: return Color(0.6, 0.6, 0.6)

func remove_object(uid: String) -> bool:
	if not _placed_objects.has(uid):
		return false
	var data = _placed_objects[uid]
	if is_instance_valid(data["node"]):
		data["node"].queue_free()
	_placed_objects.erase(uid)
	EventBus.object_removed.emit(uid)
	object_removed_signal.emit(uid)
	return true

func rotate_preview(direction: int) -> void:
	_rotate_y += direction * PI * 0.5

func _create_preview(object_id: String) -> void:
	_preview_node = _create_fallback_mesh(object_id)
	add_child(_preview_node)

func _clear_preview() -> void:
	if _preview_node:
		_preview_node.queue_free()
		_preview_node = null

func _get_active_camera() -> Camera3D:
	var player = ServiceRegistry.get_service("Player")
	if player == null:
		return get_viewport().get_camera_3d()
	return get_viewport().get_camera_3d()

func get_persistent_state() -> Dictionary:
	var state = {}
	for uid in _placed_objects:
		var d = _placed_objects[uid]
		state[uid] = {
			"id": d["id"],
			"pos": {"x": d["position"].x, "y": d["position"].y, "z": d["position"].z},
			"rot_y": d["rotation_y"],
		}
	return state

func restore_persistent_state(data: Dictionary) -> void:
	for uid in data:
		var d = data[uid]
		var pos = Vector3(d["pos"]["x"], d["pos"]["y"], d["pos"]["z"])
		_spawn_placed_object(uid, d["id"], pos, d["rot_y"])
