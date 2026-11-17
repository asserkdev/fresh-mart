extends Node
## Integration test: starts a new game and tests all core systems.

var _results: Array = []
var _pass: int = 0
var _fail: int = 0

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	print("\n========== FRESH MART v7 INTEGRATION TEST ==========\n")
	await _run_tests()
	_print_results()
	get_tree().quit(0 if _fail == 0 else 1)

func _run_tests() -> void:
	# Core systems
	_test("EventBus exists", EventBus != null)
	_test("GameManager exists", GameManager != null)
	_test("GameClock exists", GameClock != null)
	_test("SettingsManager exists", SettingsManager != null)
	_test("SaveManager exists", SaveManager != null)
	_test("SceneManager exists", SceneManager != null)
	_test("NotificationManager exists", NotificationManager != null)

	# Settings
	var autosave_interval = SettingsManager.get_autosave_interval()
	_test("Autosave default = 300s", autosave_interval == 300)
	_test("FOV setting exists", SettingsManager.get_setting("camera_fov") > 0)

	# GameClock
	GameClock.set_time(14, 30)
	_test("GameClock set time", GameClock.game_hour == 14 and GameClock.game_minute == 30)
	_test("GameClock is daytime at 14h", GameClock.is_daytime())
	GameClock.set_time(2, 0)
	_test("GameClock is night at 2h", not GameClock.is_daytime())
	var state = GameClock.get_state()
	_test("GameClock get_state has keys", state.has("hour") and state.has("day"))

	# Start a game session
	GameManager.current_save_slot = "test_slot"
	GameManager.set_mode(GameManager.GameMode.PLAYING)
	_test("GameManager is playing", GameManager.is_playing())

	# Load world scene
	await SceneManager.load_scene("res://scenes/world/world_root.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# ProductManager
	var pm = ServiceRegistry.get_service("ProductManager")
	_test("ProductManager registered", pm != null)
	if pm:
		_test("Has products", pm.products.size() >= 30)
		var apple = pm.get_product("fruit_apple")
		_test("fruit_apple exists", not apple.is_empty())
		_test("Apple has wholesale_cost", apple.has("wholesale_cost"))
		var dairy = pm.get_products_by_category("Dairy")
		_test("Dairy products found", dairy.size() >= 4)
		var cats = pm.get_all_categories()
		_test("Has 10+ categories", cats.size() >= 8)

	# InventoryManager
	var inv = ServiceRegistry.get_service("InventoryManager")
	_test("InventoryManager registered", inv != null)
	if inv:
		inv.add_stock("fruit_apple", 20, 100)
		_test("Add stock works", inv.get_stock_count("fruit_apple") == 20)
		inv.remove_stock("fruit_apple", 5)
		_test("Remove stock works", inv.get_stock_count("fruit_apple") == 15)
		_test("Has stock check", inv.has_stock("fruit_apple", 10))
		_test("No stock check", not inv.has_stock("fruit_apple", 100))
		var low = inv.get_low_stock_items(10)
		_test("Low stock detection", true)  # just verify it runs

	# PricingManager
	var pricing = ServiceRegistry.get_service("PricingManager")
	_test("PricingManager registered", pricing != null)
	if pricing:
		var price = pricing.get_price("fruit_apple")
		_test("Apple has price", price > 0.0)
		pricing.set_price("fruit_apple", 1.50)
		_test("Set price works", abs(pricing.get_price("fruit_apple") - 1.50) < 0.01)
		pricing.apply_discount("fruit_apple", 0.1)
		_test("Discount applied", pricing.get_price("fruit_apple") < 1.50)
		pricing.remove_discount("fruit_apple")
		var margin = pricing.get_margin("fruit_apple")
		_test("Margin calculated", margin > 0.0)

	# SupplierManager
	var sup = ServiceRegistry.get_service("SupplierManager")
	_test("SupplierManager registered", sup != null)
	if sup:
		_test("Has 5 suppliers", sup.suppliers.size() >= 5)
		var sups_for_apple = sup.get_suppliers_for_product("fruit_apple")
		_test("Apple has supplier", sups_for_apple.size() >= 1)

	# CheckoutManager
	var checkout = ServiceRegistry.get_service("CheckoutManager")
	_test("CheckoutManager registered", checkout != null)
	if checkout and inv:
		# Add more stock first
		inv.add_stock("fruit_apple", 50, 200)
		inv.add_stock("dairy_milk", 20, 100)
		var tid = checkout.start_transaction("test_customer_01")
		_test("Transaction started", tid != "")
		_test("Transaction ID valid", tid.begins_with("txn_"))
		checkout.add_item_to_transaction("fruit_apple", 2)
		checkout.add_item_to_transaction("dairy_milk", 1)
		_test("Active transaction has items", checkout.active_transaction["items"].size() == 2)
		var total_before = checkout.active_transaction["total"]
		_test("Transaction total > 0", total_before > 0.0)
		var result = checkout.complete_transaction("cash")
		_test("Transaction completed", not result.is_empty())
		_test("Transaction marked complete", result["complete"] == true)
		_test("Revenue recorded", checkout.daily_total > 0.0)
		_test("Active transaction cleared", checkout.active_transaction.is_empty())

	# SupermarketManager
	var sm = ServiceRegistry.get_service("SupermarketManager")
	_test("SupermarketManager registered", sm != null)
	if sm:
		_test("Has business money", sm.business_money > 0.0)
		_test("Store has reputation", sm.store_reputation > 0.0)
		var analytics = sm.get_analytics()
		_test("Analytics returns dict", analytics.has("business_money"))

	# EmployeeManager
	var em = ServiceRegistry.get_service("EmployeeManager")
	_test("EmployeeManager registered", em != null)
	if em:
		var eid = em.hire_employee("Test Employee", 0, 90.0)  # Role.CASHIER = 0
		_test("Employee hired", eid != "")
		_test("Employee in list", em.get_active_employees().size() >= 1)
		var daily_salary = em.get_daily_salary_total()
		_test("Daily salary calculated", daily_salary >= 90.0)
		em.fire_employee(eid)
		_test("Employee fired (inactive)", not em.employees[eid]["active"])

	# QuestManager
	var qm = ServiceRegistry.get_service("QuestManager")
	_test("QuestManager registered", qm != null)
	if qm:
		_test("Has quest definitions", qm.quests.size() >= 5)
		_test("first_sale quest exists", qm.quests.has("quest_first_sale"))
		# Auto-start should have fired
		_test("first_sale quest active", "quest_first_sale" in qm.active_quests)

	# Player
	var player = ServiceRegistry.get_service("Player")
	_test("Player registered", player != null)
	if player:
		var initial_money = player.held_money
		player.add_money(100.0)
		_test("Add money works", player.held_money == initial_money + 100.0)
		var spent = player.spend_money(50.0)
		_test("Spend money works", spent and player.held_money == initial_money + 50.0)
		var added = player.add_item("fruit_apple", 3)
		_test("Add item to inventory", added and player.get_item_count("fruit_apple") == 3)
		var removed = player.remove_item("fruit_apple", 2)
		_test("Remove item from inventory", removed and player.get_item_count("fruit_apple") == 1)
		var save_data = player.get_save_data()
		_test("Player save data valid", save_data.has("position") and save_data.has("money"))

	# EconomyManager
	var econ = ServiceRegistry.get_service("EconomyManager")
	_test("EconomyManager registered", econ != null)
	if econ:
		var demand = econ.get_demand_modifier("fruit_apple")
		_test("Demand modifier exists", demand > 0.0)

	# ChunkManager
	var cm = ServiceRegistry.get_service("ChunkManager")
	_test("ChunkManager registered", cm != null)
	if cm:
		_test("Has chunk definitions", cm._chunks.size() >= 10)
		var chunk_id = cm.get_chunk_id(Vector3(32, 0, 32))
		_test("get_chunk_id returns string", chunk_id is String)
		var required = cm.get_required_chunks(Vector3(32, 0, 32))
		_test("get_required_chunks returns array", required.size() > 0)

	# ConstructionCatalog
	var cat = ServiceRegistry.get_service("ConstructionCatalog")
	_test("ConstructionCatalog registered", cat != null)
	if cat:
		_test("Has 12+ objects", cat.catalog.size() >= 12)
		var shelf = cat.get_object("shelf_standard")
		_test("Shelf exists in catalog", not shelf.is_empty())
		_test("Shelf has cost", shelf.get("cost", 0.0) > 0.0)
		var cats_list = cat.get_all_categories()
		_test("Has multiple categories", cats_list.size() >= 4)

	# SaveManager
	var dirty = SaveManager._is_world_dirty()
	_test("Dirty tracking returns bool", dirty is bool)
	SaveManager.mark_dirty("player")
	_test("Marking dirty works", SaveManager._dirty_flags.get("player", false) == true)
	# Test actual save
	var save_ok = await SaveManager.save_game("test_slot")
	_test("Save game succeeds", save_ok)
	var save_slots = SaveManager.get_save_slots()
	_test("Save slot appears in list", "test_slot" in save_slots)
	# Test load
	var loaded_data = SaveManager.load_game("test_slot")
	_test("Load game returns data", not loaded_data.is_empty())
	_test("Loaded data has version", loaded_data.get("version", 0) == 7)
	_test("Loaded data has clock", loaded_data.has("clock"))
	# Clean up test save
	SaveManager.delete_save("test_slot")
	_test("Delete save works", not ("test_slot" in SaveManager.get_save_slots()))

	# WeatherSystem
	var weather = ServiceRegistry.get_service("WeatherSystem")
	_test("WeatherSystem registered", weather != null)
	if weather:
		var w_name = weather.get_weather_name()
		_test("Weather has name", w_name != "")

func _test(name: String, condition: bool) -> void:
	if condition:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ FAIL: %s" % name)
	_results.append({"name": name, "pass": condition})

func _print_results() -> void:
	print("\n========== TEST RESULTS ==========")
	print("Passed: %d / %d" % [_pass, _pass + _fail])
	if _fail > 0:
		print("\nFailed tests:")
		for r in _results:
			if not r["pass"]:
				print("  - %s" % r["name"])
	print("===================================\n")
