extends Node
## ServiceRegistry — provides controlled access to runtime services.
## Systems register themselves; others query by name.

var _services: Dictionary = {}

func register(name: String, service: Object) -> void:
	if _services.has(name):
		# Silent overwrite for re-registration during scene reloads — only warn on truly different objects
		if _services[name] != service:
			push_warning("[ServiceRegistry] Overwriting service: " + name)
	_services[name] = service
	print("[ServiceRegistry] Registered: " + name)

func get_service(name: String) -> Object:
	if not _services.has(name):
		push_error("[ServiceRegistry] Service not found: " + name)
		return null
	return _services[name]

func has_service(name: String) -> bool:
	return _services.has(name)

func unregister(name: String) -> void:
	_services.erase(name)
	print("[ServiceRegistry] Unregistered: " + name)
