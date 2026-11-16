extends Node
## SupplierManager — suppliers, catalogues, orders, delivery simulation.

var suppliers: Dictionary = {}      # supplier_id -> Supplier
var pending_orders: Array = []      # Array of order dicts
var order_history: Array = []

func _ready() -> void:
	ServiceRegistry.register("SupplierManager", self)
	_load_default_suppliers()
	EventBus.day_changed.connect(_on_day_changed)

func _load_default_suppliers() -> void:
	var defaults = [
		{
			"id": "supplier_farmco",
			"name": "FarmCo Wholesale",
			"type": "produce",
			"products": ["fruit_apple","fruit_banana","fruit_orange","fruit_grapes","fruit_strawberry",
						 "veg_carrot","veg_potato","veg_tomato","veg_onion","veg_lettuce"],
			"reliability": 0.9,
			"delivery_days": 1,
			"relationship": 50.0,
			"min_order_value": 50.0,
		},
		{
			"id": "supplier_dairylink",
			"name": "DairyLink",
			"type": "dairy",
			"products": ["dairy_milk","dairy_cheese","dairy_butter","dairy_yogurt","dairy_eggs"],
			"reliability": 0.95,
			"delivery_days": 1,
			"relationship": 50.0,
			"min_order_value": 30.0,
		},
		{
			"id": "supplier_meathouse",
			"name": "MeatHouse Direct",
			"type": "meat",
			"products": ["meat_chicken","meat_beef","meat_pork"],
			"reliability": 0.85,
			"delivery_days": 1,
			"relationship": 40.0,
			"min_order_value": 100.0,
		},
		{
			"id": "supplier_metropack",
			"name": "MetroPack",
			"type": "general",
			"products": ["drink_water","drink_cola","drink_juice","snack_chips","snack_chocolate",
						 "canned_tuna","canned_beans","canned_tomato","household_soap",
						 "household_detergent","household_toilet_paper"],
			"reliability": 0.92,
			"delivery_days": 2,
			"relationship": 50.0,
			"min_order_value": 80.0,
		},
		{
			"id": "supplier_bakehouse",
			"name": "BakeHouse",
			"type": "bakery",
			"products": ["bakery_bread","bakery_croissant","bakery_muffin"],
			"reliability": 0.88,
			"delivery_days": 1,
			"relationship": 45.0,
			"min_order_value": 20.0,
		},
	]
	for s in defaults:
		suppliers[s["id"]] = s

func get_supplier(supplier_id: String) -> Dictionary:
	return suppliers.get(supplier_id, {})

func get_suppliers_for_product(product_id: String) -> Array:
	var result = []
	for sid in suppliers:
		if product_id in suppliers[sid].get("products", []):
			result.append(sid)
	return result

func place_order(supplier_id: String, items: Dictionary) -> String:
	# items: product_id -> quantity
	var sup = suppliers.get(supplier_id)
	if sup == null:
		push_error("[SupplierManager] Unknown supplier: " + supplier_id)
		return ""

	var order_id = "order_%d_%d" % [GameClock.game_day, randi() % 10000]
	var total_cost = 0.0
	var pm = ServiceRegistry.get_service("ProductManager")
	for pid in items:
		var qty = items[pid]
		var cost = pm.get_wholesale_cost(pid) * qty if pm else qty * 1.0
		total_cost += cost

	# Check business money
	var sm = ServiceRegistry.get_service("SupermarketManager")
	if sm and sm.business_money < total_cost:
		EventBus.notification_requested.emit("Not enough business funds for order!", "error", 3.0)
		return ""

	var delivery_day = GameClock.game_day + sup.get("delivery_days", 1)
	var order = {
		"order_id": order_id,
		"supplier_id": supplier_id,
		"items": items.duplicate(),
		"total_cost": total_cost,
		"ordered_day": GameClock.game_day,
		"delivery_day": delivery_day,
		"status": "pending",
	}
	pending_orders.append(order)

	# Deduct cost
	if sm:
		sm.add_expense("stock_purchase", total_cost)
	EventBus.product_purchased.emit(supplier_id, 0, total_cost)
	EventBus.notification_requested.emit(
		"Order placed with %s. Delivery in %d day(s)." % [sup["name"], sup["delivery_days"]], "info", 3.0)
	return order_id

func _on_day_changed(day: int) -> void:
	_process_deliveries(day)

func _process_deliveries(day: int) -> void:
	var delivered = []
	for order in pending_orders:
		if order["delivery_day"] <= day:
			_deliver_order(order)
			delivered.append(order)
	for o in delivered:
		pending_orders.erase(o)
		order_history.append(o)

func _deliver_order(order: Dictionary) -> void:
	var sup = suppliers.get(order["supplier_id"], {})
	var reliability = sup.get("reliability", 1.0)
	var inv = ServiceRegistry.get_service("InventoryManager")
	var pm = ServiceRegistry.get_service("ProductManager")
	for pid in order["items"]:
		var qty = order["items"][pid]
		# Reliability check — partial delivery possible
		var actual_qty = qty if randf() < reliability else int(qty * randf_range(0.5, 1.0))
		if actual_qty > 0 and inv:
			var shelf_life = pm.get_shelf_life_days(pid) if pm else 30
			var expiry = GameClock.game_day + shelf_life
			inv.add_stock(pid, actual_qty, expiry)
	order["status"] = "delivered"
	EventBus.delivery_arrived.emit(order["supplier_id"], order["order_id"])
	EventBus.notification_requested.emit(
		"Delivery arrived from %s!" % sup.get("name", order["supplier_id"]), "success", 3.0)

func improve_relationship(supplier_id: String, amount: float = 1.0) -> void:
	if suppliers.has(supplier_id):
		suppliers[supplier_id]["relationship"] = clamp(
			suppliers[supplier_id]["relationship"] + amount, 0.0, 100.0)

func get_save_data() -> Dictionary:
	return {"pending_orders": pending_orders.duplicate(true), "suppliers": suppliers.duplicate(true)}

func restore_save_data(data: Dictionary) -> void:
	pending_orders = data.get("pending_orders", [])
	# Merge supplier state changes
	var saved_sups = data.get("suppliers", {})
	for sid in saved_sups:
		if suppliers.has(sid):
			suppliers[sid]["relationship"] = saved_sups[sid].get("relationship", 50.0)
