extends Node
## InventoryManager — stock, storage, expiration, transfers.

var stock: Dictionary = {}      # product_id -> Array of {quantity, expiry_day, batch_id}
var storage_capacity: int = 500  # total units
var total_units: int = 0

func _ready() -> void:
	ServiceRegistry.register("InventoryManager", self)
	EventBus.day_changed.connect(_on_day_changed)

func add_stock(product_id: String, quantity: int, expiry_day: int = -1) -> void:
	if not stock.has(product_id):
		stock[product_id] = []
	var batch_id = "%s_%d_%d" % [product_id, GameClock.game_day, randi()]
	stock[product_id].append({"quantity": quantity, "expiry_day": expiry_day, "batch_id": batch_id})
	total_units += quantity
	EventBus.inventory_changed.emit("supermarket")

func remove_stock(product_id: String, quantity: int) -> int:
	if not stock.has(product_id):
		return 0
	var removed = 0
	var batches = stock[product_id]
	var i = 0
	while i < batches.size() and removed < quantity:
		var need = quantity - removed
		var available = batches[i]["quantity"]
		if available <= need:
			removed += available
			batches.remove_at(i)
		else:
			batches[i]["quantity"] -= need
			removed += need
			i += 1
	total_units -= removed
	EventBus.inventory_changed.emit("supermarket")
	return removed

func get_stock_count(product_id: String) -> int:
	var total = 0
	for batch in stock.get(product_id, []):
		total += batch["quantity"]
	return total

func get_all_stock_counts() -> Dictionary:
	var result = {}
	for pid in stock:
		result[pid] = get_stock_count(pid)
	return result

func has_stock(product_id: String, quantity: int = 1) -> bool:
	return get_stock_count(product_id) >= quantity

func _on_day_changed(day: int) -> void:
	_check_expiration(day)

func _check_expiration(current_day: int) -> void:
	for pid in stock:
		var batches = stock[pid]
		var i = 0
		while i < batches.size():
			var b = batches[i]
			if b["expiry_day"] > 0 and b["expiry_day"] < current_day:
				var expired_qty = b["quantity"]
				total_units -= expired_qty
				batches.remove_at(i)
				EventBus.product_expired.emit(pid, expired_qty)
				EventBus.notification_requested.emit(
					"%d units of %s expired!" % [expired_qty, pid], "warning", 3.0)
			else:
				i += 1

func is_capacity_available(quantity: int = 1) -> bool:
	return total_units + quantity <= storage_capacity

func get_low_stock_items(threshold: int = 5) -> Array:
	var low = []
	for pid in stock:
		if get_stock_count(pid) <= threshold:
			low.append(pid)
	return low

func get_save_data() -> Dictionary:
	return {"stock": stock.duplicate(true), "storage_capacity": storage_capacity}

func restore_save_data(data: Dictionary) -> void:
	stock = data.get("stock", {})
	storage_capacity = data.get("storage_capacity", 500)
	total_units = 0
	for pid in stock:
		for batch in stock[pid]:
			total_units += batch["quantity"]
