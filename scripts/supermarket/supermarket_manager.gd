extends Node
## SupermarketManager — coordinates all supermarket subsystems.

var store_name: String = "Fresh Mart"
var store_level: int = 1
var store_reputation: float = 50.0  # 0-100
var total_revenue: float = 0.0
var total_expenses: float = 0.0
var business_money: float = 10000.0
var daily_revenue: float = 0.0
var daily_expenses: float = 0.0

var _product_manager: Node = null
var _inventory_manager: Node = null
var _shelf_manager: Node = null
var _checkout_manager: Node = null
var _customer_manager: Node = null
var _supplier_manager: Node = null
var _employee_manager: Node = null
var _pricing_manager: Node = null

func _ready() -> void:
	ServiceRegistry.register("SupermarketManager", self)
	# Connect events
	EventBus.product_sold.connect(_on_product_sold)
	EventBus.product_purchased.connect(_on_product_purchased)
	EventBus.day_changed.connect(_on_day_changed)
	# Subsystems register themselves in their own _ready(); call after one frame
	call_deferred("_post_init")

func _post_init() -> void:
	initialize_subsystems()
	check_level_up()

func initialize_subsystems() -> void:
	# These are set by child nodes that registered themselves
	_product_manager = ServiceRegistry.get_service("ProductManager")
	_inventory_manager = ServiceRegistry.get_service("InventoryManager")
	_pricing_manager = ServiceRegistry.get_service("PricingManager")
	_checkout_manager = ServiceRegistry.get_service("CheckoutManager")
	_supplier_manager = ServiceRegistry.get_service("SupplierManager")
	_employee_manager = ServiceRegistry.get_service("EmployeeManager")
	# Optional systems (may not be loaded yet)
	_shelf_manager = ServiceRegistry.get_service("ShelfManager") if ServiceRegistry.has_service("ShelfManager") else null
	_customer_manager = ServiceRegistry.get_service("CustomerManager") if ServiceRegistry.has_service("CustomerManager") else null

func _on_product_sold(product_id: String, quantity: int, revenue: float) -> void:
	total_revenue += revenue
	daily_revenue += revenue
	business_money += revenue
	EventBus.player_money_changed.emit(business_money)

func _on_product_purchased(product_id: String, quantity: int, cost: float) -> void:
	total_expenses += cost
	daily_expenses += cost
	business_money -= cost
	EventBus.player_money_changed.emit(business_money)

func _on_day_changed(_day: int) -> void:
	# Reset daily counters
	daily_revenue = 0.0
	daily_expenses = 0.0
	# Pay salaries
	if _employee_manager:
		var salary_cost = _employee_manager.get_daily_salary_total()
		business_money -= salary_cost
		daily_expenses += salary_cost
		EventBus.expense_recorded.emit("salaries", salary_cost)

func add_expense(category: String, amount: float) -> void:
	business_money -= amount
	total_expenses += amount
	daily_expenses += amount
	EventBus.expense_recorded.emit(category, amount)

func get_profit_today() -> float:
	return daily_revenue - daily_expenses

func get_total_profit() -> float:
	return total_revenue - total_expenses

func update_reputation(delta: float) -> void:
	store_reputation = clamp(store_reputation + delta, 0.0, 100.0)

func check_level_up() -> void:
	var thresholds = [0, 5000, 20000, 60000, 150000, 400000]
	var new_level = 1
	for i in range(1, thresholds.size()):
		if total_revenue >= thresholds[i]:
			new_level = i + 1
	if new_level > store_level:
		store_level = new_level
		EventBus.business_level_changed.emit("supermarket", store_level)
		EventBus.notification_requested.emit("Store reached level %d!" % store_level, "success", 4.0)

func get_analytics() -> Dictionary:
	return {
		"store_name": store_name,
		"store_level": store_level,
		"reputation": store_reputation,
		"business_money": business_money,
		"total_revenue": total_revenue,
		"total_expenses": total_expenses,
		"daily_revenue": daily_revenue,
		"daily_expenses": daily_expenses,
	}

func get_save_data() -> Dictionary:
	var data = get_analytics()
	return data

func restore_save_data(d: Dictionary) -> void:
	store_name = d.get("store_name", "Fresh Mart")
	store_level = d.get("store_level", 1)
	store_reputation = d.get("reputation", 50.0)
	business_money = d.get("business_money", 10000.0)
	total_revenue = d.get("total_revenue", 0.0)
	total_expenses = d.get("total_expenses", 0.0)
