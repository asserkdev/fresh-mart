extends Node3D
## ShelfInteractable — a shelf unit that registers itself with ShelfManager
## and responds to player interaction.

@export var shelf_id: String = ""
@export var shelf_capacity: int = 20
@export var compatible_categories: Array[String] = ["all"]
@export var assigned_product_id: String = ""

var _shelf_manager: Node = null
var _interaction_enabled: bool = true

func _ready() -> void:
	if shelf_id == "":
		shelf_id = "shelf_%s" % str(get_instance_id())
	# Register with ShelfManager
	call_deferred("_register_shelf")

func _register_shelf() -> void:
	_shelf_manager = ServiceRegistry.get_service("ShelfManager") if ServiceRegistry.has_service("ShelfManager") else null
	if _shelf_manager:
		_shelf_manager.register_shelf(shelf_id, global_position, shelf_capacity, compatible_categories)
		# Auto-stock if product assigned
		if assigned_product_id != "":
			_shelf_manager.stock_shelf(shelf_id, assigned_product_id, shelf_capacity)

func can_interact(_interactor) -> bool:
	return _interaction_enabled

func get_interaction_text() -> String:
	if _shelf_manager == null:
		return "Shelf"
	var total = _shelf_manager.shelves.get(shelf_id, {}).get("total_items", 0)
	var cap = shelf_capacity
	var product = _shelf_manager.shelves.get(shelf_id, {}).get("assigned_product", "")
	if product != "":
		var pm = ServiceRegistry.get_service("ProductManager")
		var pname = pm.get_product(product).get("name", product) if pm else product
		return "Shelf: %s (%d/%d)" % [pname, total, cap]
	return "Empty Shelf (%d/%d)" % [total, cap]

func interact(interactor) -> void:
	if _shelf_manager == null:
		return
	var shelf = _shelf_manager.shelves.get(shelf_id, {})
	var product = shelf.get("assigned_product", "")
	if product == "" or shelf.get("total_items", 0) == 0:
		EventBus.notification_requested.emit("Shelf is empty.", "info", 2.0)
		return
	# Player picks up one item
	var taken = _shelf_manager.take_from_shelf(shelf_id, product, 1)
	if taken > 0 and interactor.has_method("add_item"):
		interactor.add_item(product, taken)
		var pm = ServiceRegistry.get_service("ProductManager")
		var pname = pm.get_product(product).get("name", product) if pm else product
		EventBus.notification_requested.emit("Picked up: %s" % pname, "info", 1.5)

func get_persistent_state() -> Dictionary:
	if _shelf_manager == null:
		return {}
	return _shelf_manager.shelves.get(shelf_id, {}).duplicate(true)

func restore_persistent_state(data: Dictionary) -> void:
	call_deferred("_restore_state", data)

func _restore_state(data: Dictionary) -> void:
	if _shelf_manager == null:
		_shelf_manager = ServiceRegistry.get_service("ShelfManager") if ServiceRegistry.has_service("ShelfManager") else null
	if _shelf_manager and _shelf_manager.shelves.has(shelf_id):
		_shelf_manager.shelves[shelf_id] = data
