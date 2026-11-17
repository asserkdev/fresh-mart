extends Node3D
## PlayerMesh — builds the visible player character.
## Tries to use imported FBX first, falls back to procedural mesh.

func _ready() -> void:
	_setup_mesh()

func _setup_mesh() -> void:
	# Try FBX first
	var fbx_path = "res://assets/models/characters/man.fbx"
	if ResourceLoader.exists(fbx_path):
		var scene = load(fbx_path)
		if scene:
			var instance = scene.instantiate()
			add_child(instance)
			# Try to find and configure animation player
			var anim = _find_animation_player(instance)
			if anim:
				_setup_animations(anim)
			print("[PlayerMesh] Using FBX model")
			return
	# Fallback: procedural mesh
	CharacterMeshBuilder.build_character(self, "default")
	print("[PlayerMesh] Using procedural character mesh")

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found = _find_animation_player(child)
		if found:
			return found
	return null

func _setup_animations(anim: AnimationPlayer) -> void:
	# Rename animations to standard names if needed
	var anims = anim.get_animation_list()
	print("[PlayerMesh] Available animations: ", anims)
	# Common FBX animation name mappings
	var name_map = {
		"mixamo_idle": "Idle", "idle": "Idle", "Idle": "Idle", "idle_1": "Idle",
		"mixamo_walk": "Walking", "walk": "Walking", "Walk": "Walking", "walking": "Walking",
		"mixamo_run": "Running", "run": "Running", "Run": "Running", "running": "Running",
	}
	for anim_name in anims:
		var lower = anim_name.to_lower()
		for key in name_map:
			if key.to_lower() == lower:
				# Can't rename directly, but log it
				print("[PlayerMesh] Animation '%s' maps to '%s'" % [anim_name, name_map[key]])
