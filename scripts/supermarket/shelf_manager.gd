extends Node
## ShelfManager — tracks shelf placements, stocking state, and product display.

class_name ShelfManagerNode

var shelves: Dictionary = {}  # shelf_id -> ShelfData

func _ready() -> void:
	ServiceRegistry.register("ShelfManager", self)
	EventBus.inventory_changed.connect(_on_inventory_changed)
	EventBus.day_changed.connect(_on_day_changed)

func register_shelf(shelf_id: String, position: Vector3, capacity: int = 20, 
					compatible_categories: Array = ["all"]) -> void:
	shelves[shelf_id] = {
		"id": shelf_id,
		"position": {"x": position.x, "y": position.y, "z": position.z},
		"capacity": capacity,
		"compatible_categories": compatible_categories,
		"stock": {},         # product_id -> quantity displayed
		"total_items": 0,
		"assigned_product": "",
		"needs_restock": false,
		"cleanliness": 100.0,
	}

func stock_shelf(shelf_id: String, product_id: String, quantity: int) -> int:
	if not shelves.has(shelf_id):
		return 0
	var shelf = shelves[shelf_id]
	var space = shelf["capacity"] - shelf["total_items"]
	var to_place = min(quantity, space)
	if to_place <= 0:
		return 0
	# Pull from inventory
	var inv = ServiceRegistry.get_service("InventoryManager")
	if inv == null:
		return 0
	var actually_removed = inv.remove_stock(product_id, to_place)
	if actually_removed <= 0:
		return 0
	shelf["stock"][product_id] = shelf["stock"].get(product_id, 0) + actually_removed
	shelf["total_items"] += actually_removed
	shelf["assigned_product"] = product_id
	shelf["needs_restock"] = false
	EventBus.shelf_restocked.emit(shelf_id)
	return actually_removed

func take_from_shelf(shelf_id: String, product_id: String, quantity: int = 1) -> int:
	if not shelves.has(shelf_id):
		return 0
	var shelf = shelves[shelf_id]
	var available = shelf["stock"].get(product_id, 0)
	var taken = min(quantity, available)
	if taken <= 0:
		return 0
	shelf["stock"][product_id] -= taken
	if shelf["stock"][product_id] <= 0:
		shelf["stock"].erase(product_id)
	shelf["total_items"] -= taken
	# Check if restock needed
	if shelf["total_items"] < shelf["capacity"] * 0.3:
		shelf["needs_restock"] = true
		EventBus.shelf_empty.emit(shelf_id)
	return taken

func get_shelf_stock(shelf_id: String, product_id: String) -> int:
	return shelves.get(shelf_id, {}).get("stock", {}).get(product_id, 0)

func get_all_shelf_stock(product_id: String) -> int:
	var total = 0
	for sid in shelves:
		total += shelves[sid]["stock"].get(product_id, 0)
	return total

func find_product_on_shelf(product_id: String) -> String:
	for sid in shelves:
		if shelves[sid]["stock"].get(product_id, 0) > 0:
			return sid
	return ""

func get_shelves_needing_restock() -> Array:
	var result = []
	for sid in shelves:
		if shelves[sid]["needs_restock"]:
			result.append(sid)
	return result

func auto_stock_all_shelves() -> void:
	var inv = ServiceRegistry.get_service("InventoryManager")
	var pm = ServiceRegistry.get_service("ProductManager")
	if inv == null or pm == null:
		return
	for sid in shelves:
		var shelf = shelves[sid]
		if shelf["total_items"] >= shelf["capacity"] * 0.8:
			continue
		# Find best product to stock
		var product_id = shelf.get("assigned_product", "")
		if product_id == "" or not inv.has_stock(product_id):
			# Pick any available product
			var stock_counts = inv.get_all_stock_counts()
			for pid in stock_counts:
				if stock_counts[pid] > 0:
					product_id = pid
					break
		if product_id != "" and inv.has_stock(product_id):
			var space = shelf["capacity"] - shelf["total_items"]
			stock_shelf(sid, product_id, space)

func _on_inventory_changed(_store_id: String) -> void:
	# Check if any shelf needs restock and trigger notification
	var needs = get_shelves_needing_restock()
	if needs.size() > 0:
		pass  # Employees will handle this

func _on_day_changed(_day: int) -> void:
	# Slight cleanliness decay
	for sid in shelves:
		shelves[sid]["cleanliness"] = max(0.0, shelves[sid]["cleanliness"] - 2.0)

func get_save_data() -> Dictionary:
	return {"shelves": shelves.duplicate(true)}

func restore_save_data(data: Dictionary) -> void:
	shelves = data.get("shelves", {})
