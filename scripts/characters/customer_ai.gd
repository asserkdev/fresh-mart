extends CharacterBody3D
## CustomerAI — shopper that enters, selects products, pays, and leaves.

enum State { ENTERING, BROWSING, SELECTING, QUEUING, PAYING, LEAVING, DONE }

var customer_id: String = ""
var shopping_list: Array = []     # product_ids to buy
var basket: Dictionary = {}       # product_id -> quantity
var budget: float = 50.0
var satisfaction: float = 1.0
var current_state: State = State.ENTERING

var _nav_agent: NavigationAgent3D = null
var _target_shelf = null
var _checkout_target = null
var _exit_position: Vector3 = Vector3.ZERO
var _state_timer: float = 0.0
var _move_speed: float = 2.0

const GRAVITY = 9.8

func _ready() -> void:
	_nav_agent = $NavigationAgent3D
	customer_id = "customer_%d" % Time.get_unix_time_from_system()
	_generate_shopping_list()
	EventBus.customer_entered.emit(customer_id)

func _generate_shopping_list() -> void:
	var pm = ServiceRegistry.get_service("ProductManager")
	if pm == null:
		return
	budget = randf_range(20.0, 120.0)
	var all_products = pm.products.keys()
	var num_items = randi_range(2, 8)
	shopping_list = []
	for i in range(num_items):
		if all_products.size() > 0:
			shopping_list.append(all_products[randi() % all_products.size()])

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	_state_timer -= delta

	match current_state:
		State.ENTERING:
			_handle_entering()
		State.BROWSING:
			_handle_browsing()
		State.SELECTING:
			_handle_selecting(delta)
		State.QUEUING:
			_handle_queuing()
		State.PAYING:
			_handle_paying(delta)
		State.LEAVING:
			_handle_leaving()
		State.DONE:
			queue_free()

	if _nav_agent and not _nav_agent.is_navigation_finished():
		var next = _nav_agent.get_next_path_position()
		var dir = (next - global_position).normalized()
		velocity.x = dir.x * _move_speed
		velocity.z = dir.z * _move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, _move_speed)
		velocity.z = move_toward(velocity.z, 0, _move_speed)

	move_and_slide()

func _handle_entering() -> void:
	if _nav_agent and _nav_agent.is_navigation_finished():
		current_state = State.BROWSING
		_state_timer = 2.0

func _handle_browsing() -> void:
	if shopping_list.is_empty() or _state_timer > 0:
		return
	var product_id = shopping_list.pop_front()
	_try_pick_product(product_id)

func _try_pick_product(product_id: String) -> void:
	var inv = ServiceRegistry.get_service("InventoryManager")
	var pm = ServiceRegistry.get_service("PricingManager")
	if inv == null or not inv.has_stock(product_id):
		# Product not available — reduce satisfaction
		satisfaction -= 0.1
		if shopping_list.is_empty():
			_proceed_to_checkout()
		return
	var price = pm.get_price(product_id) if pm else 1.0
	if price > budget:
		# Too expensive
		satisfaction -= 0.05
		if shopping_list.is_empty():
			_proceed_to_checkout()
		return
	# Add to basket
	basket[product_id] = basket.get(product_id, 0) + 1
	budget -= price
	current_state = State.SELECTING
	_state_timer = randf_range(1.5, 4.0)

func _handle_selecting(_delta: float) -> void:
	if _state_timer > 0:
		return
	if shopping_list.is_empty():
		_proceed_to_checkout()
	else:
		current_state = State.BROWSING
		_state_timer = randf_range(0.5, 2.0)

func _proceed_to_checkout() -> void:
	if basket.is_empty():
		current_state = State.LEAVING
		return
	current_state = State.QUEUING
	_state_timer = randf_range(2.0, 8.0)

func _handle_queuing() -> void:
	if _state_timer > 0:
		return
	current_state = State.PAYING
	_state_timer = randf_range(3.0, 8.0)
	_process_payment()

func _process_payment() -> void:
	var checkout = ServiceRegistry.get_service("CheckoutManager")
	if checkout == null:
		current_state = State.LEAVING
		return
	var tid = checkout.start_transaction(customer_id)
	for pid in basket:
		checkout.add_item_to_transaction(pid, basket[pid])
	var result = checkout.complete_transaction("cash")
	var spent = result.get("total", 0.0) if not result.is_empty() else 0.0
	EventBus.customer_left.emit(customer_id, spent)

func _handle_paying(_delta: float) -> void:
	if _state_timer > 0:
		return
	current_state = State.LEAVING

func _handle_leaving() -> void:
	if _nav_agent:
		_nav_agent.target_position = _exit_position
	if _nav_agent and _nav_agent.is_navigation_finished():
		current_state = State.DONE

func set_exit_position(pos: Vector3) -> void:
	_exit_position = pos
