extends Node3D
## CheckoutInteractable — player can interact with checkout counters.

func can_interact(_interactor) -> bool:
	return true

func get_interaction_text() -> String:
	return "Use Checkout [%d]" % (get_meta("checkout_index", 0) + 1)

func get_interaction_priority() -> int:
	return 5

func interact(interactor) -> void:
	var checkout = ServiceRegistry.get_service("CheckoutManager")
	if checkout == null:
		return
	if not checkout.active_transaction.is_empty():
		var result = checkout.complete_transaction("cash")
		if not result.is_empty():
			var total = result.get("total", 0.0)
			EventBus.notification_requested.emit(
				"Transaction complete! Total: $%.2f" % total, "success", 3.0)
	else:
		EventBus.notification_requested.emit("No active transaction at this register.", "info", 2.0)
