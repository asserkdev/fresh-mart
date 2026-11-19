extends Control
## HUD — professional in-game UI overlay.

@onready var money_label: Label = $TopBar/TopBarHBox/MoneyBox/MoneyLabel
@onready var time_label: Label = $TopBar/TopBarHBox/TimeBox/TimeLabel
@onready var location_label: Label = $TopBar/TopBarHBox/LocationLabel
@onready var fps_label: Label = $TopBar/TopBarHBox/FPSLabel
@onready var interaction_prompt: PanelContainer = $InteractionPrompt
@onready var prompt_text: Label = $InteractionPrompt/HBox/PromptText
@onready var notification_label: Label = $NotificationArea/NotificationLabel
@onready var save_status: Label = $BottomBar/BottomHBox/SaveStatus
@onready var objective_label: Label = $ObjectivePanel/VBox/ObjectiveLabel
@onready var store_rep_label: Label = $BottomBar/BottomHBox/StoreRepLabel

var weather_label: Label = null
var weather_icon: Label = null

var _management_ui: Control = null
var _construction_ui: Control = null
var _inventory_ui: Control = null
var _skill_ui: Control = null

func _ready() -> void:
	weather_label = get_node_or_null("TopBar/TopBarHBox/WeatherBox/WeatherLabel")
	weather_icon  = get_node_or_null("TopBar/TopBarHBox/WeatherBox/WeatherIcon")

	NotificationManager.register_label(notification_label)

	EventBus.player_money_changed.connect(_on_money_changed)
	EventBus.autosave_started.connect(func(): save_status.text = "⏳ Saving…")
	EventBus.autosave_completed.connect(func(_s): save_status.text = "✓ Autosaved")
	EventBus.save_completed.connect(func(_s): save_status.text = "✓ Saved")
	EventBus.save_failed.connect(func(_r): save_status.text = "✗ Save failed!")
	EventBus.quest_started.connect(func(_id): _update_objective())
	EventBus.quest_completed.connect(func(_id): _update_objective())
	EventBus.quest_objective_updated.connect(func(_qid, _oid): _update_objective())
	EventBus.weather_changed.connect(_on_weather_changed)

	# Initial money from business
	await get_tree().process_frame
	var sm = ServiceRegistry.get_service("SupermarketManager")
	if sm:
		_on_money_changed(sm.business_money)

func _process(_delta: float) -> void:
	# Time
	time_label.text = "%s   Day %d  ·  %s" % [
		GameClock.get_time_string(), GameClock.game_day, GameClock.get_season()]

	# FPS
	fps_label.visible = SettingsManager.get_setting("show_fps")
	if fps_label.visible:
		fps_label.text = "%d FPS" % Engine.get_frames_per_second()

	# Interaction prompt + crosshair
	var player = ServiceRegistry.get_service("Player") if ServiceRegistry.has_service("Player") else null
	if player:
		var prompt = player.get_interaction_prompt()
		if prompt != "":
			prompt_text.text = prompt
			interaction_prompt.visible = true
		else:
			interaction_prompt.visible = false

	# Location from chunk
	if player:
		var cm = ServiceRegistry.get_service("ChunkManager") if ServiceRegistry.has_service("ChunkManager") else null
		if cm:
			var cid = cm.get_chunk_id(player.global_position)
			if cid != "":
				var parts = cid.split("_")
				if parts.size() >= 2:
					location_label.text = parts[1].capitalize().replace("_", " ")
		else:
			location_label.text = "Fresh Mart"

	# Reputation stars
	var sm2 = ServiceRegistry.get_service("SupermarketManager")
	if sm2:
		var rep = sm2.store_reputation
		var stars = int(rep / 20.0)
		store_rep_label.text = "★".repeat(stars) + "☆".repeat(5 - stars)

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_playing():
		return
	if event.is_action_pressed("toggle_management"):
		_toggle_panel("management")
	elif event.is_action_pressed("toggle_construction"):
		_toggle_panel("construction")
	elif event.is_action_pressed("toggle_inventory"):
		_toggle_panel("inventory")
	elif event.is_action_pressed("ui_cancel"):
		_close_all_panels()

func _toggle_panel(panel_name: String) -> void:
	# If the same panel is open, close it
	match panel_name:
		"management":
			if _management_ui and is_instance_valid(_management_ui):
				_management_ui.queue_free(); _management_ui = null
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED; return
			_close_all_panels()
			var s = load("res://ui/screens/management_dashboard.tscn")
			if s: _management_ui = s.instantiate(); add_child(_management_ui)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		"construction":
			if _construction_ui and is_instance_valid(_construction_ui):
				_construction_ui.queue_free(); _construction_ui = null
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED; return
			_close_all_panels()
			var s = load("res://ui/screens/construction_ui.tscn")
			if s: _construction_ui = s.instantiate(); add_child(_construction_ui)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		"inventory":
			if _inventory_ui and is_instance_valid(_inventory_ui):
				_inventory_ui.queue_free(); _inventory_ui = null
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED; return
			_close_all_panels()
			_inventory_ui = _build_inventory_ui(); add_child(_inventory_ui)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_all_panels() -> void:
	for ui in [_management_ui, _construction_ui, _inventory_ui, _skill_ui]:
		if ui and is_instance_valid(ui):
			ui.queue_free()
	_management_ui = null; _construction_ui = null
	_inventory_ui = null; _skill_ui = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_money_changed(amount: float) -> void:
	# Format with commas: 10,000.00
	var formatted = "%.2f" % amount
	var parts = formatted.split(".")
	var int_part = parts[0]
	var out = ""
	var count = 0
	for i in range(int_part.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = int_part[i] + out
		count += 1
	money_label.text = out + "." + parts[1]

func _on_weather_changed(weather: String) -> void:
	if weather_label:
		weather_label.text = weather.capitalize()
	if weather_icon:
		var icons = {"clear": "☀", "cloudy": "⛅", "overcast": "☁", "light_rain": "🌦", "heavy_rain": "🌧"}
		weather_icon.text = icons.get(weather, "☀")

func _update_objective() -> void:
	var qm = ServiceRegistry.get_service("QuestManager") if ServiceRegistry.has_service("QuestManager") else null
	if qm == null or qm.active_quests.is_empty():
		objective_label.text = ""
		get_node("ObjectivePanel").visible = false
		return
	get_node("ObjectivePanel").visible = true
	var qid = qm.active_quests[0]
	var q = qm.quests.get(qid, {})
	var txt = q.get("title", "") + "\n"
	for obj in q.get("objectives", []):
		var done = "✓" if qm._is_objective_complete(obj) else "○"
		txt += " %s %s\n" % [done, obj.get("text", "")]
	objective_label.text = txt

func _build_inventory_ui() -> Control:
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.55)
	container.add_child(overlay)
	var panel = PanelContainer.new()
	panel.position = Vector2(380, 80); panel.size = Vector2(820, 640)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	# Title bar
	var title_hbox = HBoxContainer.new()
	var title_lbl = Label.new()
	title_lbl.text = "Inventory"
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_btn = Button.new(); close_btn.text = "✕ Close"
	close_btn.pressed.connect(func(): container.queue_free(); Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)
	title_hbox.add_child(title_lbl); title_hbox.add_child(close_btn)
	vbox.add_child(title_hbox)
	vbox.add_child(HSeparator.new())
	# Player info
	var player = ServiceRegistry.get_service("Player")
	if player:
		var money_lbl = Label.new()
		money_lbl.text = "Cash on hand:  $%.2f" % player.held_money
		money_lbl.add_theme_font_size_override("font_size", 18)
		money_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.20))
		vbox.add_child(money_lbl)
		vbox.add_child(HSeparator.new())
		var scroll = ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var inv_vbox = VBoxContainer.new()
		inv_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if player.inventory.is_empty():
			var e = Label.new(); e.text = "Your inventory is empty."
			e.add_theme_color_override("font_color", Color(0.55, 0.65, 0.55)); inv_vbox.add_child(e)
		else:
			var pm = ServiceRegistry.get_service("ProductManager")
			# Header
			var h = HBoxContainer.new()
			for col in ["Product", "Category", "Qty"]:
				var hl = Label.new(); hl.text = col
				hl.custom_minimum_size = Vector2(240 if col == "Product" else 180, 0)
				hl.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
				h.add_child(hl)
			inv_vbox.add_child(h); inv_vbox.add_child(HSeparator.new())
			for pid in player.inventory:
				var row = HBoxContainer.new()
				var prod = pm.get_product(pid) if pm else {}
				var n_lbl = Label.new(); n_lbl.text = prod.get("name", pid); n_lbl.custom_minimum_size = Vector2(240,0)
				var c_lbl = Label.new(); c_lbl.text = prod.get("category", ""); c_lbl.custom_minimum_size = Vector2(180,0)
				c_lbl.add_theme_color_override("font_color", Color(0.6,0.75,0.6))
				var q_lbl = Label.new(); q_lbl.text = "×%d" % player.inventory[pid]
				q_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.2))
				row.add_child(n_lbl); row.add_child(c_lbl); row.add_child(q_lbl)
				inv_vbox.add_child(row)
		scroll.add_child(inv_vbox); vbox.add_child(scroll)
	panel.add_child(vbox); container.add_child(panel)
	return container
