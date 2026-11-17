extends Control
## ManagementDashboard — full business management interface.

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var close_btn: Button = $Panel/CloseBtn

# Tab references
var _finance_tab: Control = null
var _inventory_tab: Control = null
var _employees_tab: Control = null
var _suppliers_tab: Control = null
var _orders_tab: Control = null

func _ready() -> void:
	close_btn.pressed.connect(func(): queue_free())
	_build_finance_tab()
	_build_inventory_tab()
	_build_employees_tab()
	_build_suppliers_tab()
	_build_orders_tab()
	_refresh_all()
	EventBus.product_sold.connect(func(_a,_b,_c): call_deferred("_refresh_finance"))
	EventBus.inventory_changed.connect(func(_s): call_deferred("_refresh_inventory"))
	EventBus.employee_hired.connect(func(_id): call_deferred("_refresh_employees"))
	EventBus.delivery_arrived.connect(func(_a,_b): call_deferred("_refresh_orders"))

func _build_finance_tab() -> void:
	_finance_tab = tab_container.get_tab_bar().get_child(0) if tab_container.get_tab_count() > 0 else null
	var tab = _get_or_create_tab("Finance")
	var vbox = VBoxContainer.new()
	vbox.name = "FinanceVBox"
	tab.add_child(vbox)
	_finance_tab = vbox

func _build_inventory_tab() -> void:
	var tab = _get_or_create_tab("Inventory")
	var scroll = ScrollContainer.new()
	scroll.name = "InvScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new()
	vbox.name = "InvVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	tab.add_child(scroll)
	_inventory_tab = vbox

func _build_employees_tab() -> void:
	var tab = _get_or_create_tab("Employees")
	var vbox = VBoxContainer.new()
	vbox.name = "EmpVBox"
	# Hire button
	var hire_btn = Button.new()
	hire_btn.text = "Hire New Employee"
	hire_btn.pressed.connect(_show_hire_dialog)
	vbox.add_child(hire_btn)
	var sep = HSeparator.new()
	vbox.add_child(sep)
	var list_scroll = ScrollContainer.new()
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list = VBoxContainer.new()
	list.name = "EmpList"
	list_scroll.add_child(list)
	vbox.add_child(list_scroll)
	tab.add_child(vbox)
	_employees_tab = list

func _build_suppliers_tab() -> void:
	var tab = _get_or_create_tab("Suppliers")
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new()
	vbox.name = "SupVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	tab.add_child(scroll)
	_suppliers_tab = vbox

func _build_orders_tab() -> void:
	var tab = _get_or_create_tab("Orders")
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new()
	vbox.name = "OrdVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	tab.add_child(scroll)
	_orders_tab = vbox

func _get_or_create_tab(title: String) -> VBoxContainer:
	for i in range(tab_container.get_tab_count()):
		if tab_container.get_tab_title(i) == title:
			return tab_container.get_child(i) as VBoxContainer
	var vbox = VBoxContainer.new()
	vbox.name = title
	tab_container.add_child(vbox)
	tab_container.set_tab_title(tab_container.get_tab_count() - 1, title)
	return vbox

func _refresh_all() -> void:
	_refresh_finance()
	_refresh_inventory()
	_refresh_employees()
	_refresh_suppliers()
	_refresh_orders()

func _refresh_finance() -> void:
	if _finance_tab == null: return
	for c in _finance_tab.get_children(): c.queue_free()
	var sm = ServiceRegistry.get_service("SupermarketManager")
	if sm == null: return
	var analytics = sm.get_analytics()
	var items = [
		["Store", analytics["store_name"]],
		["Level", str(analytics["store_level"])],
		["Reputation", "%.1f/100" % analytics["reputation"]],
		["Balance", "$%.2f" % analytics["business_money"]],
		["Today Revenue", "$%.2f" % analytics["daily_revenue"]],
		["Today Expenses", "$%.2f" % analytics["daily_expenses"]],
		["Today Profit", "$%.2f" % sm.get_profit_today()],
		["Total Revenue", "$%.2f" % analytics["total_revenue"]],
		["Total Expenses", "$%.2f" % analytics["total_expenses"]],
		["Total Profit", "$%.2f" % sm.get_total_profit()],
	]
	for item in items:
		var hbox = HBoxContainer.new()
		var key_lbl = Label.new()
		key_lbl.text = item[0] + ":"
		key_lbl.custom_minimum_size = Vector2(200, 0)
		key_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
		var val_lbl = Label.new()
		val_lbl.text = item[1]
		val_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		hbox.add_child(key_lbl)
		hbox.add_child(val_lbl)
		_finance_tab.add_child(hbox)

func _refresh_inventory() -> void:
	if _inventory_tab == null: return
	for c in _inventory_tab.get_children(): c.queue_free()
	var inv = ServiceRegistry.get_service("InventoryManager")
	var pm = ServiceRegistry.get_service("ProductManager")
	var pricing = ServiceRegistry.get_service("PricingManager")
	if inv == null or pm == null: return
	# Header
	var header = HBoxContainer.new()
	for col in ["Product", "Category", "Stock", "Price", "Margin%"]:
		var lbl = Label.new()
		lbl.text = col
		lbl.custom_minimum_size = Vector2(150, 0)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
		header.add_child(lbl)
	_inventory_tab.add_child(header)
	_inventory_tab.add_child(HSeparator.new())
	var stock_counts = inv.get_all_stock_counts()
	for pid in pm.products:
		var row = HBoxContainer.new()
		var prod = pm.get_product(pid)
		var stock = stock_counts.get(pid, 0)
		var price = pricing.get_price(pid) if pricing else 0.0
		var margin = pricing.get_margin(pid) * 100.0 if pricing else 0.0
		var cols_data = [prod.get("name",""), prod.get("category",""), str(stock), "$%.2f" % price, "%.0f%%" % margin]
		for col_txt in cols_data:
			var lbl = Label.new()
			lbl.text = col_txt
			lbl.custom_minimum_size = Vector2(150, 0)
			if stock == 0 and col_txt == str(stock):
				lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
			row.add_child(lbl)
		# Set price button
		var set_price_btn = Button.new()
		set_price_btn.text = "Set Price"
		set_price_btn.custom_minimum_size = Vector2(80, 0)
		set_price_btn.pressed.connect(_show_price_dialog.bind(pid, price))
		row.add_child(set_price_btn)
		_inventory_tab.add_child(row)

func _refresh_employees() -> void:
	if _employees_tab == null: return
	for c in _employees_tab.get_children(): c.queue_free()
	var em = ServiceRegistry.get_service("EmployeeManager")
	if em == null: return
	var employees = em.get_active_employees()
	if employees.is_empty():
		var lbl = Label.new()
		lbl.text = "No employees hired yet."
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_employees_tab.add_child(lbl)
		return
	for emp in employees:
		var row = HBoxContainer.new()
		var info = Label.new()
		info.text = "%s — %s  |  Skill: %d  |  Morale: %.0f%%  |  Salary: $%.0f/day  |  Task: %s" % [
			emp["name"],
			EmployeeManager.Role.keys()[emp["role"]],
			emp["skill"],
			emp["morale"],
			emp["salary_daily"],
			emp["current_task"] if emp["current_task"] != "" else "idle",
		]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var fire_btn = Button.new()
		fire_btn.text = "Fire"
		fire_btn.pressed.connect(func(): em.fire_employee(emp["id"]); _refresh_employees())
		row.add_child(fire_btn)
		_employees_tab.add_child(row)

func _refresh_suppliers() -> void:
	if _suppliers_tab == null: return
	for c in _suppliers_tab.get_children(): c.queue_free()
	var sup = ServiceRegistry.get_service("SupplierManager")
	if sup == null: return
	for sid in sup.suppliers:
		var s = sup.suppliers[sid]
		var panel = VBoxContainer.new()
		panel.add_theme_constant_override("separation", 4)
		var title = Label.new()
		title.text = "▶ %s  [%s]  Reliability: %.0f%%  Relationship: %.0f/100" % [
			s["name"], s["type"].capitalize(),
			s["reliability"] * 100, s["relationship"]
		]
		title.add_theme_color_override("font_color", Color(0.7, 0.95, 0.7))
		panel.add_child(title)
		# Products list with order spinboxes
		var order_grid = GridContainer.new()
		order_grid.columns = 4
		var inv = ServiceRegistry.get_service("InventoryManager")
		var pm = ServiceRegistry.get_service("ProductManager")
		var order_qtys: Dictionary = {}
		for pid in s.get("products", []):
			var prod = pm.get_product(pid) if pm else {}
			var name_lbl = Label.new()
			name_lbl.text = prod.get("name", pid)
			name_lbl.custom_minimum_size = Vector2(160, 0)
			var stock_lbl = Label.new()
			var current_stock = inv.get_stock_count(pid) if inv else 0
			stock_lbl.text = "Stock: %d" % current_stock
			stock_lbl.custom_minimum_size = Vector2(80, 0)
			var cost_lbl = Label.new()
			cost_lbl.text = "$%.2f ea" % pm.get_wholesale_cost(pid) if pm else "$?"
			cost_lbl.custom_minimum_size = Vector2(70, 0)
			var spin = SpinBox.new()
			spin.min_value = 0
			spin.max_value = 200
			spin.step = 5
			spin.value = 0
			spin.custom_minimum_size = Vector2(80, 0)
			order_qtys[pid] = spin
			order_grid.add_child(name_lbl)
			order_grid.add_child(stock_lbl)
			order_grid.add_child(cost_lbl)
			order_grid.add_child(spin)
		panel.add_child(order_grid)
		var order_btn = Button.new()
		order_btn.text = "Place Order with %s" % s["name"]
		order_btn.pressed.connect(func():
			var items: Dictionary = {}
			for pid in order_qtys:
				var qty = int(order_qtys[pid].value)
				if qty > 0:
					items[pid] = qty
			if items.is_empty():
				EventBus.notification_requested.emit("Select quantities first.", "warning", 2.0)
				return
			sup.place_order(sid, items)
			_refresh_orders()
		)
		panel.add_child(order_btn)
		panel.add_child(HSeparator.new())
		_suppliers_tab.add_child(panel)

func _refresh_orders() -> void:
	if _orders_tab == null: return
	for c in _orders_tab.get_children(): c.queue_free()
	var sup = ServiceRegistry.get_service("SupplierManager")
	if sup == null: return
	if sup.pending_orders.is_empty():
		var lbl = Label.new()
		lbl.text = "No pending orders."
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_orders_tab.add_child(lbl)
		return
	var header = Label.new()
	header.text = "PENDING ORDERS"
	header.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	_orders_tab.add_child(header)
	for order in sup.pending_orders:
		var row = Label.new()
		var sup_name = sup.suppliers.get(order["supplier_id"], {}).get("name", order["supplier_id"])
		row.text = "Order %s — %s — $%.2f — Delivery Day %d" % [
			order["order_id"], sup_name, order["total_cost"], order["delivery_day"]
		]
		_orders_tab.add_child(row)

func _show_hire_dialog() -> void:
	var dialog = Window.new()
	dialog.title = "Hire Employee"
	dialog.size = Vector2i(400, 300)
	dialog.exclusive = true
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	var name_edit = LineEdit.new()
	name_edit.placeholder_text = "Employee name"
	name_edit.text = _random_name()
	var role_opt = OptionButton.new()
	for role_name in EmployeeManager.Role.keys():
		role_opt.add_item(role_name.capitalize())
	var salary_spin = SpinBox.new()
	salary_spin.min_value = 50
	salary_spin.max_value = 300
	salary_spin.value = 80
	var hire_btn = Button.new()
	hire_btn.text = "Hire"
	hire_btn.pressed.connect(func():
		var em = ServiceRegistry.get_service("EmployeeManager")
		if em:
			em.hire_employee(name_edit.text, role_opt.selected as EmployeeManager.Role, salary_spin.value)
		dialog.queue_free()
		_refresh_employees()
	)
	vbox.add_child(Label.new())
	var n_lbl = Label.new(); n_lbl.text = "Name:"; vbox.add_child(n_lbl)
	vbox.add_child(name_edit)
	var r_lbl = Label.new(); r_lbl.text = "Role:"; vbox.add_child(r_lbl)
	vbox.add_child(role_opt)
	var s_lbl = Label.new(); s_lbl.text = "Daily Salary ($):"; vbox.add_child(s_lbl)
	vbox.add_child(salary_spin)
	vbox.add_child(hire_btn)
	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

func _show_price_dialog(product_id: String, current_price: float) -> void:
	var dialog = Window.new()
	dialog.title = "Set Price"
	dialog.size = Vector2i(300, 180)
	dialog.exclusive = true
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	var spin = SpinBox.new()
	spin.min_value = 0.01
	spin.max_value = 1000.0
	spin.step = 0.05
	spin.value = current_price
	var set_btn = Button.new()
	set_btn.text = "Set Price"
	set_btn.pressed.connect(func():
		var pricing = ServiceRegistry.get_service("PricingManager")
		if pricing:
			pricing.set_price(product_id, spin.value)
		dialog.queue_free()
		_refresh_inventory()
	)
	var lbl = Label.new()
	lbl.text = "New price for %s:" % product_id
	vbox.add_child(lbl)
	vbox.add_child(spin)
	vbox.add_child(set_btn)
	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

func _random_name() -> String:
	var first = ["Alex","Sam","Jordan","Taylor","Morgan","Casey","Riley","Jamie","Avery","Quinn"]
	var last = ["Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis","Wilson","Moore"]
	return first[randi() % first.size()] + " " + last[randi() % last.size()]
