extends Node
## ProductManager — data-driven product catalogue.

var products: Dictionary = {}  # product_id -> ProductData

func _ready() -> void:
	ServiceRegistry.register("ProductManager", self)
	_load_product_catalogue()

func _load_product_catalogue() -> void:
	var path = "res://data/products/products.json"
	if ResourceLoader.exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var list = json.get_data()
				for p in list:
					products[p["id"]] = p
			file.close()
	if products.size() < 10:
		_load_default_products()
	print("[ProductManager] Loaded %d products" % products.size())

func _load_default_products() -> void:
	var defaults = [
		# Fruits
		{"id":"fruit_apple","name":"Apple","category":"Fruits","brand":"FarmFresh","wholesale_cost":0.30,"retail_price":0.79,"weight":0.18,"shelf_life_days":14,"demand":0.8,"tags":["fresh","organic_possible"]},
		{"id":"fruit_banana","name":"Banana","category":"Fruits","brand":"TropicGold","wholesale_cost":0.20,"retail_price":0.59,"weight":0.12,"shelf_life_days":7,"demand":0.9,"tags":["fresh"]},
		{"id":"fruit_orange","name":"Orange","category":"Fruits","brand":"SunGrove","wholesale_cost":0.35,"retail_price":0.89,"weight":0.22,"shelf_life_days":21,"demand":0.7,"tags":["fresh","vitamin_c"]},
		{"id":"fruit_grapes","name":"Grapes","category":"Fruits","brand":"VineSelect","wholesale_cost":1.20,"retail_price":2.49,"weight":0.5,"shelf_life_days":10,"demand":0.6,"tags":["fresh"]},
		{"id":"fruit_strawberry","name":"Strawberries","category":"Fruits","brand":"BerryBest","wholesale_cost":1.80,"retail_price":3.49,"weight":0.3,"shelf_life_days":5,"demand":0.65,"tags":["fresh","seasonal"]},
		# Vegetables
		{"id":"veg_carrot","name":"Carrot","category":"Vegetables","brand":"EarthBest","wholesale_cost":0.25,"retail_price":0.69,"weight":0.15,"shelf_life_days":21,"demand":0.75,"tags":["fresh"]},
		{"id":"veg_potato","name":"Potato","category":"Vegetables","brand":"HomeHarvest","wholesale_cost":0.40,"retail_price":0.99,"weight":0.25,"shelf_life_days":60,"demand":0.85,"tags":["fresh","staple"]},
		{"id":"veg_tomato","name":"Tomato","category":"Vegetables","brand":"RedGarden","wholesale_cost":0.60,"retail_price":1.29,"weight":0.2,"shelf_life_days":10,"demand":0.8,"tags":["fresh"]},
		{"id":"veg_onion","name":"Onion","category":"Vegetables","brand":"HomeHarvest","wholesale_cost":0.20,"retail_price":0.59,"weight":0.2,"shelf_life_days":60,"demand":0.8,"tags":["fresh","staple"]},
		{"id":"veg_lettuce","name":"Lettuce","category":"Vegetables","brand":"GreenLeaf","wholesale_cost":0.70,"retail_price":1.49,"weight":0.3,"shelf_life_days":7,"demand":0.65,"tags":["fresh"]},
		# Dairy
		{"id":"dairy_milk","name":"Whole Milk 1L","category":"Dairy","brand":"DairyPure","wholesale_cost":0.60,"retail_price":1.29,"weight":1.0,"shelf_life_days":10,"demand":0.9,"tags":["dairy","refrigerated"]},
		{"id":"dairy_cheese","name":"Cheddar Cheese 200g","category":"Dairy","brand":"CheeseHaven","wholesale_cost":1.40,"retail_price":2.99,"weight":0.2,"shelf_life_days":60,"demand":0.7,"tags":["dairy","refrigerated"]},
		{"id":"dairy_butter","name":"Butter 250g","category":"Dairy","brand":"CreamFarm","wholesale_cost":1.20,"retail_price":2.49,"weight":0.25,"shelf_life_days":60,"demand":0.65,"tags":["dairy","refrigerated"]},
		{"id":"dairy_yogurt","name":"Greek Yogurt 500g","category":"Dairy","brand":"CulturedGood","wholesale_cost":0.90,"retail_price":1.99,"weight":0.5,"shelf_life_days":21,"demand":0.7,"tags":["dairy","refrigerated"]},
		{"id":"dairy_eggs","name":"Eggs 12-pack","category":"Dairy","brand":"HenHouse","wholesale_cost":1.50,"retail_price":2.99,"weight":0.72,"shelf_life_days":28,"demand":0.85,"tags":["fresh","refrigerated"]},
		# Meat
		{"id":"meat_chicken","name":"Chicken Breast 500g","category":"Meat","brand":"FarmPrime","wholesale_cost":2.80,"retail_price":5.49,"weight":0.5,"shelf_life_days":5,"demand":0.8,"tags":["meat","refrigerated","protein"]},
		{"id":"meat_beef","name":"Ground Beef 500g","category":"Meat","brand":"RanchSelect","wholesale_cost":3.50,"retail_price":6.99,"weight":0.5,"shelf_life_days":4,"demand":0.75,"tags":["meat","refrigerated","protein"]},
		{"id":"meat_pork","name":"Pork Chops 400g","category":"Meat","brand":"FarmPrime","wholesale_cost":2.20,"retail_price":4.49,"weight":0.4,"shelf_life_days":5,"demand":0.65,"tags":["meat","refrigerated"]},
		# Bakery
		{"id":"bakery_bread","name":"Whole Wheat Bread","category":"Bakery","brand":"BakeryCraft","wholesale_cost":1.00,"retail_price":2.29,"weight":0.5,"shelf_life_days":5,"demand":0.9,"tags":["bakery","staple"]},
		{"id":"bakery_croissant","name":"Croissant 4-pack","category":"Bakery","brand":"LaPatisserie","wholesale_cost":1.80,"retail_price":3.49,"weight":0.3,"shelf_life_days":3,"demand":0.6,"tags":["bakery"]},
		{"id":"bakery_muffin","name":"Blueberry Muffins 6-pack","category":"Bakery","brand":"BakeryCraft","wholesale_cost":2.00,"retail_price":3.99,"weight":0.4,"shelf_life_days":5,"demand":0.55,"tags":["bakery","snack"]},
		# Frozen
		{"id":"frozen_pizza","name":"Frozen Pizza","category":"Frozen","brand":"ItalPizza","wholesale_cost":2.50,"retail_price":4.99,"weight":0.5,"shelf_life_days":180,"demand":0.75,"tags":["frozen","convenience"]},
		{"id":"frozen_peas","name":"Frozen Peas 500g","category":"Frozen","brand":"GardenFrost","wholesale_cost":0.80,"retail_price":1.79,"weight":0.5,"shelf_life_days":365,"demand":0.6,"tags":["frozen","vegetable"]},
		# Drinks
		{"id":"drink_water","name":"Mineral Water 1.5L","category":"Drinks","brand":"AquaPure","wholesale_cost":0.25,"retail_price":0.79,"weight":1.5,"shelf_life_days":730,"demand":0.95,"tags":["drink","hydration"]},
		{"id":"drink_cola","name":"Cola 1.5L","category":"Drinks","brand":"BubblePop","wholesale_cost":0.60,"retail_price":1.49,"weight":1.5,"shelf_life_days":365,"demand":0.85,"tags":["drink","soda"]},
		{"id":"drink_juice","name":"Orange Juice 1L","category":"Drinks","brand":"SunGrove","wholesale_cost":0.90,"retail_price":1.99,"weight":1.0,"shelf_life_days":21,"demand":0.7,"tags":["drink","fruit_juice"]},
		{"id":"drink_coffee","name":"Ground Coffee 250g","category":"Drinks","brand":"BeanMaster","wholesale_cost":2.80,"retail_price":5.49,"weight":0.25,"shelf_life_days":365,"demand":0.75,"tags":["drink","coffee"]},
		{"id":"drink_tea","name":"Green Tea 20 bags","category":"Drinks","brand":"LeafTime","wholesale_cost":1.20,"retail_price":2.49,"weight":0.08,"shelf_life_days":730,"demand":0.65,"tags":["drink","tea"]},
		# Snacks
		{"id":"snack_chips","name":"Potato Chips 150g","category":"Snacks","brand":"CrunchBest","wholesale_cost":0.70,"retail_price":1.69,"weight":0.15,"shelf_life_days":180,"demand":0.8,"tags":["snack","salty"]},
		{"id":"snack_chocolate","name":"Chocolate Bar 100g","category":"Snacks","brand":"ChocoDeluxe","wholesale_cost":0.60,"retail_price":1.49,"weight":0.1,"shelf_life_days":365,"demand":0.75,"tags":["snack","sweet"]},
		{"id":"snack_crackers","name":"Crackers 200g","category":"Snacks","brand":"CrunchBest","wholesale_cost":0.80,"retail_price":1.79,"weight":0.2,"shelf_life_days":180,"demand":0.65,"tags":["snack"]},
		# Canned
		{"id":"canned_tuna","name":"Tuna Can 185g","category":"Canned","brand":"OceanCatch","wholesale_cost":1.00,"retail_price":2.19,"weight":0.185,"shelf_life_days":1095,"demand":0.65,"tags":["canned","protein"]},
		{"id":"canned_beans","name":"Baked Beans 400g","category":"Canned","brand":"HomeKitchen","wholesale_cost":0.40,"retail_price":0.99,"weight":0.4,"shelf_life_days":1095,"demand":0.7,"tags":["canned","staple"]},
		{"id":"canned_tomato","name":"Diced Tomatoes 400g","category":"Canned","brand":"RedGarden","wholesale_cost":0.35,"retail_price":0.89,"weight":0.4,"shelf_life_days":1095,"demand":0.75,"tags":["canned","cooking"]},
		# Household
		{"id":"household_soap","name":"Hand Soap 300ml","category":"Household","brand":"CleanLife","wholesale_cost":0.80,"retail_price":1.99,"weight":0.3,"shelf_life_days":1095,"demand":0.85,"tags":["hygiene"]},
		{"id":"household_shampoo","name":"Shampoo 400ml","category":"Household","brand":"HairCare+","wholesale_cost":1.80,"retail_price":3.99,"weight":0.4,"shelf_life_days":1095,"demand":0.75,"tags":["hygiene"]},
		{"id":"household_detergent","name":"Laundry Detergent 2kg","category":"Household","brand":"WashPro","wholesale_cost":3.50,"retail_price":7.99,"weight":2.0,"shelf_life_days":1095,"demand":0.8,"tags":["cleaning"]},
		{"id":"household_toilet_paper","name":"Toilet Paper 12-roll","category":"Household","brand":"SoftHome","wholesale_cost":2.80,"retail_price":5.99,"weight":1.2,"shelf_life_days":1095,"demand":0.95,"tags":["household","staple"]},
	]
	for p in defaults:
		# Add any missing fields
		if not p.has("description"):
			p["description"] = p["name"]
		if not p.has("quality"):
			p["quality"] = 3  # 1-5
		if not p.has("storage_requirements"):
			p["storage_requirements"] = "ambient"
		products[p["id"]] = p

func get_product(product_id: String) -> Dictionary:
	return products.get(product_id, {})

func get_products_by_category(category: String) -> Array:
	var result = []
	for id in products:
		if products[id].get("category", "") == category:
			result.append(products[id])
	return result

func get_all_categories() -> Array:
	var cats = {}
	for id in products:
		cats[products[id].get("category", "")] = true
	return cats.keys()

func get_wholesale_cost(product_id: String) -> float:
	return products.get(product_id, {}).get("wholesale_cost", 1.0)

func get_base_demand(product_id: String) -> float:
	return products.get(product_id, {}).get("demand", 0.5)

func get_shelf_life_days(product_id: String) -> int:
	return products.get(product_id, {}).get("shelf_life_days", 30)
