extends Node3D
## SupermarketInterior — builds the full store geometry procedurally with PBR materials.

const STORE_WIDTH: float = 24.0
const STORE_DEPTH: float = 32.0
const STORE_HEIGHT: float = 4.5
const WALL_THICKNESS: float = 0.3

func _ready() -> void:
	_build_store()

func _build_store() -> void:
	_build_floor()
	_build_ceiling()
	_build_walls()
	_build_entrance()
	_build_shelving_rows()
	_build_checkout_area()
	_build_produce_section()
	_build_lighting()
	_build_signage()
	_build_navigation_region()

func _build_floor() -> void:
	var floor_sb = StaticBody3D.new()
	floor_sb.name = "Floor"
	floor_sb.collision_layer = 1
	var floor_mi = MeshInstance3D.new()
	var floor_mesh = PlaneMesh.new()
	floor_mesh.size = Vector2(STORE_WIDTH, STORE_DEPTH)
	floor_mi.mesh = floor_mesh
	floor_mi.position = Vector3(STORE_WIDTH * 0.5, 0, STORE_DEPTH * 0.5)
	# Tile material
	var mat = StandardMaterial3D.new()
	var img = Image.create(128, 128, false, Image.FORMAT_RGB8)
	for x in range(128):
		for y in range(128):
			var is_grout = (x % 32 <= 1) or (y % 32 <= 1)
			if is_grout:
				img.set_pixel(x, y, Color(0.65, 0.65, 0.63))
			else:
				var n = (sin(x * 0.3) * cos(y * 0.3)) * 0.02
				img.set_pixel(x, y, Color(0.92 + n, 0.91 + n, 0.88 + n))
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.roughness = 0.25
	mat.uv1_scale = Vector3(STORE_WIDTH * 0.5, STORE_DEPTH * 0.5, 1)
	floor_mi.set_surface_override_material(0, mat)
	var coll = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(STORE_WIDTH, 0.1, STORE_DEPTH)
	coll.shape = box
	coll.position = Vector3(STORE_WIDTH * 0.5, -0.05, STORE_DEPTH * 0.5)
	floor_sb.add_child(floor_mi)
	floor_sb.add_child(coll)
	add_child(floor_sb)

func _build_ceiling() -> void:
	var mi = MeshInstance3D.new()
	mi.name = "Ceiling"
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(STORE_WIDTH, STORE_DEPTH)
	mi.mesh = mesh
	mi.position = Vector3(STORE_WIDTH * 0.5, STORE_HEIGHT, STORE_DEPTH * 0.5)
	mi.rotation.x = PI
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 0.95)
	mat.roughness = 0.9
	mi.set_surface_override_material(0, mat)
	add_child(mi)

func _build_walls() -> void:
	var wall_mat = StandardMaterial3D.new()
	# Painted wall
	var img = Image.create(64, 64, false, Image.FORMAT_RGB8)
	for x in range(64):
		for y in range(64):
			var n = randf_range(-0.015, 0.015)
			img.set_pixel(x, y, Color(0.93 + n, 0.92 + n, 0.90 + n))
	wall_mat.albedo_texture = ImageTexture.create_from_image(img)
	wall_mat.roughness = 0.85

	# Back wall
	_add_wall(Vector3(STORE_WIDTH * 0.5, STORE_HEIGHT * 0.5, 0),
			  Vector3(STORE_WIDTH, STORE_HEIGHT, WALL_THICKNESS), wall_mat, "WallBack")
	# Left wall
	_add_wall(Vector3(0, STORE_HEIGHT * 0.5, STORE_DEPTH * 0.5),
			  Vector3(WALL_THICKNESS, STORE_HEIGHT, STORE_DEPTH), wall_mat, "WallLeft")
	# Right wall
	_add_wall(Vector3(STORE_WIDTH, STORE_HEIGHT * 0.5, STORE_DEPTH * 0.5),
			  Vector3(WALL_THICKNESS, STORE_HEIGHT, STORE_DEPTH), wall_mat, "WallRight")
	# Front wall left side (left of entrance)
	_add_wall(Vector3(4.0, STORE_HEIGHT * 0.5, STORE_DEPTH),
			  Vector3(8.0, STORE_HEIGHT, WALL_THICKNESS), wall_mat, "WallFrontLeft")
	# Front wall right side
	_add_wall(Vector3(20.0, STORE_HEIGHT * 0.5, STORE_DEPTH),
			  Vector3(8.0, STORE_HEIGHT, WALL_THICKNESS), wall_mat, "WallFrontRight")
	# Entrance header
	_add_wall(Vector3(12.0, STORE_HEIGHT - 0.5, STORE_DEPTH),
			  Vector3(8.0, 1.0, WALL_THICKNESS), wall_mat, "EntranceHeader")

func _add_wall(pos: Vector3, size: Vector3, mat: StandardMaterial3D, name_str: String) -> void:
	var sb = StaticBody3D.new()
	sb.name = name_str
	sb.collision_layer = 1
	var mi = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mi.mesh = box_mesh
	mi.set_surface_override_material(0, mat)
	sb.add_child(mi)
	var coll = CollisionShape3D.new()
	var cshape = BoxShape3D.new()
	cshape.size = size
	coll.shape = cshape
	sb.add_child(coll)
	sb.position = pos
	add_child(sb)

func _build_entrance() -> void:
	# Sliding glass doors (visual only)
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.7, 0.85, 0.9, 0.35)
	glass_mat.roughness = 0.05
	glass_mat.metallic = 0.1
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in range(2):
		var door_mi = MeshInstance3D.new()
		door_mi.name = "GlassDoor%d" % i
		var dm = BoxMesh.new()
		dm.size = Vector3(3.5, 3.0, 0.08)
		door_mi.mesh = dm
		door_mi.set_surface_override_material(0, glass_mat)
		door_mi.position = Vector3(9.5 + i * 4.5, 1.5, STORE_DEPTH - 0.1)
		add_child(door_mi)
	# Entrance marker
	var marker = Marker3D.new()
	marker.name = "EntranceMarker"
	marker.position = Vector3(STORE_WIDTH * 0.5, 0.1, STORE_DEPTH + 2.0)
	add_child(marker)

func _build_shelving_rows() -> void:
	# 4 rows of shelves, 3 shelves each
	var row_positions = [4.0, 7.5, 11.0, 14.5]
	var shelf_colors = [
		Color(0.85, 0.5, 0.2),   # produce - warm orange
		Color(0.3, 0.6, 0.9),    # dairy - blue
		Color(0.9, 0.3, 0.3),    # meat - red
		Color(0.7, 0.7, 0.7),    # general - grey
	]
	for row_idx in range(row_positions.size()):
		var row_x = row_positions[row_idx]
		for shelf_idx in range(3):
			var z = 4.0 + shelf_idx * 7.0
			_build_shelf_unit(Vector3(row_x, 0, z), shelf_colors[row_idx])

func _build_shelf_unit(pos: Vector3, product_color: Color) -> void:
	var shelf_root = Node3D.new()
	shelf_root.name = "Shelf_%s" % str(pos).replace(" ", "_")
	shelf_root.position = pos

	var metal_mat = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.72, 0.72, 0.74)
	metal_mat.metallic = 0.75
	metal_mat.roughness = 0.35

	# Frame uprights
	for side in [-1, 1]:
		var upright = MeshInstance3D.new()
		var um = BoxMesh.new()
		um.size = Vector3(0.05, 1.8, 0.05)
		upright.mesh = um
		upright.set_surface_override_material(0, metal_mat)
		upright.position = Vector3(side * 0.45, 0.9, 0)
		shelf_root.add_child(upright)
		var upright_b = upright.duplicate()
		upright_b.position = Vector3(side * 0.45, 0.9, -0.42)
		shelf_root.add_child(upright_b)

	# Shelving boards
	for level in range(4):
		var sh = MeshInstance3D.new()
		var sm = BoxMesh.new()
		sm.size = Vector3(0.95, 0.03, 0.45)
		sh.mesh = sm
		sh.set_surface_override_material(0, metal_mat)
		sh.position = Vector3(0, 0.3 + level * 0.5, -0.21)
		shelf_root.add_child(sh)
		# Products on each shelf
		if level < 3:
			_add_products_to_shelf(shelf_root, level, product_color)

	# Back panel
	var back = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.95, 1.8, 0.03)
	back.mesh = bm
	var back_mat = StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.95, 0.95, 0.95)
	back_mat.roughness = 0.8
	back.set_surface_override_material(0, back_mat)
	back.position = Vector3(0, 0.9, -0.44)
	shelf_root.add_child(back)

	# Collision for the whole shelf
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	var coll = CollisionShape3D.new()
	var cshape = BoxShape3D.new()
	cshape.size = Vector3(1.0, 1.9, 0.5)
	coll.shape = cshape
	coll.position = Vector3(0, 0.95, -0.21)
	sb.add_child(coll)
	shelf_root.add_child(sb)

	add_child(shelf_root)

func _add_products_to_shelf(parent: Node3D, level: int, color: Color) -> void:
	var product_mat = StandardMaterial3D.new()
	var img = Image.create(32, 32, false, Image.FORMAT_RGB8)
	for x in range(32):
		for y in range(32):
			if y >= 8 and y <= 24:
				img.set_pixel(x, y, Color(1, 1, 1))
			else:
				img.set_pixel(x, y, color)
	product_mat.albedo_texture = ImageTexture.create_from_image(img)
	product_mat.roughness = 0.6

	var product_shapes = [Vector3(0.08, 0.14, 0.06), Vector3(0.06, 0.18, 0.06), Vector3(0.1, 0.12, 0.08)]
	var count = randi_range(4, 8)
	for i in range(count):
		var prod = MeshInstance3D.new()
		var pm_shape = product_shapes[i % product_shapes.size()]
		var bm = BoxMesh.new()
		bm.size = pm_shape
		prod.mesh = bm
		prod.set_surface_override_material(0, product_mat)
		prod.position = Vector3(
			-0.38 + i * 0.1,
			0.33 + level * 0.5 + pm_shape.y * 0.5,
			-0.21
		)
		parent.add_child(prod)

func _build_checkout_area() -> void:
	var checkout_root = Node3D.new()
	checkout_root.name = "CheckoutArea"
	checkout_root.position = Vector3(STORE_WIDTH * 0.5, 0, STORE_DEPTH - 5.0)
	add_child(checkout_root)

	# 2 checkout counters
	for i in range(2):
		var counter_x = -3.5 + i * 7.0
		_build_checkout_counter(checkout_root, Vector3(counter_x, 0, 0), i)

	# Dividers / queue barriers
	var barrier_mat = StandardMaterial3D.new()
	barrier_mat.albedo_color = Color(0.6, 0.5, 0.2)
	barrier_mat.roughness = 0.6
	for i in range(3):
		var bar = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.05, 0.9, 2.5)
		bar.mesh = bm
		bar.set_surface_override_material(0, barrier_mat)
		bar.position = Vector3(-7.0 + i * 7.0, 0.45, 0)
		checkout_root.add_child(bar)

func _build_checkout_counter(parent: Node3D, pos: Vector3, idx: int) -> void:
	var counter_sb = StaticBody3D.new()
	counter_sb.name = "CheckoutCounter%d" % idx
	counter_sb.collision_layer = 1

	var counter_mat = StandardMaterial3D.new()
	counter_mat.albedo_color = Color(0.4, 0.38, 0.35)
	counter_mat.roughness = 0.4
	counter_mat.metallic = 0.1

	# Main counter body
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(1.4, 0.95, 0.75)
	body.mesh = bm
	body.set_surface_override_material(0, counter_mat)
	body.position = Vector3(0, 0.475, 0)
	counter_sb.add_child(body)

	# Conveyor belt surface
	var belt = MeshInstance3D.new()
	var belt_m = BoxMesh.new()
	belt_m.size = Vector3(1.2, 0.05, 0.6)
	belt.mesh = belt_m
	var belt_mat = StandardMaterial3D.new()
	belt_mat.albedo_color = Color(0.2, 0.2, 0.2)
	belt_mat.roughness = 0.9
	belt.set_surface_override_material(0, belt_mat)
	belt.position = Vector3(-0.1, 0.975, 0)
	counter_sb.add_child(belt)

	# Screen/register
	var screen = MeshInstance3D.new()
	var sm = BoxMesh.new()
	sm.size = Vector3(0.3, 0.4, 0.05)
	screen.mesh = sm
	var screen_mat = StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.1, 0.4, 0.1)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.0, 0.5, 0.0)
	screen_mat.emission_energy_multiplier = 0.8
	screen.set_surface_override_material(0, screen_mat)
	screen.position = Vector3(0.5, 1.4, 0)
	screen.rotation.x = -0.3
	counter_sb.add_child(screen)

	# Collision
	var coll = CollisionShape3D.new()
	var cshape = BoxShape3D.new()
	cshape.size = Vector3(1.4, 0.95, 0.75)
	coll.shape = cshape
	coll.position = Vector3(0, 0.475, 0)
	counter_sb.add_child(coll)

	# Make interactable
	counter_sb.set_script(load("res://scenes/supermarket/checkout_interactable.gd"))
	counter_sb.set_meta("checkout_index", idx)

	counter_sb.position = pos
	parent.add_child(counter_sb)

func _build_produce_section() -> void:
	var produce_root = Node3D.new()
	produce_root.name = "ProduceSection"
	produce_root.position = Vector3(1.5, 0, 4.0)
	add_child(produce_root)

	# Produce stands with angled displays
	var produce_colors = [
		Color(1.0, 0.3, 0.1),  # tomatoes/apples
		Color(1.0, 0.85, 0.1), # bananas/lemons
		Color(0.3, 0.75, 0.2), # lettuce
		Color(0.9, 0.5, 0.1),  # oranges
	]
	for i in range(4):
		var stand = Node3D.new()
		stand.name = "ProduceStand%d" % i
		stand.position = Vector3(i * 1.6, 0, 0)
		# Stand body
		var body = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(1.4, 0.8, 0.9)
		body.mesh = bm
		var wood_mat = StandardMaterial3D.new()
		wood_mat.albedo_color = Color(0.55, 0.38, 0.18)
		wood_mat.roughness = 0.8
		body.set_surface_override_material(0, wood_mat)
		body.position = Vector3(0, 0.4, 0)
		stand.add_child(body)
		# Display surface
		var disp = MeshInstance3D.new()
		var dm = BoxMesh.new()
		dm.size = Vector3(1.3, 0.05, 0.75)
		disp.mesh = dm
		var disp_mat = StandardMaterial3D.new()
		disp_mat.albedo_color = produce_colors[i]
		disp_mat.roughness = 0.7
		disp.set_surface_override_material(0, disp_mat)
		disp.position = Vector3(0, 0.825, 0)
		disp.rotation.z = -0.15
		stand.add_child(disp)
		produce_root.add_child(stand)

func _build_lighting() -> void:
	var lights_root = Node3D.new()
	lights_root.name = "Lighting"
	add_child(lights_root)

	# Ceiling panel lights
	var rows = 4
	var cols = 3
	for r in range(rows):
		for c in range(cols):
			var light_node = Node3D.new()
			var lx = 3.0 + r * (STORE_WIDTH - 6.0) / (rows - 1)
			var lz = 4.0 + c * (STORE_DEPTH - 8.0) / (cols - 1)
			light_node.position = Vector3(lx, STORE_HEIGHT - 0.1, lz)

			# Light fixture mesh
			var fixture_mi = MeshInstance3D.new()
			var fm = BoxMesh.new()
			fm.size = Vector3(1.2, 0.08, 0.3)
			fixture_mi.mesh = fm
			var fix_mat = StandardMaterial3D.new()
			fix_mat.albedo_color = Color(1, 1, 0.95)
			fix_mat.emission_enabled = true
			fix_mat.emission = Color(1, 1, 0.9)
			fix_mat.emission_energy_multiplier = 1.5
			fixture_mi.set_surface_override_material(0, fix_mat)
			light_node.add_child(fixture_mi)

			# Actual OmniLight
			var omni = OmniLight3D.new()
			omni.light_color = Color(1.0, 0.98, 0.92)
			omni.light_energy = 1.2
			omni.omni_range = 8.0
			omni.shadow_enabled = false
			omni.position = Vector3(0, -0.1, 0)
			light_node.add_child(omni)
			lights_root.add_child(light_node)

	# Exit sign above entrance
	var exit_sign = MeshInstance3D.new()
	var em = BoxMesh.new()
	em.size = Vector3(1.2, 0.3, 0.1)
	exit_sign.mesh = em
	var exit_mat = StandardMaterial3D.new()
	exit_mat.albedo_color = Color(0.1, 0.8, 0.1)
	exit_mat.emission_enabled = true
	exit_mat.emission = Color(0.0, 1.0, 0.0)
	exit_mat.emission_energy_multiplier = 2.0
	exit_sign.set_surface_override_material(0, exit_mat)
	exit_sign.position = Vector3(STORE_WIDTH * 0.5, STORE_HEIGHT - 0.5, STORE_DEPTH - 0.2)
	lights_root.add_child(exit_sign)

func _build_signage() -> void:
	var sign_root = Node3D.new()
	sign_root.name = "Signage"
	add_child(sign_root)

	# Aisle signs hanging from ceiling
	var aisle_labels = ["Fruits & Veg", "Dairy", "Meat & Fish", "Pantry"]
	var aisle_positions = [4.0, 7.5, 11.0, 14.5]
	for i in range(aisle_labels.size()):
		var sign = MeshInstance3D.new()
		var sm = BoxMesh.new()
		sm.size = Vector3(1.5, 0.4, 0.05)
		sign.mesh = sm
		var smat = StandardMaterial3D.new()
		smat.albedo_color = Color(0.15, 0.4, 0.15)
		smat.emission_enabled = true
		smat.emission = Color(0.1, 0.4, 0.1)
		smat.emission_energy_multiplier = 0.5
		sign.set_surface_override_material(0, smat)
		sign.position = Vector3(aisle_positions[i], STORE_HEIGHT - 0.5, STORE_DEPTH * 0.5)
		sign_root.add_child(sign)

	# Fresh Mart store sign at entrance
	var store_sign = MeshInstance3D.new()
	var ssm = BoxMesh.new()
	ssm.size = Vector3(5.0, 0.8, 0.15)
	store_sign.mesh = ssm
	var ssmat = StandardMaterial3D.new()
	ssmat.albedo_color = Color(0.1, 0.5, 0.1)
	ssmat.emission_enabled = true
	ssmat.emission = Color(0.2, 0.9, 0.2)
	ssmat.emission_energy_multiplier = 1.0
	store_sign.set_surface_override_material(0, ssmat)
	store_sign.position = Vector3(STORE_WIDTH * 0.5, STORE_HEIGHT + 0.5, STORE_DEPTH + 0.3)
	sign_root.add_child(store_sign)

func _build_navigation_region() -> void:
	var nav = NavigationRegion3D.new()
	nav.name = "NavigationRegion3D"
	var nav_mesh = NavigationMesh.new()
	nav_mesh.agent_height = 1.8
	nav_mesh.agent_radius = 0.4
	nav_mesh.agent_max_climb = 0.3
	nav_mesh.agent_max_slope = 45.0
	nav.navigation_mesh = nav_mesh
	add_child(nav)
	# Bake at runtime
	nav.bake_navigation_mesh.call_deferred()
