extends Node
## NPCManager — spawns, manages, and simulates NPCs at appropriate detail levels.

const MAX_ACTIVE_NPCS: int = 30
const FULL_SIM_RADIUS: float = 60.0
const REDUCED_SIM_RADIUS: float = 120.0

var active_npcs: Dictionary = {}   # npc_id -> NPC node
var npc_data: Dictionary = {}      # npc_id -> persistent data
var _spawn_points: Array = []

func _ready() -> void:
	ServiceRegistry.register("NPCManager", self)
	EventBus.chunk_loaded.connect(_on_chunk_loaded)
	EventBus.chunk_unloaded.connect(_on_chunk_unloaded)
	_load_npc_definitions()

func _load_npc_definitions() -> void:
	# City residents
	var residents = [
		{"id":"npc_001","name":"Elena Marsh","occupation":"Teacher","home":"residential_west","schedule":"school_hours"},
		{"id":"npc_002","name":"Tom Reyes","occupation":"Office Worker","home":"downtown","schedule":"office_hours"},
		{"id":"npc_003","name":"Maria Chen","occupation":"Shop Owner","home":"old_town","schedule":"shop_hours"},
		{"id":"npc_004","name":"James Patel","occupation":"Farmer","home":"suburban","schedule":"farm_hours"},
		{"id":"npc_005","name":"Sara Wilson","occupation":"Student","home":"university","schedule":"student_hours"},
		{"id":"npc_006","name":"Alex Novak","occupation":"Truck Driver","home":"industrial","schedule":"driver_hours"},
		{"id":"npc_007","name":"Lily Park","occupation":"Doctor","home":"residential_east","schedule":"hospital_hours"},
		{"id":"npc_008","name":"David Okonkwo","occupation":"Chef","home":"waterfront","schedule":"restaurant_hours"},
	]
	for r in residents:
		npc_data[r["id"]] = r.duplicate(true)
		npc_data[r["id"]]["state"] = "at_home"
		npc_data[r["id"]]["preferences"] = {"quality_pref": randf_range(0.3, 0.9), "price_sensitivity": randf_range(0.3, 0.8)}
		npc_data[r["id"]]["needs"] = {"hunger": 0.5, "rest": 0.8}

func _process(delta: float) -> void:
	var player = ServiceRegistry.get_service("Player") if ServiceRegistry.has_service("Player") else null
	if player == null:
		return
	for npc_id in active_npcs:
		var npc = active_npcs[npc_id]
		if not is_instance_valid(npc):
			continue
		var dist = player.global_position.distance_to(npc.global_position)
		if dist < FULL_SIM_RADIUS:
			npc.set_simulation_level(2)
		elif dist < REDUCED_SIM_RADIUS:
			npc.set_simulation_level(1)
		else:
			npc.set_simulation_level(0)

func _on_chunk_loaded(chunk_id: String) -> void:
	_spawn_npcs_for_chunk(chunk_id)

func _on_chunk_unloaded(chunk_id: String) -> void:
	_despawn_npcs_for_chunk(chunk_id)

func _spawn_npcs_for_chunk(chunk_id: String) -> void:
	if active_npcs.size() >= MAX_ACTIVE_NPCS:
		return
	# Spawn relevant NPCs for this district
	var district = _get_district_from_chunk(chunk_id)
	for npc_id in npc_data:
		var data = npc_data[npc_id]
		if data.get("home", "") == district and not active_npcs.has(npc_id):
			_spawn_npc(npc_id, chunk_id)
			if active_npcs.size() >= MAX_ACTIVE_NPCS:
				break

func _get_district_from_chunk(chunk_id: String) -> String:
	for district in ["downtown","old_town","residential_west","residential_east",
					 "university","industrial","waterfront","suburban"]:
		if chunk_id.contains(district):
			return district
	return ""

func _spawn_npc(npc_id: String, chunk_id: String) -> void:
	var npc_scene = load("res://scenes/characters/npc.tscn")
	if npc_scene == null:
		return
	var npc = npc_scene.instantiate()
	npc.setup(npc_id, npc_data[npc_id])
	var cm = ServiceRegistry.get_service("ChunkManager")
	if cm and cm._loaded_scenes.has(chunk_id):
		cm._loaded_scenes[chunk_id].add_child(npc)
	else:
		add_child(npc)
	active_npcs[npc_id] = npc

func _despawn_npcs_for_chunk(chunk_id: String) -> void:
	var district = _get_district_from_chunk(chunk_id)
	var to_remove = []
	for npc_id in active_npcs:
		var data = npc_data.get(npc_id, {})
		if data.get("home", "") == district:
			to_remove.append(npc_id)
	for npc_id in to_remove:
		if active_npcs.has(npc_id):
			var npc = active_npcs[npc_id]
			if is_instance_valid(npc):
				# Save state before removing
				npc_data[npc_id]["state"] = npc.get_current_state() if npc.has_method("get_current_state") else "at_home"
				npc.queue_free()
			active_npcs.erase(npc_id)

func simulate_background_npcs(hours: int) -> void:
	# Fast simulation for NPCs not currently active
	for npc_id in npc_data:
		if active_npcs.has(npc_id):
			continue
		var data = npc_data[npc_id]
		# Simple need decay
		data["needs"]["hunger"] = max(0.0, data["needs"].get("hunger", 0.5) - hours * 0.1)
		data["needs"]["rest"] = max(0.0, data["needs"].get("rest", 0.8) - hours * 0.05)
		# Update state based on time
		var h = GameClock.game_hour
		if h >= 22 or h < 7:
			data["state"] = "sleeping"
		elif h >= 9 and h <= 17:
			data["state"] = "working"
		else:
			data["state"] = "leisure"

func get_npc_data(npc_id: String) -> Dictionary:
	return npc_data.get(npc_id, {})

func get_save_data() -> Dictionary:
	return {"npc_data": npc_data.duplicate(true)}

func restore_save_data(data: Dictionary) -> void:
	var saved = data.get("npc_data", {})
	for npc_id in saved:
		if npc_data.has(npc_id):
			npc_data[npc_id].merge(saved[npc_id], true)
