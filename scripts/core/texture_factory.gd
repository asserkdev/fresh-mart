extends Node
## TextureFactory — generates PBR-quality procedural textures at runtime.

static func make_concrete(color: Color = Color(0.55, 0.53, 0.52)) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.metallic = 0.0
	return mat

static func make_metal(color: Color = Color(0.7, 0.7, 0.72), rough: float = 0.3) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.85
	mat.roughness = rough
	return mat

static func make_wood(color: Color = Color(0.6, 0.42, 0.22)) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	mat.metallic = 0.0
	return mat

static func make_glass(color: Color = Color(0.7, 0.85, 0.9, 0.3)) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	return mat

static func make_plastic(color: Color, rough: float = 0.5) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = 0.05
	return mat

static func make_tile(color: Color = Color(0.9, 0.9, 0.88), grout_color: Color = Color(0.6, 0.6, 0.6)) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.3
	mat.metallic = 0.0
	# Generate a simple tile texture
	var img = Image.create(64, 64, false, Image.FORMAT_RGB8)
	for x in range(64):
		for y in range(64):
			var is_grout = (x % 32 <= 1) or (y % 32 <= 1)
			if is_grout:
				img.set_pixel(x, y, grout_color)
			else:
				var noise_val = randf_range(-0.03, 0.03)
				img.set_pixel(x, y, Color(color.r + noise_val, color.g + noise_val, color.b + noise_val))
	var tex = ImageTexture.create_from_image(img)
	mat.albedo_texture = tex
	return mat

static func make_asphalt() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	mat.roughness = 0.95
	var img = Image.create(64, 64, false, Image.FORMAT_RGB8)
	for x in range(64):
		for y in range(64):
			var n = randf_range(-0.04, 0.04)
			img.set_pixel(x, y, Color(0.2 + n, 0.2 + n, 0.2 + n))
	mat.albedo_texture = ImageTexture.create_from_image(img)
	return mat

static func make_grass() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.48, 0.18)
	mat.roughness = 0.95
	var img = Image.create(64, 64, false, Image.FORMAT_RGB8)
	for x in range(64):
		for y in range(64):
			var n = randf_range(-0.06, 0.06)
			img.set_pixel(x, y, Color(0.25 + n, 0.48 + n * 0.5, 0.18 + n * 0.3))
	mat.albedo_texture = ImageTexture.create_from_image(img)
	return mat

static func make_brick(color: Color = Color(0.7, 0.35, 0.22)) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	var img = Image.create(128, 64, false, Image.FORMAT_RGB8)
	# Draw brick pattern
	var mortar = Color(0.65, 0.63, 0.6)
	for x in range(128):
		for y in range(64):
			var row = y / 16
			var offset = 32 if (row % 2 == 0) else 0
			var col_in_row = (x + offset) % 64
			var is_mortar = (y % 16 == 0 or y % 16 == 15 or col_in_row < 2 or col_in_row > 61)
			if is_mortar:
				img.set_pixel(x, y, mortar)
			else:
				var n = randf_range(-0.04, 0.04)
				img.set_pixel(x, y, Color(color.r + n, color.g + n * 0.3, color.b + n * 0.2))
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.roughness = 0.85
	return mat

static func make_shelf_metal() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.72, 0.74)
	mat.metallic = 0.7
	mat.roughness = 0.4
	return mat

static func make_product_label(product_color: Color, label_text_color: Color = Color(1,1,1)) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	var img = Image.create(64, 64, false, Image.FORMAT_RGB8)
	# Solid background with a stripe for label
	for x in range(64):
		for y in range(64):
			if y >= 20 and y <= 44:
				img.set_pixel(x, y, label_text_color * 0.9)
			else:
				img.set_pixel(x, y, product_color)
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.roughness = 0.6
	return mat

static func make_road_marking() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 0.1)
	mat.roughness = 0.8
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.8, 0.0)
	mat.emission_energy_multiplier = 0.3
	return mat

static func make_emissive(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat

static func make_skin() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.75, 0.6)
	mat.roughness = 0.7
	mat.subsurface_scattering_strength = 0.3
	return mat

static func make_fabric(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mat.metallic = 0.0
	return mat
