extends Node
## CheckoutManager — transaction processing, payment, receipts.

var transactions: Array = []  # completed transactions
var active_transaction: Dictionary = {}
var daily_transactions: int = 0
var daily_total: float = 0.0

signal transaction_started(transaction_id: String)
signal transaction_completed(transaction_id: String, total: float)

func _ready() -> void:
	ServiceRegistry.register("CheckoutManager", self)
	EventBus.day_changed.connect(func(_d): _reset_daily())

func start_transaction(customer_id: String) -> String:
	if not active_transaction.is_empty():
		push_warning("[CheckoutManager] Transaction already in progress")
		return active_transaction.get("id", "")
	var tid = "txn_%d_%d" % [GameClock.game_day * 10000, daily_transactions + randi() % 1000]
	active_transaction = {
		"id": tid,
		"customer_id": customer_id,
		"items": [],
		"subtotal": 0.0,
		"discount_total": 0.0,
		"total": 0.0,
		"payment_method": "cash",
		"timestamp": GameClock.get_time_string(),
		"complete": false,
	}
	transaction_started.emit(tid)
	return tid

func add_item_to_transaction(product_id: String, quantity: int = 1) -> void:
	if active_transaction.is_empty():
		return
	var pm = ServiceRegistry.get_service("PricingManager")
	var price = pm.get_price(product_id) if pm else 1.0
	var item = {"product_id": product_id, "quantity": quantity, "unit_price": price, "line_total": price * quantity}
	active_transaction["items"].append(item)
	active_transaction["subtotal"] += item["line_total"]
	active_transaction["total"] = active_transaction["subtotal"] - active_transaction["discount_total"]

func apply_discount(amount: float) -> void:
	if active_transaction.is_empty():
		return
	active_transaction["discount_total"] += amount
	active_transaction["total"] = max(0, active_transaction["subtotal"] - active_transaction["discount_total"])

func complete_transaction(payment_method: String = "cash") -> Dictionary:
	if active_transaction.is_empty() or active_transaction["complete"]:
		return {}

	active_transaction["payment_method"] = payment_method
	active_transaction["complete"] = true

	# Remove items from inventory
	var inv = ServiceRegistry.get_service("InventoryManager")
	for item in active_transaction["items"]:
		if inv:
			inv.remove_stock(item["product_id"], item["quantity"])
		EventBus.product_sold.emit(item["product_id"], item["quantity"], item["line_total"])

	var total = active_transaction["total"]
	daily_total += total
	daily_transactions += 1
	transactions.append(active_transaction.duplicate(true))

	EventBus.checkout_completed.emit(active_transaction["id"], total)
	transaction_completed.emit(active_transaction["id"], total)

	var completed = active_transaction.duplicate(true)
	active_transaction = {}
	return completed

func cancel_transaction() -> void:
	active_transaction = {}

func get_receipt_text(transaction: Dictionary) -> String:
	var txt = "=== FRESH MART ===\n"
	txt += "Date: %s\n" % GameClock.get_date_string()
	txt += "Time: %s\n" % transaction.get("timestamp", "")
	txt += "-----------------\n"
	var pm = ServiceRegistry.get_service("ProductManager")
	for item in transaction.get("items", []):
		var name = pm.get_product(item["product_id"]).get("name", item["product_id"]) if pm else item["product_id"]
		txt += "%s x%d  $%.2f\n" % [name, item["quantity"], item["line_total"]]
	txt += "-----------------\n"
	txt += "TOTAL: $%.2f\n" % transaction.get("total", 0.0)
	txt += "Payment: %s\n" % transaction.get("payment_method", "cash")
	txt += "Thank you!\n"
	return txt

func _reset_daily() -> void:
	daily_transactions = 0
	daily_total = 0.0

func get_save_data() -> Dictionary:
	# Save last 100 transactions
	var t = transactions
	if t.size() > 100:
		t = t.slice(t.size() - 100)
	return {"transactions": t, "daily_total": daily_total}

func restore_save_data(data: Dictionary) -> void:
	transactions = data.get("transactions", [])
	daily_total = data.get("daily_total", 0.0)
