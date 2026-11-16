extends Control

@onready var slots_vbox: VBoxContainer = $Panel/ScrollContainer/VBox
@onready var btn_back: Button = $Panel/BtnBack

func _ready() -> void:
	btn_back.pressed.connect(func(): SceneManager.load_scene("res://scenes/menus/main_menu.tscn"))
	_populate_slots()

func _populate_slots() -> void:
	for child in slots_vbox.get_children():
		child.queue_free()
	var slots = SaveManager.get_save_slots()
	if slots.is_empty():
		var lbl = Label.new()
		lbl.text = "No saved games found."
		slots_vbox.add_child(lbl)
		return
	for slot in slots:
		var data = SaveManager.load_game(slot)
		var hbox = HBoxContainer.new()
		var lbl = Label.new()
		var playtime = data.get("metadata", {}).get("playtime", 0.0)
		var hours = int(playtime / 3600)
		var mins = int(fmod(playtime, 3600) / 60)
		lbl.text = "%s — %dh %dm" % [slot, hours, mins]
		lbl.custom_minimum_size = Vector2(400, 0)
		var btn_load = Button.new()
		btn_load.text = "Load"
		btn_load.pressed.connect(func(): GameManager.load_game(slot))
		var btn_del = Button.new()
		btn_del.text = "Delete"
		btn_del.pressed.connect(func():
			SaveManager.delete_save(slot)
			_populate_slots()
		)
		hbox.add_child(lbl)
		hbox.add_child(btn_load)
		hbox.add_child(btn_del)
		slots_vbox.add_child(hbox)
