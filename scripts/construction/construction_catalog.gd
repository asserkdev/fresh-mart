extends Node
## ConstructionCatalog — defines all placeable objects with costs and scenes.

var catalog: Dictionary = {}

func _ready() -> void:
	ServiceRegistry.register("ConstructionCatalog", self)
	_load_catalog()

func _load_catalog() -> void:
	catalog = {
		# Shelving
		"shelf_standard": {
			"id": "shelf_standard", "name": "Standard Shelf",
			"category": "Shelving", "cost": 150.0,
			"scene": "", "description": "A metal shelf for general merchandise.",
			"capacity": 20, "compatible_categories": ["all"],
		},
		"shelf_refrigerated": {
			"id": "shelf_refrigerated", "name": "Refrigerated Display",
			"category": "Shelving", "cost": 800.0,
			"scene": "", "description": "Open refrigerated display for dairy and drinks.",
			"capacity": 15, "compatible_categories": ["Dairy", "Drinks", "Meat"],
		},
		"shelf_freezer": {
			"id": "shelf_freezer", "name": "Freezer Unit",
			"category": "Shelving", "cost": 1200.0,
			"scene": "", "description": "Upright freezer unit for frozen products.",
			"capacity": 10, "compatible_categories": ["Frozen"],
		},
		# Checkout
		"checkout_counter": {
			"id": "checkout_counter", "name": "Checkout Counter",
			"category": "Checkout", "cost": 500.0,
			"scene": "", "description": "Staff checkout counter with scanner.",
			"capacity": 0, "compatible_categories": [],
		},
		"self_checkout": {
			"id": "self_checkout", "name": "Self-Checkout",
			"category": "Checkout", "cost": 2000.0,
			"scene": "", "description": "Customer-operated self-checkout machine.",
			"capacity": 0, "compatible_categories": [],
		},
		# Display
		"display_table": {
			"id": "display_table", "name": "Display Table",
			"category": "Display", "cost": 200.0,
			"scene": "", "description": "Flat display table for featured products.",
			"capacity": 25, "compatible_categories": ["all"],
		},
		"produce_stand": {
			"id": "produce_stand", "name": "Produce Stand",
			"category": "Display", "cost": 180.0,
			"scene": "", "description": "Slanted display for fresh produce.",
			"capacity": 30, "compatible_categories": ["Fruits", "Vegetables"],
		},
		# Storage
		"storage_rack": {
			"id": "storage_rack", "name": "Storage Rack",
			"category": "Storage", "cost": 120.0,
			"scene": "", "description": "Heavy-duty storage rack for back room.",
			"capacity": 50, "compatible_categories": ["all"],
		},
		# Lighting
		"floor_light": {
			"id": "floor_light", "name": "Floor Light",
			"category": "Lighting", "cost": 80.0,
			"scene": "", "description": "Recessed floor lighting.",
			"capacity": 0, "compatible_categories": [],
		},
		"ceiling_light": {
			"id": "ceiling_light", "name": "Ceiling Panel Light",
			"category": "Lighting", "cost": 60.0,
			"scene": "", "description": "LED ceiling panel.",
			"capacity": 0, "compatible_categories": [],
		},
		# Decoration
		"potted_plant": {
			"id": "potted_plant", "name": "Potted Plant",
			"category": "Decoration", "cost": 40.0,
			"scene": "", "description": "Indoor plant for store atmosphere.",
			"capacity": 0, "compatible_categories": [],
		},
		"sign_store": {
			"id": "sign_store", "name": "Store Sign",
			"category": "Decoration", "cost": 300.0,
			"scene": "", "description": "Illuminated store sign.",
			"capacity": 0, "compatible_categories": [],
		},
	}

func get_object(object_id: String) -> Dictionary:
	return catalog.get(object_id, {})

func get_object_cost(object_id: String) -> float:
	return catalog.get(object_id, {}).get("cost", 0.0)

func get_scene_path(object_id: String) -> String:
	return catalog.get(object_id, {}).get("scene", "")

func get_objects_by_category(category: String) -> Array:
	var result = []
	for id in catalog:
		if catalog[id]["category"] == category:
			result.append(catalog[id])
	return result

func get_all_categories() -> Array:
	var cats = {}
	for id in catalog:
		cats[catalog[id]["category"]] = true
	return cats.keys()
