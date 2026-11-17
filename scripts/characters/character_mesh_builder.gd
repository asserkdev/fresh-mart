extends Node
## CharacterMeshBuilder — procedurally builds human-looking character meshes with PBR materials.
## Used by both player and NPCs until FBX import is processed.

static func build_character(root: Node3D, style: String = "default") -> void:
	# Pick colors based on style
	var skin_color = Color(0.88, 0.72, 0.56)
	var shirt_color = Color(0.25, 0.42, 0.72)
	var pants_color = Color(0.2, 0.22, 0.28)
	var shoe_color = Color(0.18, 0.14, 0.11)
	var hair_color = Color(0.25, 0.18, 0.1)

	match style:
		"worker":
			shirt_color = Color(0.72, 0.55, 0.15)   # orange hi-vis
			pants_color = Color(0.25, 0.3, 0.38)
		"manager":
			shirt_color = Color(0.95, 0.95, 0.95)   # white shirt
			pants_color = Color(0.1, 0.12, 0.2)     # dark suit
		"casual":
			shirt_color = Color(randf_range(0.4,0.9), randf_range(0.3,0.8), randf_range(0.3,0.8))
			pants_color = Color(randf_range(0.2,0.6), randf_range(0.2,0.6), randf_range(0.2,0.6))
		"npc":
			shirt_color = Color(randf_range(0.3,0.9), randf_range(0.3,0.9), randf_range(0.3,0.9))
			pants_color = Color(randf_range(0.15,0.5), randf_range(0.15,0.5), randf_range(0.15,0.5))
			skin_color = [
				Color(0.90, 0.75, 0.6),
				Color(0.65, 0.48, 0.32),
				Color(0.35, 0.25, 0.18),
				Color(0.95, 0.80, 0.68),
			][randi() % 4]

	var skin_mat = _make_skin_mat(skin_color)
	var shirt_mat = _make_fabric_mat(shirt_color)
	var pants_mat = _make_fabric_mat(pants_color)
	var shoe_mat = _make_shoe_mat(shoe_color)
	var hair_mat = _make_hair_mat(hair_color)

	# HEAD
	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.13
	head_mesh.height = 0.26
	head.mesh = head_mesh
	head.set_surface_override_material(0, skin_mat)
	head.position = Vector3(0, 1.72, 0)
	root.add_child(head)

	# HAIR
	var hair = MeshInstance3D.new()
	var hair_mesh = SphereMesh.new()
	hair_mesh.radius = 0.135
	hair_mesh.height = 0.18
	hair.mesh = hair_mesh
	hair.set_surface_override_material(0, hair_mat)
	hair.position = Vector3(0, 1.80, 0)
	root.add_child(hair)

	# EYES
	for ex in [-0.055, 0.055]:
		var eye = MeshInstance3D.new()
		var em = SphereMesh.new()
		em.radius = 0.022
		em.height = 0.022
		eye.mesh = em
		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = Color(0.05, 0.05, 0.1)
		eye.set_surface_override_material(0, eye_mat)
		eye.position = Vector3(ex, 1.73, -0.12)
		root.add_child(eye)

	# NECK
	var neck = MeshInstance3D.new()
	var neck_mesh = CylinderMesh.new()
	neck_mesh.top_radius = 0.06
	neck_mesh.bottom_radius = 0.06
	neck_mesh.height = 0.1
	neck.mesh = neck_mesh
	neck.set_surface_override_material(0, skin_mat)
	neck.position = Vector3(0, 1.57, 0)
	root.add_child(neck)

	# TORSO (shirt)
	var torso = MeshInstance3D.new()
	var torso_mesh = CapsuleMesh.new()
	torso_mesh.radius = 0.19
	torso_mesh.height = 0.58
	torso.mesh = torso_mesh
	torso.set_surface_override_material(0, shirt_mat)
	torso.position = Vector3(0, 1.22, 0)
	root.add_child(torso)

	# ARMS
	for side in [-1, 1]:
		# Upper arm
		var ua = MeshInstance3D.new()
		var ua_mesh = CapsuleMesh.new()
		ua_mesh.radius = 0.065
		ua_mesh.height = 0.3
		ua.mesh = ua_mesh
		ua.set_surface_override_material(0, shirt_mat)
		ua.position = Vector3(side * 0.26, 1.28, 0)
		ua.rotation.z = side * 0.2
		root.add_child(ua)
		# Lower arm
		var la = MeshInstance3D.new()
		var la_mesh = CapsuleMesh.new()
		la_mesh.radius = 0.055
		la_mesh.height = 0.28
		la.mesh = la_mesh
		la.set_surface_override_material(0, skin_mat)
		la.position = Vector3(side * 0.3, 1.0, 0)
		la.rotation.z = side * 0.3
		root.add_child(la)
		# Hand
		var hand = MeshInstance3D.new()
		var hm = SphereMesh.new()
		hm.radius = 0.055
		hm.height = 0.09
		hand.mesh = hm
		hand.set_surface_override_material(0, skin_mat)
		hand.position = Vector3(side * 0.34, 0.86, 0)
		root.add_child(hand)

	# PELVIS
	var pelvis = MeshInstance3D.new()
	var pelvis_mesh = CylinderMesh.new()
	pelvis_mesh.top_radius = 0.17
	pelvis_mesh.bottom_radius = 0.16
	pelvis_mesh.height = 0.14
	pelvis.mesh = pelvis_mesh
	pelvis.set_surface_override_material(0, pants_mat)
	pelvis.position = Vector3(0, 0.88, 0)
	root.add_child(pelvis)

	# LEGS
	for side in [-1, 1]:
		# Upper leg
		var ul = MeshInstance3D.new()
		var ul_mesh = CapsuleMesh.new()
		ul_mesh.radius = 0.085
		ul_mesh.height = 0.4
		ul.mesh = ul_mesh
		ul.set_surface_override_material(0, pants_mat)
		ul.position = Vector3(side * 0.1, 0.65, 0)
		root.add_child(ul)
		# Lower leg
		var ll = MeshInstance3D.new()
		var ll_mesh = CapsuleMesh.new()
		ll_mesh.radius = 0.07
		ll_mesh.height = 0.36
		ll.mesh = ll_mesh
		ll.set_surface_override_material(0, pants_mat)
		ll.position = Vector3(side * 0.1, 0.27, 0)
		root.add_child(ll)
		# Shoe
		var shoe = MeshInstance3D.new()
		var shoe_mesh = BoxMesh.new()
		shoe_mesh.size = Vector3(0.12, 0.08, 0.22)
		shoe.mesh = shoe_mesh
		shoe.set_surface_override_material(0, shoe_mat)
		shoe.position = Vector3(side * 0.1, 0.04, 0.02)
		root.add_child(shoe)

static func _make_skin_mat(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	mat.metallic = 0.0
	mat.subsurface_scattering_strength = 0.2
	return mat

static func _make_fabric_mat(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	# Add subtle fabric texture
	var img = Image.create(32, 32, false, Image.FORMAT_RGB8)
	for x in range(32):
		for y in range(32):
			var n = randf_range(-0.03, 0.03)
			img.set_pixel(x, y, Color(color.r + n, color.g + n, color.b + n))
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.roughness = 0.92
	mat.metallic = 0.0
	return mat

static func _make_shoe_mat(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mat.metallic = 0.05
	return mat

static func _make_hair_mat(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mat.metallic = 0.0
	return mat
