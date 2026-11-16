extends Node
## EconomyManager — city-wide economic simulation, demand, prices, taxes.

var city_funds: float = 0.0
var city_tax_rate: float = 0.08  # 8%
var inflation_rate: float = 0.0
var market_demand: Dictionary = {}     # product_id -> demand_modifier (0.5-2.0)
var market_prices: Dictionary = {}     # product_id -> current market price
var _update_timer: float = 0.0
const UPDATE_INTERVAL: float = 300.0  # every 5 real minutes

func _ready() -> void:
	ServiceRegistry.register("EconomyManager", self)
	_initialize_market()
	EventBus.product_sold.connect(_on_product_sold)
	EventBus.day_changed.connect(_on_day_changed)
	EventBus.season_changed.connect(_on_season_changed)

func _initialize_market() -> void:
	var pm = ServiceRegistry.get_service("ProductManager")
	if pm == null:
		return
	for pid in pm.products:
		market_demand[pid] = 1.0
		market_prices[pid] = pm.get_wholesale_cost(pid)

func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		_simulate_market()

func _simulate_market() -> void:
	for pid in market_demand:
		# Random demand fluctuation
		var change = randf_range(-0.05, 0.05)
		market_demand[pid] = clamp(market_demand[pid] + change, 0.4, 2.0)
		# Update wholesale prices
		if market_prices.has(pid):
			var base_change = randf_range(-0.02, 0.02)
			market_prices[pid] = max(0.1, market_prices[pid] * (1.0 + base_change + inflation_rate * 0.001))
			EventBus.market_price_updated.emit(pid, market_prices[pid])

func _on_product_sold(product_id: String, quantity: int, revenue: float) -> void:
	# Tax collection
	var tax = revenue * city_tax_rate
	city_funds += tax
	EventBus.tax_collected.emit(tax)
	# High sales reduce demand slightly
	if market_demand.has(product_id):
		market_demand[product_id] = clamp(market_demand[product_id] - quantity * 0.001, 0.4, 2.0)

func _on_day_changed(_day: int) -> void:
	# Slight demand recovery
	for pid in market_demand:
		market_demand[pid] = clamp(market_demand[pid] + 0.01, 0.4, 2.0)

func _on_season_changed(season: String) -> void:
	var pm = ServiceRegistry.get_service("ProductManager")
	if pm == null:
		return
	# Seasonal demand adjustments
	for pid in pm.products:
		var tags = pm.products[pid].get("tags", [])
		match season:
			"Summer":
				if "drink" in tags or "ice_cream" in tags:
					market_demand[pid] = clamp(market_demand.get(pid, 1.0) + 0.3, 0.4, 2.0)
				if "seasonal" in tags:
					market_demand[pid] = clamp(market_demand.get(pid, 1.0) + 0.2, 0.4, 2.0)
			"Winter":
				if "frozen" in tags:
					market_demand[pid] = clamp(market_demand.get(pid, 1.0) - 0.1, 0.4, 2.0)
			"Autumn":
				if "fruit" in tags:
					market_demand[pid] = clamp(market_demand.get(pid, 1.0) + 0.15, 0.4, 2.0)

func get_demand_modifier(product_id: String) -> float:
	return market_demand.get(product_id, 1.0)

func get_current_wholesale_price(product_id: String) -> float:
	return market_prices.get(product_id, 1.0)

func get_save_data() -> Dictionary:
	return {
		"city_funds": city_funds,
		"market_demand": market_demand.duplicate(),
		"market_prices": market_prices.duplicate(),
		"inflation_rate": inflation_rate,
	}

func restore_save_data(data: Dictionary) -> void:
	city_funds = data.get("city_funds", 0.0)
	market_demand = data.get("market_demand", {})
	market_prices = data.get("market_prices", {})
	inflation_rate = data.get("inflation_rate", 0.0)
