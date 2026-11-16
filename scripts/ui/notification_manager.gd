extends Node
## NotificationManager — queues and displays in-game notifications.

signal notification_shown(message: String, type: String)

var _queue: Array = []
var _current_timer: float = 0.0
var _notification_label: Label = null  # Set by HUD when ready

func _ready() -> void:
	EventBus.notification_requested.connect(_on_notification_requested)
	ServiceRegistry.register("NotificationManager", self)

func _process(delta: float) -> void:
	if _notification_label == null:
		return
	if _current_timer > 0.0:
		_current_timer -= delta
		if _current_timer <= 0.0:
			_notification_label.visible = false
			_show_next()
	elif _queue.size() > 0:
		_show_next()

func _on_notification_requested(message: String, type: String, duration: float) -> void:
	_queue.append({"message": message, "type": type, "duration": duration})

func _show_next() -> void:
	if _queue.is_empty() or _notification_label == null:
		return
	var n = _queue.pop_front()
	_notification_label.text = n["message"]
	_notification_label.visible = true
	_current_timer = n["duration"]
	notification_shown.emit(n["message"], n["type"])

func register_label(label: Label) -> void:
	_notification_label = label
