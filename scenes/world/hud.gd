extends Control
## HUD — displays all in-game overlays and handles UI toggle hotkeys.

@onready var money_label: Label = $TopBar/MoneyLabel
@onready var time_label: Label = $TopBar/TimeLabel
@onready var location_label: Label = $TopBar/LocationLabel
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var notification_label: Label = $NotificationArea/NotificationLabel
@onready var save_status: Label = $BottomBar/SaveStatus
@onready var fps_label: Label = $TopBar/FPSLabel
@onready var objective_label: Label = $ObjectivePanel/ObjectiveLabel

var weather_label: Label = null

var _management_ui: Control = null
var _construction_ui: Control = null
var _inventory_ui: Control = null

func _ready() -> void:
	weather_label = get_node_or_null("TopBar/WeatherLabel")
	NotificationManager.register_label(notification_label)
	# Money
	EventBus.player_money_changed.connect(_on_money_changed)
	# Save status
	EventBus.autosave_started.connect(func(): save_status.text = "⏳ Saving...")
	EventBus.autosave_completed.connect(func(_s): save_status.text = "✓ Autosaved")
	EventBus.save_completed.connect(func(_s): save_status.text = "✓ Saved")
	EventBus.save_failed.connect(func(_r): save_status.text = "✗ Save failed!")
	# Quests
	EventBus.quest_started.connect(func(_id): _update_objective())
	EventBus.quest_completed.connect(func(_id): _update_objective())
	EventBus.quest_objective_updated.connect(func(_qid, _oid): _update_objective())
	# Weather
	EventBus.weather_changed.connect(func(w):
		if weather_label: weather_label.text = w.capitalize()
	)
	# Initial money
	var sm = ServiceRegistry.get_service("SupermarketManager")
	if sm:
		_on_money_changed(sm.business_money)

func _process(_delta: float) -> void:
	# Time & date
	time_label.text = "%s  Day %d  %s" % [GameClock.get_time_string(), GameClock.game_day, GameClock.get_season()]
	# FPS
	fps_label.visible = SettingsManager.get_setting("show_fps")
	if fps_label.visible:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	# Interaction prompt
	var player = ServiceRegistry.get_service("Player")
	if player:
		var prompt = player.get_interaction_prompt()
		if prompt != "":
			interaction_prompt.text = "[E]  " + prompt
			interaction_prompt.visible = true
		else:
			interaction_prompt.visible = false
	# Location
	if player:
		var cm = ServiceRegistry.get_service("ChunkManager")
		if cm:
			var cid = cm.get_chunk_id(player.global_position)
			if cid != "":
				var parts = cid.split("_")
				if parts.size() >= 2:
					location_label.text = parts[1].capitalize().replace("_", " ")

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_playing():
		return
	if event.is_action_pressed("toggle_management"):
		_toggle_management()
	elif event.is_action_pressed("toggle_construction"):
		_toggle_construction()
	elif event.is_action_pressed("toggle_inventory"):
		_toggle_inventory()
	elif event.is_action_pressed("ui_cancel"):
		# Close any open UI panel
		if _management_ui and is_instance_valid(_management_ui):
			_management_ui.queue_free()
			_management_ui = null
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif _construction_ui and is_instance_valid(_construction_ui):
			_construction_ui.queue_free()
			_construction_ui = null
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif _inventory_ui and is_instance_valid(_inventory_ui):
			_inventory_ui.queue_free()
			_inventory_ui = null
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _toggle_management() -> void:
	if _management_ui and is_instance_valid(_management_ui):
		_management_ui.queue_free()
		_management_ui = null
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	var scene = load("res://ui/screens/management_dashboard.tscn")
	if scene:
		_management_ui = scene.instantiate()
		add_child(_management_ui)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _toggle_construction() -> void:
	if _construction_ui and is_instance_valid(_construction_ui):
		_construction_ui.queue_free()
		_construction_ui = null
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	var scene = load("res://ui/screens/construction_ui.tscn")
	if scene:
		_construction_ui = scene.instantiate()
		add_child(_construction_ui)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _toggle_inventory() -> void:
	if _inventory_ui and is_instance_valid(_inventory_ui):
		_inventory_ui.queue_free()
		_inventory_ui = null
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	# Simple inventory overlay
	var inv_ui = _build_inventory_ui()
	add_child(inv_ui)
	_inventory_ui = inv_ui
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_inventory_ui() -> Control:
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	container.add_child(overlay)
	var panel = Panel.new()
	panel.position = Vector2(400, 100)
	panel.size = Vector2(800, 600)
	var title = Label.new()
	title.text = "Inventory — Press I to close"
	title.position = Vector2(20, 10)
	title.add_theme_font_size_override("font_size", 24)
	panel.add_child(title)
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(10, 60)
	scroll.size = Vector2(780, 520)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Player inventory
	var player = ServiceRegistry.get_service("Player")
	if player:
		var money_lbl = Label.new()
		money_lbl.text = "Cash: $%.2f" % player.held_money
		money_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		vbox.add_child(money_lbl)
		vbox.add_child(HSeparator.new())
		if player.inventory.is_empty():
			var empty_lbl = Label.new()
			empty_lbl.text = "Inventory is empty."
			vbox.add_child(empty_lbl)
		else:
			var pm = ServiceRegistry.get_service("ProductManager")
			for pid in player.inventory:
				var row = HBoxContainer.new()
				var name_lbl = Label.new()
				var pname = pm.get_product(pid).get("name", pid) if pm else pid
				name_lbl.text = pname
				name_lbl.custom_minimum_size = Vector2(300, 0)
				var qty_lbl = Label.new()
				qty_lbl.text = "x%d" % player.inventory[pid]
				row.add_child(name_lbl)
				row.add_child(qty_lbl)
				vbox.add_child(row)
	scroll.add_child(vbox)
	panel.add_child(scroll)
	container.add_child(panel)
	return container

func _on_money_changed(amount: float) -> void:
	money_label.text = "$%.2f" % amount

func _update_objective() -> void:
	var qm = ServiceRegistry.get_service("QuestManager")
	if qm == null or qm.active_quests.is_empty():
		objective_label.text = ""
		return
	var qid = qm.active_quests[0]
	var q = qm.quests.get(qid, {})
	var txt = "📋 %s\n" % q.get("title", "")
	for obj in q.get("objectives", []):
		var done = "✓" if qm._is_objective_complete(obj) else "○"
		txt += "  %s %s  (%s/%s)\n" % [done, obj.get("text",""), str(obj["current"]), str(obj["target"])]
	objective_label.text = txt
