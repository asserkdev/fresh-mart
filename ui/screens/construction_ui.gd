extends Control
## ConstructionUI — browse catalog, select objects, place/rotate/remove.

@onready var category_list: ItemList = $Panel/HSplit/LeftPanel/CategoryList
@onready var object_list: ItemList = $Panel/HSplit/LeftPanel/ObjectList
@onready var preview_label: Label = $Panel/HSplit/RightPanel/PreviewLabel
@onready var cost_label: Label = $Panel/HSplit/RightPanel/CostLabel
@onready var desc_label: Label = $Panel/HSplit/RightPanel/DescLabel
@onready var btn_place: Button = $Panel/HSplit/RightPanel/BtnPlace
@onready var btn_rotate: Button = $Panel/HSplit/RightPanel/BtnRotate
@onready var btn_cancel: Button = $Panel/HSplit/RightPanel/BtnCancel
@onready var btn_remove: Button = $Panel/HSplit/RightPanel/BtnRemove
@onready var balance_label: Label = $Panel/BalanceLabel

var _selected_object_id: String = ""
var _placement_system: Node = null
var _catalog: Node = null

func _ready() -> void:
	_placement_system = ServiceRegistry.get_service("PlacementSystem")
	_catalog = ServiceRegistry.get_service("ConstructionCatalog")
	if _catalog == null or _placement_system == null:
		push_error("[ConstructionUI] Required services not found.")
		return
	_populate_categories()
	category_list.item_selected.connect(_on_category_selected)
	object_list.item_selected.connect(_on_object_selected)
	btn_place.pressed.connect(_on_place)
	btn_rotate.pressed.connect(_on_rotate)
	btn_cancel.pressed.connect(_on_cancel)
	btn_remove.pressed.connect(_on_remove_mode)
	_placement_system.enter_construction_mode()
	_update_balance()
	EventBus.player_money_changed.connect(func(_m): _update_balance())

func _populate_categories() -> void:
	category_list.clear()
	for cat in _catalog.get_all_categories():
		category_list.add_item(cat)

func _on_category_selected(idx: int) -> void:
	var category = category_list.get_item_text(idx)
	object_list.clear()
	for obj in _catalog.get_objects_by_category(category):
		object_list.add_item(obj["name"])
		object_list.set_item_metadata(object_list.item_count - 1, obj["id"])

func _on_object_selected(idx: int) -> void:
	_selected_object_id = object_list.get_item_metadata(idx)
	var obj = _catalog.get_object(_selected_object_id)
	preview_label.text = obj.get("name", "")
	cost_label.text = "$%.0f" % obj.get("cost", 0.0)
	desc_label.text = obj.get("description", "")
	btn_place.disabled = false
	_placement_system.select_object(_selected_object_id)

func _on_place() -> void:
	if _selected_object_id == "":
		return
	var success = _placement_system.confirm_placement()
	if success:
		EventBus.notification_requested.emit("Placed %s" % _selected_object_id, "success", 2.0)
		_update_balance()

func _on_rotate() -> void:
	_placement_system.rotate_preview(1)

func _on_remove_mode() -> void:
	EventBus.notification_requested.emit("Click an object to remove it.", "info", 3.0)

func _on_cancel() -> void:
	_placement_system.exit_construction_mode()
	queue_free()

func _update_balance() -> void:
	var sm = ServiceRegistry.get_service("SupermarketManager")
	if sm:
		balance_label.text = "Balance: $%.2f" % sm.business_money

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_object"):
		_placement_system.rotate_preview(1)
