extends Node
## QuestManager — quest definitions, tracking, rewards.

var quests: Dictionary = {}       # quest_id -> definition
var active_quests: Array = []     # quest_ids
var completed_quests: Array = []  # quest_ids
var failed_quests: Array = []

func _ready() -> void:
	ServiceRegistry.register("QuestManager", self)
	_load_quest_definitions()
	EventBus.product_sold.connect(_on_product_sold)
	EventBus.employee_hired.connect(_on_employee_hired)
	EventBus.delivery_arrived.connect(_on_delivery_arrived)
	EventBus.business_level_changed.connect(_on_business_level_changed)
	# Auto-starts deferred so world has time to load
	call_deferred("_check_auto_starts")

func _load_quest_definitions() -> void:
	quests = {
		"quest_first_sale": {
			"id": "quest_first_sale",
			"title": "First Sale",
			"description": "Make your first sale. Stock a shelf and let a customer buy something.",
			"objectives": [{"id":"sell_1","type":"product_sold","target":1,"current":0,"text":"Sell 1 product"}],
			"rewards": {"money": 200.0, "reputation": 5.0},
			"prerequisites": [],
			"auto_start": true,
		},
		"quest_stock_up": {
			"id": "quest_stock_up",
			"title": "Open for Business",
			"description": "Order stock from a supplier and fill your shelves.",
			"objectives": [
				{"id":"order_stock","type":"delivery_arrived","target":1,"current":0,"text":"Receive 1 delivery"},
				{"id":"sell_10","type":"product_sold","target":10,"current":0,"text":"Sell 10 products"},
			],
			"rewards": {"money": 500.0, "reputation": 10.0},
			"prerequisites": ["quest_first_sale"],
			"auto_start": false,
		},
		"quest_hire_first": {
			"id": "quest_hire_first",
			"title": "Growing Team",
			"description": "Hire your first employee to help run the store.",
			"objectives": [{"id":"hire_1","type":"employee_hired","target":1,"current":0,"text":"Hire 1 employee"}],
			"rewards": {"money": 300.0, "reputation": 8.0},
			"prerequisites": ["quest_first_sale"],
			"auto_start": false,
		},
		"quest_reach_level2": {
			"id": "quest_reach_level2",
			"title": "Growing Business",
			"description": "Grow your store to level 2.",
			"objectives": [{"id":"level2","type":"business_level","target":2,"current":1,"text":"Reach store level 2"}],
			"rewards": {"money": 1500.0, "reputation": 20.0},
			"prerequisites": ["quest_stock_up", "quest_hire_first"],
			"auto_start": false,
		},
		"quest_meet_farmer": {
			"id": "quest_meet_farmer",
			"title": "Local Supplier",
			"description": "Find the farmer James Patel in the Suburban District and strike a deal for fresh produce.",
			"objectives": [{"id":"meet_james","type":"npc_talked","target":"npc_004","current":"","text":"Talk to James Patel"}],
			"rewards": {"money": 400.0, "new_supplier": "supplier_james_farm"},
			"prerequisites": ["quest_first_sale"],
			"auto_start": false,
		},
	}

func get_available_quests() -> Array:
	var available = []
	for qid in quests:
		if qid in active_quests or qid in completed_quests or qid in failed_quests:
			continue
		var q = quests[qid]
		var prereqs_met = true
		for prereq in q.get("prerequisites", []):
			if not prereq in completed_quests:
				prereqs_met = false
				break
		if prereqs_met:
			available.append(qid)
	return available

func start_quest(quest_id: String) -> bool:
	if quest_id in active_quests or quest_id in completed_quests:
		return false
	if not quests.has(quest_id):
		return false
	active_quests.append(quest_id)
	EventBus.quest_started.emit(quest_id)
	EventBus.notification_requested.emit(
		"New quest: %s" % quests[quest_id]["title"], "quest", 4.0)
	return true

func _check_auto_starts() -> void:
	for qid in quests:
		if quests[qid].get("auto_start", false) and qid not in active_quests and qid not in completed_quests:
			start_quest(qid)

func update_objective(quest_id: String, objective_id: String, value: Variant) -> void:
	if not quest_id in active_quests:
		return
	var q = quests.get(quest_id)
	if q == null:
		return
	for obj in q["objectives"]:
		if obj["id"] == objective_id:
			obj["current"] = value
			EventBus.quest_objective_updated.emit(quest_id, objective_id)
			if _is_objective_complete(obj):
				_check_quest_completion(quest_id)
			break

func _is_objective_complete(obj: Dictionary) -> bool:
	match obj.get("type", ""):
		"product_sold", "delivery_arrived", "employee_hired", "business_level":
			return obj["current"] >= obj["target"]
		"npc_talked":
			return obj["current"] == obj["target"]
	return false

func _check_quest_completion(quest_id: String) -> void:
	var q = quests.get(quest_id)
	if q == null:
		return
	for obj in q["objectives"]:
		if not _is_objective_complete(obj):
			return
	# All objectives met
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	_grant_rewards(q)
	EventBus.quest_completed.emit(quest_id)
	EventBus.notification_requested.emit("Quest completed: %s!" % q["title"], "success", 5.0)
	# Check new available quests
	for available_id in get_available_quests():
		var aq = quests[available_id]
		if aq.get("auto_start", false):
			start_quest(available_id)

func _grant_rewards(quest: Dictionary) -> void:
	var rewards = quest.get("rewards", {})
	if rewards.has("money"):
		var sm = ServiceRegistry.get_service("SupermarketManager")
		if sm:
			sm.business_money += rewards["money"]
			EventBus.player_money_changed.emit(sm.business_money)
	if rewards.has("reputation"):
		var sm = ServiceRegistry.get_service("SupermarketManager")
		if sm:
			sm.update_reputation(rewards["reputation"])

# Event handlers that advance quest objectives
func _on_product_sold(_pid: String, _qty: int, _rev: float) -> void:
	for qid in active_quests:
		var q = quests.get(qid)
		if q == null:
			continue
		for obj in q["objectives"]:
			if obj["type"] == "product_sold":
				obj["current"] += 1
				EventBus.quest_objective_updated.emit(qid, obj["id"])
				_check_quest_completion(qid)

func _on_employee_hired(_eid: String) -> void:
	for qid in active_quests:
		var q = quests.get(qid)
		if q == null:
			continue
		for obj in q["objectives"]:
			if obj["type"] == "employee_hired":
				obj["current"] += 1
				_check_quest_completion(qid)

func _on_delivery_arrived(_sid: String, _oid: String) -> void:
	for qid in active_quests:
		var q = quests.get(qid)
		if q == null:
			continue
		for obj in q["objectives"]:
			if obj["type"] == "delivery_arrived":
				obj["current"] += 1
				_check_quest_completion(qid)

func _on_business_level_changed(_store_id: String, new_level: int) -> void:
	for qid in active_quests:
		var q = quests.get(qid)
		if q == null:
			continue
		for obj in q["objectives"]:
			if obj["type"] == "business_level":
				obj["current"] = new_level
				_check_quest_completion(qid)

func get_save_data() -> Dictionary:
	var quest_states = {}
	for qid in quests:
		quest_states[qid] = {"objectives": quests[qid]["objectives"].duplicate(true)}
	return {
		"active": active_quests.duplicate(),
		"completed": completed_quests.duplicate(),
		"failed": failed_quests.duplicate(),
		"quest_states": quest_states,
	}

func restore_save_data(data: Dictionary) -> void:
	active_quests = data.get("active", [])
	completed_quests = data.get("completed", [])
	failed_quests = data.get("failed", [])
	var saved_states = data.get("quest_states", {})
	for qid in saved_states:
		if quests.has(qid):
			quests[qid]["objectives"] = saved_states[qid]["objectives"]
