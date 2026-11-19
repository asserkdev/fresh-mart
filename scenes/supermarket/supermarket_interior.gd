extends Node3D
## SupermarketInterior — professional quality 3D store with PBR materials.

const STORE_W: float = 28.0
const STORE_D: float = 36.0
const STORE_H: float = 5.2
const WALL_T: float = 0.25

var _mats: Dictionary = {}

func _ready() -> void:
	_build_materials()
	_build_store()

func _build_materials() -> void:
	# White floor tile
	var tile = StandardMaterial3D.new()
	var tile_img = Image.create(256, 256, false, Image.FORMAT_RGB8)
	for x in range(256):
		for y in range(256):
			var grout = (x % 64 <= 2) or (y % 64 <= 2)
			var n = randf_range(-0.02, 0.02)
			if grout:
				tile_img.set_pixel(x, y, Color(0.62+n, 0.62+n, 0.60+n))
			else:
				tile_img.set_pixel(x, y, Color(0.90+n, 0.90+n, 0.88+n))
	tile.albedo_texture = ImageTexture.create_from_image(tile_img)
	tile.roughness = 0.18
	tile.metallic = 0.05
	_mats["floor"] = tile

	# Wall paint — off-white
	var wall = StandardMaterial3D.new()
	wall.albedo_color = Color(0.93, 0.92, 0.90)
	wall.roughness = 0.88
	_mats["wall"] = wall

	# Accent wall — green stripe
	var accent = StandardMaterial3D.new()
	accent.albedo_color = Color(0.18, 0.52, 0.22)
	accent.roughness = 0.75
	_mats["wall_accent"] = accent

	# Ceiling tiles
	var ceiling = StandardMaterial3D.new()
	ceiling.albedo_color = Color(0.95, 0.95, 0.95)
	ceiling.roughness = 0.92
	_mats["ceiling"] = ceiling

	# Metal shelf frame
	var metal = StandardMaterial3D.new()
	metal.albedo_color = Color(0.68, 0.68, 0.70)
	metal.metallic = 0.82
	metal.roughness = 0.28
	_mats["metal"] = metal

	# White shelf board
	var shelf_board = StandardMaterial3D.new()
	shelf_board.albedo_color = Color(0.95, 0.94, 0.92)
	shelf_board.roughness = 0.65
	_mats["shelf_board"] = shelf_board

	# Checkout counter — dark grey composite
	var counter = StandardMaterial3D.new()
	var ctr_img = Image.create(64, 64, false, Image.FORMAT_RGB8)
	for x in range(64):
		for y in range(64):
			var n = randf_range(-0.015, 0.015)
			ctr_img.set_pixel(x, y, Color(0.28+n, 0.28+n, 0.30+n))
	counter.albedo_texture = ImageTexture.create_from_image(ctr_img)
	counter.roughness = 0.35
	counter.metallic = 0.05
	_mats["counter"] = counter

	# Glass (entrance doors)
	var glass = StandardMaterial3D.new()
	glass.albedo_color = Color(0.72, 0.85, 0.90, 0.25)
	glass.roughness = 0.04
	glass.metallic = 0.12
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats["glass"] = glass

	# Produce crate wood
	var wood = StandardMaterial3D.new()
	wood.albedo_color = Color(0.58, 0.40, 0.20)
	wood.roughness = 0.82
	_mats["wood"] = wood

	# Red product label
	var prod_colors = [
		Color(0.85, 0.20, 0.18), Color(0.18, 0.55, 0.85),
		Color(0.20, 0.72, 0.28), Color(0.95, 0.70, 0.08),
		Color(0.72, 0.18, 0.72), Color(0.18, 0.72, 0.65),
	]
	for i in range(prod_colors.size()):
		var pm = StandardMaterial3D.new()
		var pimg = Image.create(64, 64, false, Image.FORMAT_RGB8)
		for x in range(64):
			for y in range(64):
				if y >= 16 and y <= 48:
					pimg.set_pixel(x, y, Color(1.0, 1.0, 1.0))
				else:
					pimg.set_pixel(x, y, prod_colors[i])
		pm.albedo_texture = ImageTexture.create_from_image(pimg)
		pm.roughness = 0.55
		_mats["product_%d" % i] = pm

	# Rubber conveyor belt
	var belt = StandardMaterial3D.new()
	belt.albedo_color = Color(0.15, 0.15, 0.15)
	belt.roughness = 0.95
	_mats["belt"] = belt

	# Bright LED screen
	var screen = StandardMaterial3D.new()
	screen.albedo_color = Color(0.05, 0.60, 0.15)
	screen.emission_enabled = true
	screen.emission = Color(0.0, 0.8, 0.2)
	screen.emission_energy_multiplier = 1.5
	_mats["screen"] = screen

	# Green accent stripe for signage
	var sign_green = StandardMaterial3D.new()
	sign_green.albedo_color = Color(0.15, 0.60, 0.20)
	sign_green.emission_enabled = true
	sign_green.emission = Color(0.08, 0.45, 0.12)
	sign_green.emission_energy_multiplier = 0.8
	_mats["sign"] = sign_green

	# Ceiling light panel
	var light_panel = StandardMaterial3D.new()
	light_panel.albedo_color = Color(1.0, 1.0, 0.98)
	light_panel.emission_enabled = true
	light_panel.emission = Color(1.0, 0.98, 0.92)
	light_panel.emission_energy_multiplier = 2.0
	_mats["light_panel"] = light_panel

	# Entrance mat
	var mat_e = StandardMaterial3D.new()
	mat_e.albedo_color = Color(0.15, 0.40, 0.18)
	mat_e.roughness = 0.95
	_mats["entrance_mat"] = mat_e

func _build_store() -> void:
	_build_floor()
	_build_ceiling_grid()
	_build_walls()
	_build_entrance_area()
	_build_produce_wall()
	_build_shelf_rows()
	_build_dairy_cooler()
	_build_checkout_lanes()
	_build_service_desk()
	_build_ceiling_lights()
	_build_signage()
	_build_nav_region()

# ============================================================
func _build_floor() -> void:
	var sb = StaticBody3D.new(); sb.name = "Floor"; sb.collision_layer = 1
	var mi = MeshInstance3D.new()
	var pm = PlaneMesh.new(); pm.size = Vector2(STORE_W, STORE_D)
	mi.mesh = pm; mi.position = Vector3(STORE_W*0.5, 0.0, STORE_D*0.5)
	mi.set_surface_override_material(0, _mats["floor"])
	var coll = CollisionShape3D.new()
	var bs = BoxShape3D.new(); bs.size = Vector3(STORE_W, 0.1, STORE_D)
	coll.shape = bs; coll.position = Vector3(STORE_W*0.5, -0.05, STORE_D*0.5)
	sb.add_child(mi); sb.add_child(coll); add_child(sb)
	# Entrance mat
	var em = MeshInstance3D.new()
	var epm = PlaneMesh.new(); epm.size = Vector2(8.0, 2.0)
	em.mesh = epm; em.position = Vector3(STORE_W*0.5, 0.005, STORE_D-1.0)
	em.set_surface_override_material(0, _mats["entrance_mat"]); add_child(em)

func _build_ceiling_grid() -> void:
	# Main ceiling
	var mi = MeshInstance3D.new()
	var pm = PlaneMesh.new(); pm.size = Vector2(STORE_W, STORE_D)
	mi.mesh = pm; mi.position = Vector3(STORE_W*0.5, STORE_H, STORE_D*0.5)
	mi.rotation.x = PI
	mi.set_surface_override_material(0, _mats["ceiling"]); add_child(mi)
	# Drop ceiling grid lines
	var grid_mat = StandardMaterial3D.new()
	grid_mat.albedo_color = Color(0.72, 0.72, 0.72); grid_mat.roughness = 0.9
	for x in range(1, int(STORE_W / 1.2)):
		var bar = MeshInstance3D.new()
		var bm = BoxMesh.new(); bm.size = Vector3(0.04, 0.04, STORE_D)
		bar.mesh = bm; bar.position = Vector3(x * 1.2, STORE_H - 0.02, STORE_D*0.5)
		bar.set_surface_override_material(0, grid_mat); add_child(bar)

func _build_walls() -> void:
	var walls = [
		# Back wall
		[Vector3(STORE_W*0.5, STORE_H*0.5, 0), Vector3(STORE_W, STORE_H, WALL_T), "wall"],
		# Left wall
		[Vector3(0, STORE_H*0.5, STORE_D*0.5), Vector3(WALL_T, STORE_H, STORE_D), "wall"],
		# Right wall
		[Vector3(STORE_W, STORE_H*0.5, STORE_D*0.5), Vector3(WALL_T, STORE_H, STORE_D), "wall"],
		# Front left panel
		[Vector3(4.0, STORE_H*0.5, STORE_D), Vector3(8.0, STORE_H, WALL_T), "wall"],
		# Front right panel
		[Vector3(STORE_W-4.0, STORE_H*0.5, STORE_D), Vector3(8.0, STORE_H, WALL_T), "wall"],
		# Entrance header
		[Vector3(STORE_W*0.5, STORE_H-0.6, STORE_D), Vector3(12.0, 1.2, WALL_T), "wall"],
		# Green accent stripe — lower back wall
		[Vector3(STORE_W*0.5, 0.6, 0.12), Vector3(STORE_W, 1.2, 0.08), "wall_accent"],
	]
	for w in walls:
		var sb = StaticBody3D.new(); sb.collision_layer = 1
		var mi = MeshInstance3D.new()
		var bm = BoxMesh.new(); bm.size = w[1]
		mi.mesh = bm; mi.set_surface_override_material(0, _mats[w[2]])
		var cs = CollisionShape3D.new()
		var bs = BoxShape3D.new(); bs.size = w[1]; cs.shape = bs
		sb.add_child(mi); sb.add_child(cs); sb.position = w[0]; add_child(sb)

func _build_entrance_area() -> void:
	# Glass automatic doors
	for i in range(2):
		var door = MeshInstance3D.new()
		var dm = BoxMesh.new(); dm.size = Vector3(3.6, 3.4, 0.08)
		door.mesh = dm
		door.set_surface_override_material(0, _mats["glass"])
		door.position = Vector3(10.0 + i*5.0, 1.7, STORE_D - 0.04); add_child(door)
		# Aluminium door frame
		for side in [-1, 1]:
			var frame = MeshInstance3D.new()
			var fm = BoxMesh.new(); fm.size = Vector3(0.10, 3.5, 0.12)
			frame.mesh = fm
			var fm_mat = StandardMaterial3D.new()
			fm_mat.albedo_color = Color(0.75, 0.75, 0.78); fm_mat.metallic = 0.75; fm_mat.roughness = 0.25
			frame.set_surface_override_material(0, fm_mat)
			frame.position = Vector3(10.0 + i*5.0 + side*1.85, 1.75, STORE_D - 0.04); add_child(frame)
	# Entrance marker
	var marker = Marker3D.new(); marker.name = "EntranceMarker"
	marker.position = Vector3(STORE_W*0.5, 0.1, STORE_D + 1.5); add_child(marker)
	# Security sensor pillars
	for px in [STORE_W*0.5 - 5.5, STORE_W*0.5 + 5.5]:
		var pillar = MeshInstance3D.new()
		var pillar_mesh = BoxMesh.new(); pillar_mesh.size = Vector3(0.14, 1.6, 0.14)
		pillar.mesh = pillar_mesh
		var pm_mat = StandardMaterial3D.new()
		pm_mat.albedo_color = Color(0.30, 0.30, 0.32); pm_mat.metallic = 0.6; pm_mat.roughness = 0.3
		pillar.set_surface_override_material(0, pm_mat)
		pillar.position = Vector3(px, 0.8, STORE_D - 0.5); add_child(pillar)

func _build_produce_wall() -> void:
	# Left wall: fresh produce display along back-left
	var base_z = 2.0
	var produce_items = [
		{"color": Color(0.95, 0.20, 0.08), "name": "Tomatoes", "pid": "veg_tomato"},
		{"color": Color(1.00, 0.85, 0.05), "name": "Bananas",  "pid": "fruit_banana"},
		{"color": Color(0.98, 0.45, 0.08), "name": "Oranges",  "pid": "fruit_orange"},
		{"color": Color(0.92, 0.18, 0.18), "name": "Apples",   "pid": "fruit_apple"},
		{"color": Color(0.25, 0.70, 0.22), "name": "Lettuce",  "pid": "veg_lettuce"},
		{"color": Color(0.80, 0.55, 0.18), "name": "Potatoes", "pid": "veg_potato"},
	]
	for i in range(produce_items.size()):
		var item = produce_items[i]
		var z = base_z + i * 2.8
		_build_produce_bin(Vector3(1.4, 0, z), item["color"], item["name"], item["pid"])

func _build_produce_bin(pos: Vector3, color: Color, label: String, pid: String) -> void:
	var root = Node3D.new(); root.name = "ProduceBin_%s" % pid
	root.position = pos

	# Attach shelf interactable
	var interactable = load("res://scenes/supermarket/shelf_interactable.gd")
	if interactable:
		root.set_script(interactable)
		root.set("shelf_id", "produce_%s" % pid)
		root.set("shelf_capacity", 30)
		root.set("assigned_product_id", pid)

	# Wooden crate base
	var crate = MeshInstance3D.new()
	var cm = BoxMesh.new(); cm.size = Vector3(1.6, 0.55, 1.1)
	crate.mesh = cm; crate.position = Vector3(0, 0.275, 0)
	crate.set_surface_override_material(0, _mats["wood"]); root.add_child(crate)
	# Angled display surface
	var disp = MeshInstance3D.new()
	var dm = BoxMesh.new(); dm.size = Vector3(1.5, 0.06, 0.95)
	disp.mesh = dm
	var disp_mat = StandardMaterial3D.new()
	disp_mat.albedo_color = color; disp_mat.roughness = 0.6
	disp.set_surface_override_material(0, disp_mat)
	disp.position = Vector3(0, 0.58, 0.05); disp.rotation.z = -0.12; root.add_child(disp)
	# Small produce items on display
	for j in range(5):
		var item = MeshInstance3D.new()
		var sm = SphereMesh.new(); sm.radius = 0.07; sm.height = 0.14
		item.mesh = sm
		var item_mat = StandardMaterial3D.new()
		item_mat.albedo_color = color * Color(0.9, 0.9, 0.9)
		item_mat.roughness = 0.65
		item.set_surface_override_material(0, item_mat)
		item.position = Vector3(-0.28 + j*0.14, 0.65, randf_range(-0.1, 0.1)); root.add_child(item)
	# Price tag
	var tag = MeshInstance3D.new()
	var tm = BoxMesh.new(); tm.size = Vector3(0.3, 0.12, 0.02)
	tag.mesh = tm
	var tag_mat = StandardMaterial3D.new(); tag_mat.albedo_color = Color(1,1,0.9)
	tag.set_surface_override_material(0, tag_mat)
	tag.position = Vector3(0, 0.85, -0.5); root.add_child(tag)
	# Collision
	var sb = StaticBody3D.new(); sb.collision_layer = 1
	var cs = CollisionShape3D.new()
	var bsh = BoxShape3D.new(); bsh.size = Vector3(1.6, 0.9, 1.1); cs.shape = bsh
	cs.position = Vector3(0, 0.45, 0); sb.add_child(cs); root.add_child(sb)
	add_child(root)

func _build_shelf_rows() -> void:
	var rows = [
		{"x": 5.5,  "products": ["dairy_milk","dairy_yogurt","dairy_cheese"], "label": "Dairy"},
		{"x": 9.5,  "products": ["drink_water","drink_cola","drink_juice"],    "label": "Drinks"},
		{"x": 13.5, "products": ["snack_chips","snack_chocolate","canned_tuna"],"label": "Snacks & Canned"},
		{"x": 17.5, "products": ["bakery_bread","canned_beans","household_soap"],"label": "Bakery & Home"},
		{"x": 21.5, "products": ["frozen_pizza","frozen_peas","meat_chicken"],  "label": "Frozen & Meat"},
	]
	for row_idx in range(rows.size()):
		var row = rows[row_idx]
		for shelf_z in [4.0, 10.0, 16.0, 22.0]:
			var product_id = row["products"][int(shelf_z / 7) % row["products"].size()]
			_build_gondola(Vector3(row["x"], 0, shelf_z), product_id, row_idx)

func _build_gondola(pos: Vector3, product_id: String, color_idx: int) -> void:
	var root = Node3D.new(); root.name = "Gondola_%s_%s" % [str(pos.x), product_id]
	root.position = pos

	# Attach shelf interactable
	var interactable = load("res://scenes/supermarket/shelf_interactable.gd")
	if interactable:
		root.set_script(interactable)
		root.set("shelf_id", "shelf_%s_%d_%d" % [product_id, int(pos.x), int(pos.z)])
		root.set("shelf_capacity", 20)
		root.set("assigned_product_id", product_id)

	var col_idx = color_idx % 6
	# Upright posts x4
	for px in [-0.48, 0.48]:
		for pz in [0.0, -0.46]:
			var post = MeshInstance3D.new()
			var pm = BoxMesh.new(); pm.size = Vector3(0.05, 1.95, 0.05)
			post.mesh = pm; post.set_surface_override_material(0, _mats["metal"])
			post.position = Vector3(px, 0.975, pz); root.add_child(post)
	# Shelf boards x4
	for level in range(4):
		var board = MeshInstance3D.new()
		var bm = BoxMesh.new(); bm.size = Vector3(1.0, 0.025, 0.5)
		board.mesh = bm; board.set_surface_override_material(0, _mats["shelf_board"])
		board.position = Vector3(0, 0.3 + level*0.5, -0.23); root.add_child(board)
		# Back divider rails
		var rail = MeshInstance3D.new()
		var rm = BoxMesh.new(); rm.size = Vector3(1.0, 0.08, 0.02)
		rail.mesh = rm; rail.set_surface_override_material(0, _mats["metal"])
		rail.position = Vector3(0, 0.34 + level*0.5, -0.46); root.add_child(rail)
		# Products on shelf
		if level < 3:
			_add_shelf_products(root, level, col_idx)
	# Back panel
	var back = MeshInstance3D.new()
	var bpm = BoxMesh.new(); bpm.size = Vector3(1.0, 1.95, 0.025)
	back.mesh = bpm
	var back_mat = StandardMaterial3D.new(); back_mat.albedo_color = Color(0.95, 0.95, 0.94); back_mat.roughness = 0.85
	back.set_surface_override_material(0, back_mat)
	back.position = Vector3(0, 0.975, -0.47); root.add_child(back)
	# Collision
	var sb = StaticBody3D.new(); sb.collision_layer = 1
	var cs = CollisionShape3D.new()
	var bsh = BoxShape3D.new(); bsh.size = Vector3(1.1, 2.0, 0.55); cs.shape = bsh
	cs.position = Vector3(0, 1.0, -0.23); sb.add_child(cs); root.add_child(sb)
	add_child(root)

func _add_shelf_products(parent: Node3D, level: int, color_idx: int) -> void:
	var mat = _mats.get("product_%d" % color_idx, _mats["product_0"])
	var count = randi_range(5, 9)
	for i in range(count):
		var prod = MeshInstance3D.new()
		# Alternate between box (bottles/cans) and cylinder shapes
		if i % 3 == 0:
			var cm = CylinderMesh.new(); cm.top_radius = 0.038; cm.bottom_radius = 0.038; cm.height = 0.17
			prod.mesh = cm
		else:
			var bm = BoxMesh.new(); bm.size = Vector3(0.075, 0.155, 0.065)
			prod.mesh = bm
		prod.set_surface_override_material(0, mat)
		prod.position = Vector3(-0.38 + i*0.09, 0.325 + level*0.5, -0.21)
		parent.add_child(prod)

func _build_dairy_cooler() -> void:
	# Right wall: refrigerated open cooler units
	var cooler_mat = StandardMaterial3D.new()
	cooler_mat.albedo_color = Color(0.88, 0.90, 0.92); cooler_mat.metallic = 0.3; cooler_mat.roughness = 0.4
	var glass_door_mat = _mats["glass"].duplicate()
	glass_door_mat.albedo_color = Color(0.60, 0.80, 0.90, 0.35)

	for unit_idx in range(4):
		var z = 4.0 + unit_idx * 7.0
		var root = Node3D.new(); root.name = "Cooler_%d" % unit_idx
		root.position = Vector3(STORE_W - 0.8, 0, z)
		# Cabinet body
		var body = MeshInstance3D.new()
		var bm = BoxMesh.new(); bm.size = Vector3(1.0, 2.2, 1.6)
		body.mesh = bm; body.set_surface_override_material(0, cooler_mat)
		body.position = Vector3(0, 1.1, 0); root.add_child(body)
		# Glass doors
		for d in range(2):
			var door = MeshInstance3D.new()
			var dm = BoxMesh.new(); dm.size = Vector3(0.06, 1.8, 0.75)
			door.mesh = dm; door.set_surface_override_material(0, glass_door_mat)
			door.position = Vector3(-0.52, 1.1, -0.4 + d*0.8); root.add_child(door)
		# Products inside
		var products = [["dairy_milk","dairy_yogurt"],["dairy_cheese","dairy_butter"],["meat_chicken","meat_beef"],["drink_juice","drink_cola"]]
		var pids = products[unit_idx % products.size()]
		for shelf in range(3):
			for col in range(3):
				var p = MeshInstance3D.new()
				var pm = CylinderMesh.new(); pm.top_radius = 0.05; pm.bottom_radius = 0.05; pm.height = 0.22
				p.mesh = pm
				var pm_mat = StandardMaterial3D.new()
				pm_mat.albedo_color = [Color(0.9,0.9,1.0), Color(0.9,1.0,0.9), Color(1.0,0.85,0.7)][shelf % 3]
				p.set_surface_override_material(0, pm_mat)
				p.position = Vector3(0.1, 0.4 + shelf*0.65, -0.5 + col*0.5); root.add_child(p)
		# Collision
		var sb = StaticBody3D.new(); sb.collision_layer = 1
		var cs = CollisionShape3D.new()
		var bsh = BoxShape3D.new(); bsh.size = Vector3(1.0, 2.2, 1.6); cs.shape = bsh
		cs.position = Vector3(0, 1.1, 0); sb.add_child(cs); root.add_child(sb)
		add_child(root)

func _build_checkout_lanes() -> void:
	for lane in range(3):
		_build_checkout_counter(Vector3(6.0 + lane * 6.5, 0, STORE_D - 5.5), lane)

func _build_checkout_counter(pos: Vector3, idx: int) -> void:
	var root = Node3D.new(); root.name = "Checkout_%d" % idx
	root.position = pos

	# Attach checkout interactable
	var checkout_script = load("res://scenes/supermarket/checkout_interactable.gd")
	if checkout_script:
		root.set_script(checkout_script)
		root.set_meta("checkout_index", idx)

	# Main counter body — L-shape (conveyor + bagging area)
	var conveyor_body = MeshInstance3D.new()
	var cbm = BoxMesh.new(); cbm.size = Vector3(1.8, 0.95, 0.72)
	conveyor_body.mesh = cbm; conveyor_body.set_surface_override_material(0, _mats["counter"])
	conveyor_body.position = Vector3(-0.4, 0.475, 0); root.add_child(conveyor_body)
	# Bagging area
	var bag_area = MeshInstance3D.new()
	var bam = BoxMesh.new(); bam.size = Vector3(0.9, 0.85, 0.72)
	bag_area.mesh = bam; bag_area.set_surface_override_material(0, _mats["counter"])
	bag_area.position = Vector3(1.0, 0.425, 0); root.add_child(bag_area)
	# Conveyor belt surface
	var belt = MeshInstance3D.new()
	var belt_m = BoxMesh.new(); belt_m.size = Vector3(1.5, 0.03, 0.55)
	belt.mesh = belt_m; belt.set_surface_override_material(0, _mats["belt"])
	belt.position = Vector3(-0.4, 0.965, 0); root.add_child(belt)
	# Screen/register
	var screen = MeshInstance3D.new()
	var sm = BoxMesh.new(); sm.size = Vector3(0.35, 0.44, 0.04)
	screen.mesh = sm; screen.set_surface_override_material(0, _mats["screen"])
	screen.position = Vector3(0.6, 1.5, 0); screen.rotation.x = -0.3; root.add_child(screen)
	# Screen stand
	var stand = MeshInstance3D.new()
	var stm = CylinderMesh.new(); stm.top_radius = 0.025; stm.bottom_radius = 0.03; stm.height = 0.5
	stand.mesh = stm
	var stand_mat = StandardMaterial3D.new(); stand_mat.albedo_color = Color(0.4,0.4,0.42); stand_mat.metallic=0.7; stand_mat.roughness=0.3
	stand.set_surface_override_material(0, stand_mat)
	stand.position = Vector3(0.6, 1.2, 0); root.add_child(stand)
	# Divider post
	var div = MeshInstance3D.new()
	var dm = CylinderMesh.new(); dm.top_radius = 0.025; dm.bottom_radius = 0.025; dm.height = 0.9
	div.mesh = dm; div.set_surface_override_material(0, stand_mat)
	div.position = Vector3(-1.35, 0.45, 0); root.add_child(div)
	# Lane divider paddle
	var paddle = MeshInstance3D.new()
	var pm = BoxMesh.new(); pm.size = Vector3(0.06, 0.06, 0.55)
	paddle.mesh = pm
	var pad_mat = StandardMaterial3D.new(); pad_mat.albedo_color = Color(0.95,0.95,0.95)
	paddle.set_surface_override_material(0, pad_mat)
	paddle.position = Vector3(-1.35, 0.95, 0); root.add_child(paddle)
	# Collision
	var sb = StaticBody3D.new(); sb.collision_layer = 1
	var cs = CollisionShape3D.new()
	var bsh = BoxShape3D.new(); bsh.size = Vector3(2.8, 0.95, 0.72); cs.shape = bsh
	cs.position = Vector3(0.0, 0.475, 0); sb.add_child(cs); root.add_child(sb)
	add_child(root)

func _build_service_desk() -> void:
	# Customer service desk at back
	var root = Node3D.new(); root.name = "ServiceDesk"
	root.position = Vector3(STORE_W - 5.0, 0, 2.0)
	var desk = MeshInstance3D.new()
	var dm = BoxMesh.new(); dm.size = Vector3(3.5, 1.1, 0.8)
	desk.mesh = dm; desk.set_surface_override_material(0, _mats["counter"])
	desk.position = Vector3(0, 0.55, 0); root.add_child(desk)
	# Sign above
	var sign = MeshInstance3D.new()
	var sm = BoxMesh.new(); sm.size = Vector3(2.8, 0.45, 0.08)
	sign.mesh = sm; sign.set_surface_override_material(0, _mats["sign"])
	sign.position = Vector3(0, 1.8, 0); root.add_child(sign)
	# Collision
	var sb = StaticBody3D.new(); sb.collision_layer = 1
	var cs = CollisionShape3D.new()
	var bsh = BoxShape3D.new(); bsh.size = Vector3(3.5, 1.1, 0.8); cs.shape = bsh
	cs.position = Vector3(0, 0.55, 0); sb.add_child(cs); root.add_child(sb)
	add_child(root)

func _build_ceiling_lights() -> void:
	var lights_root = Node3D.new(); lights_root.name = "CeilingLights"
	var rows_x = [4.5, 9.5, 14.5, 19.5, 24.5]
	var cols_z = [5.0, 11.0, 17.0, 23.0, 29.0]
	for lx in rows_x:
		for lz in cols_z:
			var light_node = Node3D.new()
			light_node.position = Vector3(lx, STORE_H - 0.08, lz)
			# Fixture housing
			var fixture = MeshInstance3D.new()
			var fm = BoxMesh.new(); fm.size = Vector3(1.4, 0.06, 0.28)
			fixture.mesh = fm; fixture.set_surface_override_material(0, _mats["light_panel"])
			lights_root.add_child(fixture)
			fixture.position = light_node.position
			# OmniLight
			var omni = OmniLight3D.new()
			omni.light_color = Color(1.0, 0.98, 0.93)
			omni.light_energy = 1.5
			omni.omni_range = 9.0
			omni.shadow_enabled = false
			omni.position = light_node.position + Vector3(0, -0.08, 0)
			lights_root.add_child(omni)
	add_child(lights_root)

func _build_signage() -> void:
	var sign_root = Node3D.new(); sign_root.name = "Signage"
	# Store name sign above entrance — the main header
	var store_sign = MeshInstance3D.new()
	var sm = BoxMesh.new(); sm.size = Vector3(8.5, 0.9, 0.18)
	store_sign.mesh = sm; store_sign.set_surface_override_material(0, _mats["sign"])
	store_sign.position = Vector3(STORE_W*0.5, STORE_H + 0.3, STORE_D + 0.1); sign_root.add_child(store_sign)
	# Glow effect for sign
	var sign_light = OmniLight3D.new()
	sign_light.light_color = Color(0.3, 0.9, 0.3)
	sign_light.light_energy = 1.2
	sign_light.omni_range = 4.0
	sign_light.position = Vector3(STORE_W*0.5, STORE_H + 0.3, STORE_D + 0.5); sign_root.add_child(sign_light)
	# Aisle number signs hanging from ceiling
	var aisle_data = [
		[5.5, "1 · Dairy"], [9.5, "2 · Drinks"], [13.5, "3 · Snacks"],
		[17.5, "4 · Bakery"], [21.5, "5 · Frozen"]
	]
	for ad in aisle_data:
		var aisle_sign = MeshInstance3D.new()
		var asm = BoxMesh.new(); asm.size = Vector3(1.6, 0.4, 0.06)
		aisle_sign.mesh = asm; aisle_sign.set_surface_override_material(0, _mats["sign"])
		aisle_sign.position = Vector3(ad[0], STORE_H - 0.6, STORE_D*0.5); sign_root.add_child(aisle_sign)
	# Exit sign
	var exit_sign = MeshInstance3D.new()
	var em = BoxMesh.new(); em.size = Vector3(1.1, 0.28, 0.06)
	exit_sign.mesh = em
	var exit_mat = StandardMaterial3D.new()
	exit_mat.albedo_color = Color(0.9, 0.0, 0.0); exit_mat.emission_enabled = true
	exit_mat.emission = Color(1.0, 0.0, 0.0); exit_mat.emission_energy_multiplier = 1.5
	exit_sign.set_surface_override_material(0, exit_mat)
	exit_sign.position = Vector3(STORE_W*0.5, STORE_H - 0.4, STORE_D - 0.2); sign_root.add_child(exit_sign)
	add_child(sign_root)

func _build_nav_region() -> void:
	var nav = NavigationRegion3D.new(); nav.name = "NavigationRegion3D"
	var nav_mesh = NavigationMesh.new()
	nav_mesh.agent_height = 1.9; nav_mesh.agent_radius = 0.42
	nav_mesh.agent_max_climb = 0.35; nav_mesh.agent_max_slope = 45.0
	nav.navigation_mesh = nav_mesh; add_child(nav)
	nav.bake_navigation_mesh.call_deferred()
