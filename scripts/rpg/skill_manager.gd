extends Node
## SkillManager — skill trees that affect real gameplay.

var skills: Dictionary = {}
var skill_points: int = 0
var total_xp: int = 0

const SKILL_DEFINITIONS = {
	# Retail Management
	"retail_efficiency": {
		"name": "Retail Efficiency", "tree": "retail",
		"description": "Customers browse 10% faster per level.",
		"max_level": 5, "cost": 1, "effect": "customer_speed", "value_per_level": 0.1
	},
	"pricing_mastery": {
		"name": "Pricing Mastery", "tree": "retail",
		"description": "Unlock detailed price analysis. +5% margin per level.",
		"max_level": 5, "cost": 2, "effect": "margin_bonus", "value_per_level": 0.05,
		"requires": "retail_efficiency"
	},
	"customer_service": {
		"name": "Customer Service", "tree": "retail",
		"description": "Reputation gains 20% more effective per level.",
		"max_level": 3, "cost": 2, "effect": "reputation_gain", "value_per_level": 0.2,
		"requires": "retail_efficiency"
	},
	# Finance
	"bookkeeping": {
		"name": "Bookkeeping", "tree": "finance",
		"description": "Unlock financial analytics. Reduce tax rate 1% per level.",
		"max_level": 3, "cost": 1, "effect": "tax_reduction", "value_per_level": 0.01
	},
	"investment": {
		"name": "Investment", "tree": "finance",
		"description": "Business money earns 2% interest per game month per level.",
		"max_level": 5, "cost": 2, "effect": "interest_rate", "value_per_level": 0.02,
		"requires": "bookkeeping"
	},
	# Logistics
	"supply_chain": {
		"name": "Supply Chain", "tree": "logistics",
		"description": "Delivery time reduced by 1 day per level (min 1).",
		"max_level": 2, "cost": 2, "effect": "delivery_speed", "value_per_level": 1
	},
	"bulk_buying": {
		"name": "Bulk Buying", "tree": "logistics",
		"description": "Wholesale cost reduced 3% per level.",
		"max_level": 5, "cost": 2, "effect": "wholesale_discount", "value_per_level": 0.03,
		"requires": "supply_chain"
	},
	# Construction
	"architecture": {
		"name": "Architecture", "tree": "construction",
		"description": "Unlock more building objects. Construction cost -5% per level.",
		"max_level": 3, "cost": 1, "effect": "construction_discount", "value_per_level": 0.05
	},
	# Negotiation
	"negotiation": {
		"name": "Negotiation", "tree": "negotiation",
		"description": "Supplier relationship gains +10% per level.",
		"max_level": 5, "cost": 1, "effect": "relationship_gain", "value_per_level": 0.1
	},
	"contracts": {
		"name": "Contract Expertise", "tree": "negotiation",
		"description": "Unlock long-term contracts. Better terms per level.",
		"max_level": 3, "cost": 3, "effect": "contract_quality", "value_per_level": 1,
		"requires": "negotiation"
	},
	# Marketing
	"advertising": {
		"name": "Advertising", "tree": "marketing",
		"description": "Increase customer spawn rate 15% per level.",
		"max_level": 4, "cost": 2, "effect": "customer_rate", "value_per_level": 0.15
	},
	"branding": {
		"name": "Branding", "tree": "marketing",
		"description": "Store becomes recognizable — +3 reputation per game week.",
		"max_level": 3, "cost": 3, "effect": "passive_reputation", "value_per_level": 3,
		"requires": "advertising"
	},
}

func _ready() -> void:
	ServiceRegistry.register("SkillManager", self)
	# Initialize all skills at level 0
	for skill_id in SKILL_DEFINITIONS:
		skills[skill_id] = {"level": 0, "xp_invested": 0}
	# Give starting skill points
	skill_points = 2
	EventBus.day_changed.connect(_on_day_changed)

func can_unlock(skill_id: String) -> bool:
	var def = SKILL_DEFINITIONS.get(skill_id, {})
	if def.is_empty():
		return false
	var current_level = skills[skill_id]["level"]
	if current_level >= def.get("max_level", 1):
		return false
	if skill_points < def.get("cost", 1):
		return false
	var requires = def.get("requires", "")
	if requires != "" and skills.get(requires, {}).get("level", 0) == 0:
		return false
	return true

func unlock_skill(skill_id: String) -> bool:
	if not can_unlock(skill_id):
		return false
	var def = SKILL_DEFINITIONS[skill_id]
	skills[skill_id]["level"] += 1
	skill_points -= def.get("cost", 1)
	EventBus.skill_unlocked.emit(skill_id)
	EventBus.notification_requested.emit(
		"Skill upgraded: %s (Level %d)" % [def["name"], skills[skill_id]["level"]], "success", 3.0)
	_apply_skill_effect(skill_id)
	return true

func _apply_skill_effect(skill_id: String) -> void:
	var def = SKILL_DEFINITIONS.get(skill_id, {})
	var level = skills[skill_id]["level"]
	var effect = def.get("effect", "")
	var value = def.get("value_per_level", 0.0) * level
	match effect:
		"tax_reduction":
			var econ = ServiceRegistry.get_service("EconomyManager")
			if econ:
				econ.city_tax_rate = max(0.01, econ.city_tax_rate - def["value_per_level"])
		"customer_rate":
			var cm = ServiceRegistry.get_service("CustomerManager")
			if cm:
				cm._spawn_interval = max(5.0, cm._spawn_interval * (1.0 - def["value_per_level"]))

func add_xp(amount: int) -> void:
	total_xp += amount
	# Every 500 XP = 1 skill point
	var new_points = total_xp / 500
	if new_points > (total_xp - amount) / 500:
		skill_points += 1
		EventBus.notification_requested.emit("Skill point earned! Total: %d" % skill_points, "success", 3.0)

func get_skill_level(skill_id: String) -> int:
	return skills.get(skill_id, {}).get("level", 0)

func get_effect_value(effect: String) -> float:
	var total = 0.0
	for skill_id in SKILL_DEFINITIONS:
		var def = SKILL_DEFINITIONS[skill_id]
		if def.get("effect", "") == effect:
			total += def.get("value_per_level", 0.0) * skills[skill_id]["level"]
	return total

func _on_day_changed(_day: int) -> void:
	# Apply passive reputation from branding
	var rep_per_week = get_effect_value("passive_reputation")
	if rep_per_week > 0 and GameClock.game_day % 7 == 0:
		var sm = ServiceRegistry.get_service("SupermarketManager")
		if sm:
			sm.update_reputation(rep_per_week)
	# Apply investment interest
	var interest_rate = get_effect_value("interest_rate")
	if interest_rate > 0 and GameClock.game_day % 30 == 0:
		var sm = ServiceRegistry.get_service("SupermarketManager")
		if sm:
			var interest = sm.business_money * interest_rate
			sm.business_money += interest
			EventBus.notification_requested.emit("Interest earned: $%.2f" % interest, "info", 3.0)
	# XP from each business day
	var sm = ServiceRegistry.get_service("SupermarketManager")
	if sm and sm.daily_revenue > 0:
		add_xp(int(sm.daily_revenue / 10))

func get_save_data() -> Dictionary:
	return {"skills": skills.duplicate(true), "skill_points": skill_points, "total_xp": total_xp}

func restore_save_data(data: Dictionary) -> void:
	skills = data.get("skills", skills)
	skill_points = data.get("skill_points", 2)
	total_xp = data.get("total_xp", 0)
