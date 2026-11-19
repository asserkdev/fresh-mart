extends CharacterBody3D
## PlayerController — movement, interaction, inventory, camera switching.

const WALK_SPEED: float = 4.5
const RUN_SPEED: float = 8.0
const SPRINT_SPEED: float = 12.0
const JUMP_VELOCITY: float = 5.0
const GRAVITY: float = 9.8
const MOUSE_SENSITIVITY_BASE: float = 0.003

var speed: float = WALK_SPEED
var is_sprinting: bool = false
var _camera_mode: String = "first_person"  # "first_person" or "third_person"

@onready var fp_pivot: Node3D = $FPCameraPivot
@onready var tp_pivot: Node3D = $TPCameraPivot
@onready var fp_camera: Camera3D = $FPCameraPivot/Camera3D
@onready var tp_camera: Camera3D = $TPCameraPivot/TPCamera
@onready var interaction_ray: RayCast3D = $FPCameraPivot/InteractionRay
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var mesh_root: Node3D = $MeshRoot

var _yaw: float = 0.0
var _pitch: float = 0.0
var _tp_distance: float = 4.0
var _mouse_sensitivity: float = 0.003
var _interacting_with: Node = null
var _interaction_prompt: String = ""

# Inventory
var inventory: Dictionary = {}  # product_id -> quantity
var inventory_capacity: int = 20
var held_money: float = 500.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_set_camera_mode("first_person")
	ServiceRegistry.register("Player", self)
	_update_sensitivity()
	if mesh_root:
		CharacterMeshBuilder.build_character(mesh_root, "default")

func _update_sensitivity() -> void:
	# Settings slider goes 0.05 to 1.0
	# Map to 0.0005 - 0.004 rad/pixel — comfortable range
	var s = SettingsManager.get_setting("mouse_sensitivity")
	_mouse_sensitivity = lerp(0.0005, 0.004, s)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * _mouse_sensitivity
		_pitch -= event.relative.y * _mouse_sensitivity
		_pitch = clamp(_pitch, -1.4, 1.4)
		if _camera_mode == "first_person":
			fp_pivot.rotation.x = _pitch
			rotation.y = _yaw
		else:
			tp_pivot.rotation.x = _pitch
			rotation.y = _yaw

	if event.is_action_pressed("toggle_camera"):
		var new_mode = "third_person" if _camera_mode == "first_person" else "first_person"
		_set_camera_mode(new_mode)

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("pause"):
		if GameManager.current_mode == GameManager.GameMode.PLAYING:
			GameManager.pause_game()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif GameManager.current_mode == GameManager.GameMode.PAUSED:
			GameManager.resume_game()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("save_game"):
		if GameManager.is_playing():
			SaveManager.save_game(GameManager.current_save_slot)

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Sprint
	is_sprinting = Input.is_action_pressed("sprint")
	speed = SPRINT_SPEED if is_sprinting else WALK_SPEED

	# Move direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction.length() > 0.01:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		EventBus.player_moved.emit(global_position)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	_update_animation()
	_update_interaction()

	# Third person camera spring arm collision
	if _camera_mode == "third_person":
		_update_tp_camera()

func _update_animation() -> void:
	if not anim_player:
		return
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed < 0.1:
		if anim_player.has_animation("Idle"):
			anim_player.play("Idle")
	elif is_sprinting:
		if anim_player.has_animation("Running"):
			anim_player.play("Running")
	else:
		if anim_player.has_animation("Walking"):
			anim_player.play("Walking")

func _update_interaction() -> void:
	if not interaction_ray:
		return
	interaction_ray.enabled = true
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider and collider.has_method("can_interact") and collider.can_interact(self):
			_interacting_with = collider
			_interaction_prompt = collider.get_interaction_text()
			return
	_interacting_with = null
	_interaction_prompt = ""

func _try_interact() -> void:
	if _interacting_with and _interacting_with.has_method("interact"):
		_interacting_with.interact(self)
		EventBus.player_interacted.emit(str(_interacting_with.get_instance_id()))

func _set_camera_mode(mode: String) -> void:
	_camera_mode = mode
	if mode == "first_person":
		fp_camera.current = true
		tp_camera.current = false
		if mesh_root:
			mesh_root.visible = false
	else:
		fp_camera.current = false
		tp_camera.current = true
		if mesh_root:
			mesh_root.visible = true
	EventBus.camera_changed.emit(mode)

func _update_tp_camera() -> void:
	# Simple camera collision for third person
	var from = global_position + Vector3(0, 1.6, 0)
	var desired = from + tp_pivot.global_basis * Vector3(0, 0, _tp_distance)
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, desired)
	params.exclude = [self]
	var result = space.intersect_ray(params)
	if result:
		tp_camera.global_position = result["position"] + result["normal"] * 0.2
	else:
		tp_camera.global_position = desired

func get_interaction_prompt() -> String:
	return _interaction_prompt

# --- Inventory ---
func add_item(product_id: String, quantity: int) -> bool:
	var current = inventory.get(product_id, 0)
	if current + quantity > inventory_capacity:
		EventBus.notification_requested.emit("Inventory full!", "warning", 2.0)
		return false
	inventory[product_id] = current + quantity
	EventBus.player_inventory_changed.emit()
	return true

func remove_item(product_id: String, quantity: int) -> bool:
	var current = inventory.get(product_id, 0)
	if current < quantity:
		return false
	inventory[product_id] = current - quantity
	if inventory[product_id] <= 0:
		inventory.erase(product_id)
	EventBus.player_inventory_changed.emit()
	return true

func get_item_count(product_id: String) -> int:
	return inventory.get(product_id, 0)

func add_money(amount: float) -> void:
	held_money += amount
	EventBus.player_money_changed.emit(held_money)

func spend_money(amount: float) -> bool:
	if held_money < amount:
		EventBus.notification_requested.emit("Not enough money!", "error", 2.0)
		return false
	held_money -= amount
	EventBus.player_money_changed.emit(held_money)
	return true

# --- Persistence ---
func get_save_data() -> Dictionary:
	return {
		"position": {"x": global_position.x, "y": global_position.y, "z": global_position.z},
		"rotation_y": rotation.y,
		"inventory": inventory.duplicate(),
		"money": held_money,
		"camera_mode": _camera_mode,
	}

func restore_save_data(data: Dictionary) -> void:
	if data.has("position"):
		var p = data["position"]
		global_position = Vector3(p["x"], p["y"], p["z"])
	if data.has("rotation_y"):
		rotation.y = data["rotation_y"]
	if data.has("inventory"):
		inventory = data["inventory"]
	if data.has("money"):
		held_money = data["money"]
		EventBus.player_money_changed.emit(held_money)
	if data.has("camera_mode"):
		_set_camera_mode(data["camera_mode"])
