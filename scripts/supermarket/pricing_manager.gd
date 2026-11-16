extends Node
## PricingManager — retail prices, margins, discounts.

var prices: Dictionary = {}       # product_id -> retail_price
var discounts: Dictionary = {}    # product_id -> discount_pct (0.0-1.0)
var price_history: Dictionary = {}  # product_id -> Array of {day, price}

func _ready() -> void:
	ServiceRegistry.register("PricingManager", self)
	_load_default_prices()

func _load_default_prices() -> void:
	var pm = ServiceRegistry.get_service("ProductManager")
	if pm == null:
		return
	for pid in pm.products:
		prices[pid] = pm.products[pid].get("retail_price", 1.0)

func get_price(product_id: String) -> float:
	var base = prices.get(product_id, 1.0)
	var discount = discounts.get(product_id, 0.0)
	return base * (1.0 - discount)

func set_price(product_id: String, new_price: float) -> void:
	var old = prices.get(product_id, 0.0)
	prices[product_id] = max(0.01, new_price)
	if not price_history.has(product_id):
		price_history[product_id] = []
	price_history[product_id].append({"day": GameClock.game_day, "price": old})
	EventBus.price_changed.emit(product_id, prices[product_id])

func apply_discount(product_id: String, pct: float) -> void:
	discounts[product_id] = clamp(pct, 0.0, 0.9)

func remove_discount(product_id: String) -> void:
	discounts.erase(product_id)

func get_margin(product_id: String) -> float:
	var pm = ServiceRegistry.get_service("ProductManager")
	if pm == null:
		return 0.0
	var cost = pm.get_wholesale_cost(product_id)
	var retail = get_price(product_id)
	if retail <= 0:
		return 0.0
	return (retail - cost) / retail

func get_save_data() -> Dictionary:
	return {"prices": prices.duplicate(), "discounts": discounts.duplicate()}

func restore_save_data(data: Dictionary) -> void:
	prices = data.get("prices", {})
	discounts = data.get("discounts", {})
