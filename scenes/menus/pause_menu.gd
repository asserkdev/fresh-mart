extends Control

@onready var btn_resume: Button = $Panel/VBox/BtnResume
@onready var btn_save: Button = $Panel/VBox/BtnSave
@onready var btn_settings: Button = $Panel/VBox/BtnSettings
@onready var btn_main_menu: Button = $Panel/VBox/BtnMainMenu
@onready var btn_quit: Button = $Panel/VBox/BtnQuit
@onready var save_status: Label = $Panel/VBox/SaveStatus

func _ready() -> void:
	visible = false
	btn_resume.pressed.connect(_resume)
	btn_save.pressed.connect(_save)
	btn_settings.pressed.connect(_settings)
	btn_main_menu.pressed.connect(_main_menu)
	btn_quit.pressed.connect(_quit)
	EventBus.save_completed.connect(func(_s): save_status.text = "Saved!")
	EventBus.autosave_completed.connect(func(_s): save_status.text = "Autosaved!")

func _resume() -> void:
	visible = false
	GameManager.resume_game()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _save() -> void:
	save_status.text = "Saving..."
	await SaveManager.save_game(GameManager.current_save_slot)

func _settings() -> void:
	var s = load("res://scenes/menus/settings_menu.tscn").instantiate()
	add_child(s)

func _main_menu() -> void:
	visible = false
	GameManager.return_to_main_menu()

func _quit() -> void:
	GameManager.quit_game()
