extends Control
## HUD — displays money, time, location, interaction prompt, notifications, save status.

@onready var money_label: Label = $TopBar/MoneyLabel
@onready var time_label: Label = $TopBar/TimeLabel
@onready var location_label: Label = $TopBar/LocationLabel
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var notification_label: Label = $NotificationArea/NotificationLabel
@onready var save_status: Label = $BottomBar/SaveStatus
@onready var fps_label: Label = $TopBar/FPSLabel
@onready var objective_label: Label = $ObjectivePanel/ObjectiveLabel

func _ready() -> void:
	NotificationManager.register_label(notification_label)
	EventBus.player_money_changed.connect(_on_money_changed)
	EventBus.autosave_started.connect(func(): save_status.text = "Saving...")
	EventBus.autosave_completed.connect(func(_s): save_status.text = "Saved")
	EventBus.save_completed.connect(func(_s): save_status.text = "Saved")
	EventBus.save_failed.connect(func(_r): save_status.text = "Save failed!")
	EventBus.quest_started.connect(_on_quest_started)
	EventBus.quest_completed.connect(func(_id): _update_objective())
	EventBus.quest_objective_updated.connect(func(_qid, _oid): _update_objective())

func _process(_delta: float) -> void:
	time_label.text = "%s  Day %d" % [GameClock.get_time_string(), GameClock.game_day]
	if SettingsManager.get_setting("show_fps"):
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
		fps_label.visible = true
	else:
		fps_label.visible = false
	# Interaction prompt
	var player = ServiceRegistry.get_service("Player")
	if player:
		var prompt = player.get_interaction_prompt()
		if prompt != "":
			interaction_prompt.text = "[E] " + prompt
			interaction_prompt.visible = true
		else:
			interaction_prompt.visible = false
	# Location
	if player:
		var cm = ServiceRegistry.get_service("ChunkManager")
		if cm:
			var chunk_id = cm.get_chunk_id(player.global_position)
			if chunk_id != "":
				var parts = chunk_id.split("_")
				if parts.size() >= 2:
					location_label.text = parts[1].capitalize()

func _on_money_changed(amount: float) -> void:
	money_label.text = "$%.2f" % amount

func _on_quest_started(quest_id: String) -> void:
	_update_objective()

func _update_objective() -> void:
	var qm = ServiceRegistry.get_service("QuestManager")
	if qm == null:
		return
	if qm.active_quests.is_empty():
		objective_label.text = ""
		return
	var qid = qm.active_quests[0]
	var q = qm.quests.get(qid, {})
	var txt = q.get("title", "") + "\n"
	for obj in q.get("objectives", []):
		var done = "✓" if qm._is_objective_complete(obj) else "○"
		txt += "  %s %s (%s/%s)\n" % [done, obj["text"], str(obj["current"]), str(obj["target"])]
	objective_label.text = txt
