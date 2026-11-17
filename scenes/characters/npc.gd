extends CharacterBody3D
## NPC — AI-controlled character with states, needs, and navigation.

enum SimLevel { BACKGROUND, REDUCED, FULL }
enum State { IDLE, WALKING, WORKING, SHOPPING, EATING, SOCIALIZING, RESTING }

var npc_id: String = ""
var npc_name: String = "NPC"
var occupation: String = ""
var schedule: String = ""
var needs: Dictionary = {"hunger": 0.5, "rest": 0.8}
var preferences: Dictionary = {}
var current_state: State = State.IDLE
var sim_level: SimLevel = SimLevel.BACKGROUND

var _nav_agent: NavigationAgent3D = null
var _target_position: Vector3 = Vector3.ZERO
var _state_timer: float = 0.0
var _move_speed: float = 2.5

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var mesh_root: Node3D = $MeshRoot

const WALK_SPEED = 2.5
const RUN_SPEED = 5.0
const GRAVITY = 9.8

func _ready() -> void:
	_nav_agent = $NavigationAgent3D
	if _nav_agent:
		_nav_agent.path_desired_distance = 0.5
		_nav_agent.target_desired_distance = 0.8

func setup(id: String, data: Dictionary) -> void:
	npc_id = id
	npc_name = data.get("name", "NPC")
	occupation = data.get("occupation", "")
	schedule = data.get("schedule", "")
	needs = data.get("needs", {"hunger": 0.5, "rest": 0.8})
	preferences = data.get("preferences", {})
	# Build visible mesh
	if mesh_root:
		CharacterMeshBuilder.build_character(mesh_root, "npc")

func set_simulation_level(level: int) -> void:
	sim_level = level as SimLevel
	if anim_player:
		anim_player.active = level >= SimLevel.FULL

func _physics_process(delta: float) -> void:
	if sim_level == SimLevel.BACKGROUND:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	_state_timer -= delta
	if _state_timer <= 0:
		_pick_next_behavior()

	if current_state == State.WALKING and _nav_agent:
		if not _nav_agent.is_navigation_finished():
			var next_pos = _nav_agent.get_next_path_position()
			var dir = (next_pos - global_position).normalized()
			velocity.x = dir.x * _move_speed
			velocity.z = dir.z * _move_speed
			look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
		else:
			velocity.x = 0
			velocity.z = 0
			current_state = State.IDLE
	else:
		velocity.x = move_toward(velocity.x, 0, _move_speed)
		velocity.z = move_toward(velocity.z, 0, _move_speed)

	move_and_slide()
	_update_animation()

func _pick_next_behavior() -> void:
	var rng = randf()
	var hour = GameClock.game_hour
	if hour >= 22 or hour < 7:
		current_state = State.RESTING
		_state_timer = 60.0
	elif hour >= 9 and hour <= 17:
		if rng < 0.6:
			current_state = State.WORKING
			_state_timer = randf_range(10.0, 30.0)
		else:
			_wander()
	else:
		if rng < 0.5:
			_wander()
		else:
			current_state = State.IDLE
			_state_timer = randf_range(5.0, 15.0)

func _wander() -> void:
	var offset = Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))
	var target = global_position + offset
	if _nav_agent:
		_nav_agent.target_position = target
	current_state = State.WALKING
	_state_timer = 20.0

func navigate_to(world_pos: Vector3) -> void:
	if _nav_agent:
		_nav_agent.target_position = world_pos
	current_state = State.WALKING
	_state_timer = 60.0

func _update_animation() -> void:
	if not anim_player:
		return
	var horizontal = Vector2(velocity.x, velocity.z).length()
	match current_state:
		State.RESTING:
			if anim_player.has_animation("Idle"):
				anim_player.play("Idle")
		State.WALKING:
			if horizontal > 0.1:
				if anim_player.has_animation("Walking"):
					anim_player.play("Walking")
			else:
				if anim_player.has_animation("Idle"):
					anim_player.play("Idle")
		_:
			if anim_player.has_animation("Idle"):
				anim_player.play("Idle")

func can_interact(_interactor) -> bool:
	return true

func get_interaction_text() -> String:
	return "Talk to " + npc_name

func interact(interactor) -> void:
	EventBus.notification_requested.emit("Talked to " + npc_name, "info", 2.0)
	# Check quest objectives
	var qm = ServiceRegistry.get_service("QuestManager")
	if qm:
		for qid in qm.active_quests:
			var q = qm.quests.get(qid, {})
			for obj in q.get("objectives", []):
				if obj["type"] == "npc_talked" and obj["target"] == npc_id:
					qm.update_objective(qid, obj["id"], npc_id)

func get_current_state() -> String:
	return State.keys()[current_state]

func get_persistent_state() -> Dictionary:
	return {
		"position": {"x": global_position.x, "y": global_position.y, "z": global_position.z},
		"state": State.keys()[current_state],
		"needs": needs.duplicate(),
	}

func restore_persistent_state(data: Dictionary) -> void:
	if data.has("position"):
		var p = data["position"]
		global_position = Vector3(p["x"], p["y"], p["z"])
	needs = data.get("needs", needs)
