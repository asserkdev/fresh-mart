extends Node3D
## Supermarket — the main playable store. Contains shelves, checkout, storage.

@onready var placement_system: Node3D = $PlacementSystem
@onready var customer_spawner: Node3D = $CustomerSpawner
@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D

var customer_scene: PackedScene = null
var _customer_timer: float = 0.0
var _customer_interval: float = 15.0  # seconds between customers
var _max_customers: int = 8
var _active_customers: int = 0

func _ready() -> void:
	customer_scene = load("res://scenes/characters/customer.tscn")
	ServiceRegistry.register("SupermarketScene", self)

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	# Spawn customers during business hours
	if GameClock.game_hour >= 8 and GameClock.game_hour < 21:
		_customer_timer += delta
		# Adjust interval by reputation and time of day
		var sm = ServiceRegistry.get_service("SupermarketManager")
		var rep = sm.store_reputation if sm else 50.0
		var peak = 1.0 if (GameClock.game_hour >= 11 and GameClock.game_hour <= 14) else 0.6
		_customer_interval = lerp(30.0, 8.0, (rep / 100.0) * peak)
		if _customer_timer >= _customer_interval and _active_customers < _max_customers:
			_customer_timer = 0.0
			_spawn_customer()

func _spawn_customer() -> void:
	if customer_scene == null:
		return
	var c = customer_scene.instantiate()
	add_child(c)
	# Spawn at entrance
	c.global_position = $EntranceMarker.global_position if has_node("EntranceMarker") else Vector3(0, 1, -15)
	c.set_exit_position(c.global_position)
	# Navigate into store
	if c.has_method("navigate_to"):
		c.navigate_to(Vector3(0, 0, 0))
	_active_customers += 1
	c.tree_exited.connect(func(): _active_customers -= 1)

func get_shelf_positions() -> Array:
	var positions = []
	for child in get_children():
		if child.name.begins_with("Shelf"):
			positions.append(child.global_position)
	return positions
