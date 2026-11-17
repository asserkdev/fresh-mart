extends Node3D
## Downtown chunk — procedurally built city block with buildings, roads, sidewalks.

const CHUNK_SIZE: float = 64.0

func _ready() -> void:
	_build_road_network()
	_build_buildings()
	_build_sidewalks()
	_build_street_furniture()
	_build_vegetation()

func _build_road_network() -> void:
	# Main road (horizontal)
	_add_road_segment(Vector3(CHUNK_SIZE * 0.5, 0.01, CHUNK_SIZE * 0.5),
					  Vector2(CHUNK_SIZE, 7.0))
	# Cross road (vertical)
	_add_road_segment(Vector3(CHUNK_SIZE * 0.5, 0.01, CHUNK_SIZE * 0.5),
					  Vector2(7.0, CHUNK_SIZE), 0.0)
	# Pavement markings
	_add_crosswalk(Vector3(CHUNK_SIZE * 0.5, 0.02, CHUNK_SIZE * 0.5 - 10))
	_add_crosswalk(Vector3(CHUNK_SIZE * 0.5 + 10, 0.02, CHUNK_SIZE * 0.5))

func _add_road_segment(pos: Vector3, size: Vector2, _rot: float = 0.0) -> void:
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	var mi = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	var mat = StandardMaterial3D.new()
	var img = Image.create(64, 64, false, Image.FORMAT_RGB8)
	for x in range(64):
		for y in range(64):
			var n = randf_range(-0.03, 0.03)
			img.set_pixel(x, y, Color(0.22 + n, 0.22 + n, 0.22 + n))
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.roughness = 0.95
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	sb.add_child(mi)
	var coll = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(size.x, 0.05, size.y)
	coll.shape = box
	coll.position = pos + Vector3(0, -0.025, 0)
	sb.add_child(coll)
	add_child(sb)

func _add_crosswalk(pos: Vector3) -> void:
	for i in range(5):
		var stripe = MeshInstance3D.new()
		var pm = PlaneMesh.new()
		pm.size = Vector2(0.6, 4.5)
		stripe.mesh = pm
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.95, 0.95, 0.95)
		mat.roughness = 0.8
		stripe.set_surface_override_material(0, mat)
		stripe.position = pos + Vector3(-1.2 + i * 0.6, 0, 0)
		add_child(stripe)

func _build_sidewalks() -> void:
	var sw_mat = StandardMaterial3D.new()
	var img = Image.create(64, 64, false, Image.FORMAT_RGB8)
	for x in range(64):
		for y in range(64):
			var is_line = (x % 16 == 0 or y % 16 == 0)
			var n = randf_range(-0.02, 0.02)
			if is_line:
				img.set_pixel(x, y, Color(0.65 + n, 0.65 + n, 0.63 + n))
			else:
				img.set_pixel(x, y, Color(0.78 + n, 0.77 + n, 0.75 + n))
	sw_mat.albedo_texture = ImageTexture.create_from_image(img)
	sw_mat.roughness = 0.85

	# Sidewalks around road intersections
	var sw_configs = [
		[Vector3(CHUNK_SIZE * 0.5, 0.05, 8), Vector2(CHUNK_SIZE, 3)],
		[Vector3(CHUNK_SIZE * 0.5, 0.05, CHUNK_SIZE - 8), Vector2(CHUNK_SIZE, 3)],
		[Vector3(8, 0.05, CHUNK_SIZE * 0.5), Vector2(3, CHUNK_SIZE)],
		[Vector3(CHUNK_SIZE - 8, 0.05, CHUNK_SIZE * 0.5), Vector2(3, CHUNK_SIZE)],
	]
	for cfg in sw_configs:
		var sb = StaticBody3D.new()
		sb.collision_layer = 1
		var mi = MeshInstance3D.new()
		var pm = PlaneMesh.new()
		pm.size = cfg[1]
		mi.mesh = pm
		mi.set_surface_override_material(0, sw_mat)
		mi.position = cfg[0]
		sb.add_child(mi)
		var coll = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(cfg[1].x, 0.05, cfg[1].y)
		coll.shape = box
		coll.position = cfg[0] + Vector3(0, -0.025, 0)
		sb.add_child(coll)
		add_child(sb)

func _build_buildings() -> void:
	# Building in each quadrant of the chunk
	var building_configs = [
		{"pos": Vector3(16, 0, 16), "size": Vector3(14, 12, 14), "type": "office"},
		{"pos": Vector3(48, 0, 16), "size": Vector3(14, 8, 14), "type": "shop"},
		{"pos": Vector3(16, 0, 48), "size": Vector3(14, 16, 14), "type": "apartment"},
		{"pos": Vector3(48, 0, 48), "size": Vector3(14, 10, 14), "type": "shop"},
	]
	for cfg in building_configs:
		_build_building(cfg["pos"], cfg["size"], cfg["type"])

func _build_building(pos: Vector3, size: Vector3, building_type: String) -> void:
	var building_root = Node3D.new()
	building_root.name = "Building_%s_%s" % [building_type, str(pos.x)]
	building_root.position = pos
	add_child(building_root)

	# Wall material
	var wall_mat = StandardMaterial3D.new()
	var wall_colors = {"office": Color(0.75, 0.78, 0.82), "shop": Color(0.85, 0.75, 0.6), "apartment": Color(0.72, 0.68, 0.62)}
	wall_mat.albedo_color = wall_colors.get(building_type, Color(0.75, 0.73, 0.70))
	# Brick texture
	var img = Image.create(128, 64, false, Image.FORMAT_RGB8)
	var brick_col = wall_colors.get(building_type, Color(0.75, 0.73, 0.70))
	var mortar = Color(brick_col.r * 0.75, brick_col.g * 0.75, brick_col.b * 0.75)
	for x in range(128):
		for y in range(64):
			var row = y / 10
			var offset = 32 if (row % 2 == 0) else 0
			var col_in_row = (x + offset) % 64
			var is_mortar = (y % 10 == 0 or y % 10 == 9 or col_in_row < 2 or col_in_row > 61)
			if is_mortar:
				img.set_pixel(x, y, mortar)
			else:
				var n = randf_range(-0.02, 0.02)
				img.set_pixel(x, y, Color(brick_col.r + n, brick_col.g + n, brick_col.b + n))
	wall_mat.albedo_texture = ImageTexture.create_from_image(img)
	wall_mat.roughness = 0.85

	# Main building body (hollow — just outer walls + roof)
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	# Walls
	var wall_configs = [
		[Vector3(0, size.y * 0.5, -size.z * 0.5), Vector3(size.x, size.y, 0.3)],  # front
		[Vector3(0, size.y * 0.5, size.z * 0.5), Vector3(size.x, size.y, 0.3)],   # back
		[Vector3(-size.x * 0.5, size.y * 0.5, 0), Vector3(0.3, size.y, size.z)],  # left
		[Vector3(size.x * 0.5, size.y * 0.5, 0), Vector3(0.3, size.y, size.z)],   # right
	]
	for wc in wall_configs:
		var wmi = MeshInstance3D.new()
		var wm = BoxMesh.new()
		wm.size = wc[1]
		wmi.mesh = wm
		wmi.set_surface_override_material(0, wall_mat)
		wmi.position = wc[0]
		sb.add_child(wmi)
		var wcoll = CollisionShape3D.new()
		var wcs = BoxShape3D.new()
		wcs.size = wc[1]
		wcoll.shape = wcs
		wcoll.position = wc[0]
		sb.add_child(wcoll)
	# Roof
	var roof = MeshInstance3D.new()
	var rm = BoxMesh.new()
	rm.size = Vector3(size.x + 0.4, 0.3, size.z + 0.4)
	roof.mesh = rm
	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.25, 0.25, 0.28)
	roof_mat.roughness = 0.95
	roof.set_surface_override_material(0, roof_mat)
	roof.position = Vector3(0, size.y + 0.15, 0)
	sb.add_child(roof)
	building_root.add_child(sb)

	# Windows
	_add_windows(building_root, size, wall_mat)

	# Door
	_add_door(building_root, size)

func _add_windows(parent: Node3D, size: Vector3, _wall_mat: StandardMaterial3D) -> void:
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.6, 0.75, 0.85, 0.4)
	glass_mat.roughness = 0.05
	glass_mat.metallic = 0.1
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.9, 0.9, 0.9)
	frame_mat.roughness = 0.3

	var floors = int(size.y / 3.5)
	for floor_i in range(1, floors):
		for side in [-1, 1]:
			for window_i in range(2):
				var win_root = Node3D.new()
				# Window frame
				var frame = MeshInstance3D.new()
				var fm = BoxMesh.new()
				fm.size = Vector3(1.2, 1.4, 0.08)
				frame.mesh = fm
				frame.set_surface_override_material(0, frame_mat)
				win_root.add_child(frame)
				# Glass pane
				var glass = MeshInstance3D.new()
				var gm = BoxMesh.new()
				gm.size = Vector3(1.0, 1.2, 0.04)
				glass.mesh = gm
				glass.set_surface_override_material(0, glass_mat)
				win_root.add_child(glass)
				win_root.position = Vector3(
					side * size.x * 0.3 + (window_i - 0.5) * 2.5,
					floor_i * 3.0 + 1.0,
					-size.z * 0.5 - 0.05
				)
				parent.add_child(win_root)

func _add_door(parent: Node3D, size: Vector3) -> void:
	var door_mat = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.35, 0.28, 0.2)
	door_mat.roughness = 0.7
	var door = MeshInstance3D.new()
	var dm = BoxMesh.new()
	dm.size = Vector3(1.1, 2.2, 0.1)
	door.mesh = dm
	door.set_surface_override_material(0, door_mat)
	door.position = Vector3(0, 1.1, -size.z * 0.5 - 0.05)
	parent.add_child(door)

func _build_street_furniture() -> void:
	# Street lights
	var light_positions = [
		Vector3(9.5, 0, 9.5), Vector3(9.5, 0, 54.5),
		Vector3(54.5, 0, 9.5), Vector3(54.5, 0, 54.5),
	]
	for lp in light_positions:
		_build_street_light(lp)
	# Benches
	_build_bench(Vector3(13, 0, 13))
	_build_bench(Vector3(51, 0, 13))

func _build_street_light(pos: Vector3) -> void:
	var light_root = Node3D.new()
	light_root.position = pos
	# Pole
	var pole = MeshInstance3D.new()
	var pm = CylinderMesh.new()
	pm.top_radius = 0.05
	pm.bottom_radius = 0.08
	pm.height = 5.0
	pole.mesh = pm
	var pole_mat = StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.35, 0.35, 0.37)
	pole_mat.metallic = 0.6
	pole_mat.roughness = 0.4
	pole.set_surface_override_material(0, pole_mat)
	pole.position = Vector3(0, 2.5, 0)
	light_root.add_child(pole)
	# Lamp housing
	var lamp = MeshInstance3D.new()
	var lm = SphereMesh.new()
	lm.radius = 0.2
	lm.height = 0.4
	lamp.mesh = lm
	var lamp_mat = StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(1, 1, 0.8)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1, 0.95, 0.7)
	lamp_mat.emission_energy_multiplier = 3.0
	lamp.set_surface_override_material(0, lamp_mat)
	lamp.position = Vector3(0.3, 5.1, 0)
	light_root.add_child(lamp)
	# Actual light
	var omni = OmniLight3D.new()
	omni.light_color = Color(1.0, 0.95, 0.75)
	omni.light_energy = 2.0
	omni.omni_range = 12.0
	omni.shadow_enabled = false
	omni.position = Vector3(0.3, 5.1, 0)
	light_root.add_child(omni)
	add_child(light_root)

func _build_bench(pos: Vector3) -> void:
	var bench = Node3D.new()
	bench.position = pos
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.52, 0.36, 0.18)
	wood_mat.roughness = 0.8
	var metal_mat = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.5, 0.5, 0.52)
	metal_mat.metallic = 0.7
	metal_mat.roughness = 0.4
	# Seat slats
	for i in range(4):
		var slat = MeshInstance3D.new()
		var sm = BoxMesh.new()
		sm.size = Vector3(1.4, 0.05, 0.12)
		slat.mesh = sm
		slat.set_surface_override_material(0, wood_mat)
		slat.position = Vector3(0, 0.45, -0.18 + i * 0.12)
		bench.add_child(slat)
	# Legs
	for lx in [-0.6, 0.6]:
		var leg = MeshInstance3D.new()
		var lm = BoxMesh.new()
		lm.size = Vector3(0.06, 0.45, 0.4)
		leg.mesh = lm
		leg.set_surface_override_material(0, metal_mat)
		leg.position = Vector3(lx, 0.225, 0)
		bench.add_child(leg)
	add_child(bench)

func _build_vegetation() -> void:
	var tree_positions = [
		Vector3(12, 0, 12), Vector3(52, 0, 12),
		Vector3(12, 0, 52), Vector3(52, 0, 52),
	]
	for tp in tree_positions:
		_build_tree(tp)
	# Grass patches
	for _i in range(6):
		_build_grass_patch(Vector3(randf_range(5, 59), 0.01, randf_range(5, 59)))

func _build_tree(pos: Vector3) -> void:
	var tree_root = Node3D.new()
	tree_root.position = pos
	# Trunk
	var trunk = MeshInstance3D.new()
	var tm = CylinderMesh.new()
	tm.top_radius = 0.12
	tm.bottom_radius = 0.18
	tm.height = 2.5
	trunk.mesh = tm
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.38, 0.26, 0.12)
	trunk_mat.roughness = 0.95
	trunk.set_surface_override_material(0, trunk_mat)
	trunk.position = Vector3(0, 1.25, 0)
	tree_root.add_child(trunk)
	# Canopy layers
	var canopy_colors = [Color(0.15, 0.5, 0.1), Color(0.2, 0.55, 0.12), Color(0.12, 0.42, 0.08)]
	for i in range(3):
		var canopy = MeshInstance3D.new()
		var cm = SphereMesh.new()
		cm.radius = 1.5 - i * 0.2
		cm.height = 2.0 - i * 0.3
		canopy.mesh = cm
		var cm_mat = StandardMaterial3D.new()
		cm_mat.albedo_color = canopy_colors[i]
		cm_mat.roughness = 0.9
		canopy.set_surface_override_material(0, cm_mat)
		canopy.position = Vector3(0, 3.5 + i * 0.4, 0)
		tree_root.add_child(canopy)
	add_child(tree_root)

func _build_grass_patch(pos: Vector3) -> void:
	var patch = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(randf_range(2, 5), randf_range(2, 5))
	patch.mesh = pm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25 + randf_range(-0.03, 0.03), 0.5, 0.18)
	mat.roughness = 0.95
	patch.set_surface_override_material(0, mat)
	patch.position = pos
	add_child(patch)
