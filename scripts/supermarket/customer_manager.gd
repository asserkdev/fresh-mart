extends Node
## CustomerManager — controls customer flow: spawning, tracking, satisfaction.

var active_customers: Array = []
var daily_customer_count: int = 0
var total_customers_served: int = 0
var average_satisfaction: float = 1.0
var _satisfaction_history: Array = []

var _spawn_timer: float = 0.0
var _spawn_interval: float = 20.0
const MAX_CUSTOMERS: int = 10

func _ready() -> void:
	ServiceRegistry.register("CustomerManager", self)
	EventBus.customer_entered.connect(_on_customer_entered)
	EventBus.customer_left.connect(_on_customer_left)
	EventBus.day_changed.connect(_on_day_changed)

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	var hour = GameClock.game_hour
	if hour < 8 or hour >= 21:
		return  # Store closed
	
	_spawn_timer += delta
	
	# Dynamic spawn interval based on reputation + time of day
	var sm = ServiceRegistry.get_service("SupermarketManager")
	var rep = sm.store_reputation if sm else 50.0
	var peak = _get_peak_multiplier(hour)
	_spawn_interval = lerp(40.0, 8.0, (rep / 100.0) * peak)
	
	if _spawn_timer >= _spawn_interval and active_customers.size() < MAX_CUSTOMERS:
		_spawn_timer = 0.0
		_try_spawn_customer()
	
	# Clean up invalid customer references
	active_customers = active_customers.filter(func(c): return is_instance_valid(c))

func _get_peak_multiplier(hour: int) -> float:
	# Peak hours: 11-13 (lunch) and 17-19 (after work)
	if hour >= 11 and hour <= 13:
		return 1.0
	elif hour >= 17 and hour <= 19:
		return 0.9
	elif hour >= 9 and hour <= 20:
		return 0.6
	return 0.2

func _try_spawn_customer() -> void:
	var customer_scene = load("res://scenes/characters/customer.tscn")
	if customer_scene == null:
		return
	
	var customer = customer_scene.instantiate()
	# Find spawn point — entrance area
	var spawn_pos = _get_spawn_position()
	var exit_pos = spawn_pos + Vector3(0, 0, 2)
	
	customer.global_position = spawn_pos
	customer.set_exit_position(exit_pos)
	
	# Build customer mesh
	CharacterMeshBuilder.build_character(customer.get_node_or_null("MeshRoot"), "casual")
	
	# Add to scene
	var world_root = get_tree().get_root().get_node_or_null("WorldRoot")
	if world_root:
		world_root.add_child(customer)
	else:
		add_child(customer)
	
	active_customers.append(customer)
	daily_customer_count += 1

func _get_spawn_position() -> Vector3:
	# Spawn near supermarket entrance
	var store = get_tree().get_root().get_node_or_null("WorldRoot/SupermarketBuilding")
	if store:
		var entrance = store.get_node_or_null("Interior/EntranceMarker")
		if entrance:
			return entrance.global_position + Vector3(randf_range(-2, 2), 0, 2)
	return Vector3(randf_range(8, 16), 1, 37)

func _on_customer_entered(customer_id: String) -> void:
	pass

func _on_customer_left(customer_id: String, spent: float) -> void:
	total_customers_served += 1
	# Track satisfaction based on how much they spent
	var satisfaction = clamp(spent / 20.0, 0.1, 1.0)
	_satisfaction_history.append(satisfaction)
	if _satisfaction_history.size() > 50:
		_satisfaction_history.pop_front()
	var total_sat = 0.0
	for s in _satisfaction_history:
		total_sat += s
	average_satisfaction = total_sat / _satisfaction_history.size()
	# Update reputation
	var sm = ServiceRegistry.get_service("SupermarketManager")
	if sm:
		sm.update_reputation((satisfaction - 0.5) * 0.5)

func _on_day_changed(_day: int) -> void:
	daily_customer_count = 0

func get_analytics() -> Dictionary:
	return {
		"active": active_customers.size(),
		"daily_count": daily_customer_count,
		"total_served": total_customers_served,
		"avg_satisfaction": average_satisfaction,
	}
