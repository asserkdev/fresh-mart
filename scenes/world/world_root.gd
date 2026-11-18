extends Node3D
## WorldRoot — sets up the game world, spawns player, initializes all world systems.

@onready var environment_node: WorldEnvironment = $WorldEnvironment
@onready var directional_light: DirectionalLight3D = $DirectionalLight3D
@onready var chunk_manager: Node = $ChunkManager
@onready var npc_manager_node: Node = $NPCManager
@onready var player_spawn: Marker3D = $PlayerSpawn

var _player: CharacterBody3D = null
var _pause_menu: Control = null
var _weather_system = null

func _ready() -> void:
	# Register world managers (guard against double registration)
	if not ServiceRegistry.has_service("ChunkManager"):
		ServiceRegistry.register("ChunkManager", chunk_manager)
	if not ServiceRegistry.has_service("NPCManager"):
		ServiceRegistry.register("NPCManager", npc_manager_node)
	_pause_menu = get_node_or_null("PauseMenu")

	# Wait one frame for all autoloads and child nodes to be ready
	await get_tree().process_frame

	# Initialize supermarket systems (child nodes register themselves)
	var sm_node = get_node_or_null("SupermarketManager")
	if sm_node:
		sm_node.initialize_subsystems()

	# Spawn player
	_spawn_player()

	# Spawn the supermarket into world
	_spawn_supermarket()

	# Start quest auto-starts
	var qm = ServiceRegistry.get_service("QuestManager")
	if qm:
		qm._check_auto_starts()

	# Day/night environment
	EventBus.time_of_day_changed.connect(_on_time_changed)
	EventBus.weather_changed.connect(_on_weather_changed)
	_on_time_changed(GameClock.game_hour)

	# Load save data into world
	if GameManager.current_save_slot != "":
		_restore_world_state()

	# Build initial ground (supermarket lot)
	_build_starting_lot()

	print("[WorldRoot] World ready. Time: %s" % GameClock.get_time_string())

func _spawn_player() -> void:
	var player_scene = load("res://scenes/player/player.tscn")
	if player_scene == null:
		push_error("[WorldRoot] Player scene not found!")
		return
	_player = player_scene.instantiate()
	add_child(_player)
	# Spawn inside supermarket entrance
	var spawn_pos = player_spawn.global_position if player_spawn else Vector3(12, 1, 30)
	_player.global_position = spawn_pos
	# Player registers itself in its own _ready(); world_root just stores the reference
	await get_tree().process_frame  # let player _ready() run
	print("[WorldRoot] Player spawned at: %s" % str(_player.global_position))
func _spawn_supermarket() -> void:
	var sm_scene = load("res://scenes/supermarket/supermarket.tscn")
	if sm_scene == null:
		push_error("[WorldRoot] Supermarket scene not found!")
		return
	var sm = sm_scene.instantiate()
	sm.name = "SupermarketBuilding"
	add_child(sm)
	sm.global_position = Vector3(0, 0, 0)
	print("[WorldRoot] Supermarket spawned.")

func _build_starting_lot() -> void:
	# Parking lot and surroundings outside the supermarket
	var lot = Node3D.new()
	lot.name = "ParkingLot"
	add_child(lot)

	# Asphalt ground for parking
	var asphalt_sb = StaticBody3D.new()
	asphalt_sb.collision_layer = 1
	var asphalt_mi = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(32, 20)
	asphalt_mi.mesh = pm
	var asphalt_mat = StandardMaterial3D.new()
	var img = Image.create(64, 64, false, Image.FORMAT_RGB8)
	for x in range(64):
		for y in range(64):
			var n = randf_range(-0.03, 0.03)
			img.set_pixel(x, y, Color(0.22 + n, 0.22 + n, 0.22 + n))
	asphalt_mat.albedo_texture = ImageTexture.create_from_image(img)
	asphalt_mat.roughness = 0.95
	asphalt_mi.set_surface_override_material(0, asphalt_mat)
	asphalt_mi.position = Vector3(12, 0.005, 44)
	asphalt_sb.add_child(asphalt_mi)
	var asphalt_coll = CollisionShape3D.new()
	var asphalt_shape = BoxShape3D.new()
	asphalt_shape.size = Vector3(32, 0.05, 20)
	asphalt_coll.shape = asphalt_shape
	asphalt_coll.position = Vector3(12, -0.025, 44)
	asphalt_sb.add_child(asphalt_coll)
	lot.add_child(asphalt_sb)

	# Grass area surrounding the lot
	var grass_sb = StaticBody3D.new()
	grass_sb.collision_layer = 1
	var grass_mi = MeshInstance3D.new()
	var gpm = PlaneMesh.new()
	gpm.size = Vector2(80, 80)
	grass_mi.mesh = gpm
	var grass_mat = StandardMaterial3D.new()
	var gimg = Image.create(64, 64, false, Image.FORMAT_RGB8)
	for x in range(64):
		for y in range(64):
			var n = randf_range(-0.05, 0.05)
			gimg.set_pixel(x, y, Color(0.25 + n, 0.50 + n * 0.5, 0.18 + n * 0.3))
	grass_mat.albedo_texture = ImageTexture.create_from_image(gimg)
	grass_mat.roughness = 0.95
	grass_mi.set_surface_override_material(0, grass_mat)
	grass_mi.position = Vector3(12, -0.01, 20)
	grass_sb.add_child(grass_mi)
	var grass_coll = CollisionShape3D.new()
	var grass_shape = BoxShape3D.new()
	grass_shape.size = Vector3(80, 0.05, 80)
	grass_coll.shape = grass_shape
	grass_coll.position = Vector3(12, -0.025, 20)
	grass_sb.add_child(grass_coll)
	lot.add_child(grass_sb)

	# Parking lines
	for i in range(6):
		var line = MeshInstance3D.new()
		var lpm = PlaneMesh.new()
		lpm.size = Vector2(0.1, 4.5)
		line.mesh = lpm
		var lmat = StandardMaterial3D.new()
		lmat.albedo_color = Color(0.95, 0.95, 0.95)
		lmat.roughness = 0.8
		line.set_surface_override_material(0, lmat)
		line.position = Vector3(2.5 + i * 4.0, 0.012, 42)
		lot.add_child(line)

	# Road leading to supermarket
	var road_sb = StaticBody3D.new()
	road_sb.collision_layer = 1
	var road_mi = MeshInstance3D.new()
	var rpm = PlaneMesh.new()
	rpm.size = Vector2(8, 20)
	road_mi.mesh = rpm
	road_mi.set_surface_override_material(0, asphalt_mat)
	road_mi.position = Vector3(12, 0.008, 60)
	road_sb.add_child(road_mi)
	var road_coll = CollisionShape3D.new()
	var road_shape = BoxShape3D.new()
	road_shape.size = Vector3(8, 0.05, 20)
	road_coll.shape = road_shape
	road_coll.position = Vector3(12, -0.025, 60)
	road_sb.add_child(road_coll)
	lot.add_child(road_sb)

func _restore_world_state() -> void:
	var data = SaveManager.load_game(GameManager.current_save_slot)
	if data.is_empty():
		return
	if data.has("clock"):
		GameClock.restore_state(data["clock"])
	if data.has("player") and _player:
		_player.restore_save_data(data["player"])
	var sm = ServiceRegistry.get_service("SupermarketManager")
	if sm and data.has("supermarket"):
		sm.restore_save_data(data["supermarket"])
	var qm = ServiceRegistry.get_service("QuestManager")
	if qm and data.has("quests"):
		qm.restore_save_data(data["quests"])
	if data.has("chunks"):
		chunk_manager.restore_save_data(data["chunks"])
	var inv = ServiceRegistry.get_service("InventoryManager")
	if inv and data.has("inventory"):
		inv.restore_save_data(data["inventory"])
	var sup = ServiceRegistry.get_service("SupplierManager")
	if sup and data.has("suppliers"):
		sup.restore_save_data(data["suppliers"])
	var emp = ServiceRegistry.get_service("EmployeeManager")
	if emp and data.has("employees"):
		emp.restore_save_data(data["employees"])
	print("[WorldRoot] World state restored.")

func _on_time_changed(hour: int) -> void:
	var angle = (hour / 24.0) * TAU - PI * 0.5
	directional_light.rotation.x = angle
	var day_progress = GameClock.get_day_progress()
	if GameClock.is_daytime():
		var t = sin(day_progress * PI)
		directional_light.light_color = Color(
			lerp(0.9, 1.0, t), lerp(0.6, 0.95, t), lerp(0.4, 0.85, t))
		directional_light.light_energy = lerp(0.2, 1.3, t)
		# Update sky
		var env = environment_node.environment
		if env and env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
			sky_mat.sky_top_color = Color(lerp(0.05, 0.2, t), lerp(0.08, 0.4, t), lerp(0.2, 0.75, t))
			sky_mat.sky_horizon_color = Color(lerp(0.4, 0.6, t), lerp(0.3, 0.75, t), lerp(0.3, 0.85, t))
	else:
		# Night
		directional_light.light_color = Color(0.35, 0.38, 0.6)
		directional_light.light_energy = 0.12
		var env = environment_node.environment
		if env and env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
			sky_mat.sky_top_color = Color(0.02, 0.03, 0.08)
			sky_mat.sky_horizon_color = Color(0.05, 0.05, 0.12)

func _on_weather_changed(weather_type: String) -> void:
	var env = environment_node.environment
	if env == null:
		return
	match weather_type:
		"rain":
			env.fog_enabled = true
			env.fog_density = 0.012
			directional_light.light_energy *= 0.5
		"cloudy":
			env.fog_enabled = true
			env.fog_density = 0.005
		"clear":
			env.fog_enabled = false
			env.fog_density = 0.003

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameManager.current_mode == GameManager.GameMode.PAUSED:
			GameManager.resume_game()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if _pause_menu: _pause_menu.visible = false
		elif GameManager.current_mode == GameManager.GameMode.PLAYING:
			GameManager.pause_game()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			if _pause_menu: _pause_menu.visible = true
