extends Node
## EmployeeManager — hiring, firing, tasks, shifts, morale, salaries.

enum Role { CASHIER, STOCKER, CLEANER, MANAGER, WAREHOUSE, DRIVER, SECURITY }
enum TaskState { IDLE, WORKING, ON_BREAK, OFF_SHIFT }

var employees: Dictionary = {}   # employee_id -> EmployeeData
var _task_timer: float = 0.0
const TASK_UPDATE_INTERVAL: float = 10.0

var _next_id: int = 1

func _ready() -> void:
	ServiceRegistry.register("EmployeeManager", self)
	EventBus.day_changed.connect(_on_day_changed)

func _process(delta: float) -> void:
	_task_timer += delta
	if _task_timer >= TASK_UPDATE_INTERVAL:
		_task_timer = 0.0
		_update_employee_tasks()

func hire_employee(name: String, role: Role, salary: float = -1.0) -> String:
	var default_salaries = {
		Role.CASHIER: 80.0, Role.STOCKER: 75.0, Role.CLEANER: 70.0,
		Role.MANAGER: 120.0, Role.WAREHOUSE: 80.0, Role.DRIVER: 90.0, Role.SECURITY: 85.0
	}
	var eid = "emp_%04d" % _next_id
	_next_id += 1
	employees[eid] = {
		"id": eid, "name": name, "role": role,
		"salary_daily": salary if salary > 0 else default_salaries.get(role, 80.0),
		"morale": 70.0, "skill": 1, "experience": 0,
		"task_state": TaskState.IDLE, "current_task": "",
		"shift_start": 8, "shift_end": 17,
		"hired_day": GameClock.game_day,
		"active": true,
	}
	EventBus.employee_hired.emit(eid)
	EventBus.notification_requested.emit("Hired %s as %s!" % [name, Role.keys()[role]], "success", 3.0)
	return eid

func fire_employee(eid: String) -> void:
	if not employees.has(eid):
		return
	employees[eid]["active"] = false
	EventBus.employee_fired.emit(eid)
	EventBus.notification_requested.emit("%s has been let go." % employees[eid]["name"], "info", 3.0)

func get_active_employees() -> Array:
	var result = []
	for eid in employees:
		if employees[eid]["active"]:
			result.append(employees[eid])
	return result

func get_employees_by_role(role: Role) -> Array:
	return get_active_employees().filter(func(e): return e["role"] == role)

func get_daily_salary_total() -> float:
	var total = 0.0
	for eid in employees:
		if employees[eid]["active"]:
			total += employees[eid]["salary_daily"]
	return total

func assign_task(eid: String, task: String) -> void:
	if not employees.has(eid):
		return
	employees[eid]["current_task"] = task
	employees[eid]["task_state"] = TaskState.WORKING
	EventBus.employee_task_assigned.emit(eid, task)

func _update_employee_tasks() -> void:
	var hour = GameClock.game_hour
	var inv = ServiceRegistry.get_service("InventoryManager")
	var checkout = ServiceRegistry.get_service("CheckoutManager")

	for eid in employees:
		var emp = employees[eid]
		if not emp["active"]:
			continue
		# Check shift
		if hour < emp["shift_start"] or hour >= emp["shift_end"]:
			emp["task_state"] = TaskState.OFF_SHIFT
			emp["current_task"] = ""
			continue
		# Assign tasks by role
		match emp["role"]:
			Role.STOCKER:
				if inv:
					var low = inv.get_low_stock_items(10)
					if low.size() > 0:
						assign_task(eid, "restock_%s" % low[0])
					else:
						emp["task_state"] = TaskState.IDLE
						emp["current_task"] = "patrolling"
			Role.CASHIER:
				assign_task(eid, "operate_checkout")
			Role.CLEANER:
				assign_task(eid, "clean_store")
			Role.MANAGER:
				assign_task(eid, "manage_store")
			_:
				if emp["task_state"] == TaskState.IDLE:
					emp["current_task"] = "standby"

		# Morale decay
		emp["morale"] = clamp(emp["morale"] - 0.05, 0.0, 100.0)
		# XP gain
		if emp["task_state"] == TaskState.WORKING:
			emp["experience"] += 1
			if emp["experience"] >= emp["skill"] * 100:
				emp["experience"] = 0
				emp["skill"] += 1
				EventBus.notification_requested.emit(
					"%s leveled up to skill %d!" % [emp["name"], emp["skill"]], "success", 3.0)

func improve_morale(eid: String, amount: float = 10.0) -> void:
	if employees.has(eid):
		employees[eid]["morale"] = clamp(employees[eid]["morale"] + amount, 0.0, 100.0)

func _on_day_changed(_day: int) -> void:
	# Reset daily experience tracking
	pass

func get_save_data() -> Dictionary:
	return {"employees": employees.duplicate(true), "next_id": _next_id}

func restore_save_data(data: Dictionary) -> void:
	employees = data.get("employees", {})
	_next_id = data.get("next_id", 1)
