extends Control
## Main menu — entry point for all game modes.

@onready var btn_new_game: Button = $VBoxContainer/BtnNewGame
@onready var btn_continue: Button = $VBoxContainer/BtnContinue
@onready var btn_load: Button = $VBoxContainer/BtnLoad
@onready var btn_sandbox: Button = $VBoxContainer/BtnSandbox
@onready var btn_settings: Button = $VBoxContainer/BtnSettings
@onready var btn_credits: Button = $VBoxContainer/BtnCredits
@onready var btn_exit: Button = $VBoxContainer/BtnExit
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.set_mode(GameManager.GameMode.MAIN_MENU)
	version_label.text = "Fresh Mart v7.0"

	# Check if save exists for Continue
	var slots = SaveManager.get_save_slots()
	btn_continue.disabled = slots.is_empty()

	btn_new_game.pressed.connect(_on_new_game)
	btn_continue.pressed.connect(_on_continue)
	btn_load.pressed.connect(_on_load)
	btn_sandbox.pressed.connect(_on_sandbox)
	btn_settings.pressed.connect(_on_settings)
	btn_credits.pressed.connect(_on_credits)
	btn_exit.pressed.connect(_on_exit)

func _on_new_game() -> void:
	# Default slot: "save_01"
	GameManager.start_new_game("save_01", GameManager.PlayMode.CAREER)

func _on_continue() -> void:
	var slots = SaveManager.get_save_slots()
	if slots.is_empty():
		return
	# Load the most recently modified slot
	slots.sort()
	GameManager.load_game(slots[slots.size() - 1])

func _on_load() -> void:
	# Open save selection screen
	SceneManager.load_scene("res://scenes/menus/save_selection.tscn")

func _on_sandbox() -> void:
	GameManager.start_new_game("sandbox_01", GameManager.PlayMode.SANDBOX)

func _on_settings() -> void:
	var settings_scene = load("res://scenes/menus/settings_menu.tscn")
	if settings_scene:
		var s = settings_scene.instantiate()
		add_child(s)

func _on_credits() -> void:
	pass  # TODO: implement credits screen

func _on_exit() -> void:
	get_tree().quit()
