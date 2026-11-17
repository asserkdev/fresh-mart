extends Control
## MainMenu — animated, visually rich main menu.

@onready var title_label: Label = $Background/TitleContainer/TitleLabel
@onready var subtitle_label: Label = $Background/TitleContainer/SubtitleLabel
@onready var version_label: Label = $Background/VersionLabel
@onready var btn_new_game: Button = $Background/MenuPanel/VBox/BtnNewGame
@onready var btn_continue: Button = $Background/MenuPanel/VBox/BtnContinue
@onready var btn_load: Button = $Background/MenuPanel/VBox/BtnLoad
@onready var btn_sandbox: Button = $Background/MenuPanel/VBox/BtnSandbox
@onready var btn_settings: Button = $Background/MenuPanel/VBox/BtnSettings
@onready var btn_credits: Button = $Background/MenuPanel/VBox/BtnCredits
@onready var btn_exit: Button = $Background/MenuPanel/VBox/BtnExit
@onready var background: Control = $Background
@onready var particles_layer: Control = $Background/ParticlesLayer
@onready var tip_label: Label = $Background/TipLabel

var _time: float = 0.0
var _btn_hover_tween: Tween = null
var _particles: Array = []
var _title_tween: Tween = null

const TIPS = [
	"💡 Press T in-game to open the Management Dashboard",
	"💡 Press B to enter Construction Mode — place shelves and fixtures",
	"💡 Order stock from suppliers before opening — your shelves need filling!",
	"💡 Hire employees to automatically restock shelves and run the checkout",
	"💡 Set prices wisely — too high and customers leave, too low and you lose money",
	"💡 Autosave triggers every 5 minutes when the world has changed",
	"💡 Press V to switch between first-person and third-person camera",
	"💡 Your store reputation affects how many customers visit",
	"💡 Products expire — keep an eye on your stock freshness",
	"💡 Talk to NPCs in the city — they can become suppliers or give quests",
]
var _tip_idx: int = 0
var _tip_timer: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.set_mode(GameManager.GameMode.MAIN_MENU)

	# Check saves
	var slots = SaveManager.get_save_slots()
	btn_continue.disabled = slots.is_empty()

	# Wire buttons
	btn_new_game.pressed.connect(_on_new_game)
	btn_continue.pressed.connect(_on_continue)
	btn_load.pressed.connect(_on_load)
	btn_sandbox.pressed.connect(_on_sandbox)
	btn_settings.pressed.connect(_on_settings)
	btn_credits.pressed.connect(_on_credits)
	btn_exit.pressed.connect(_on_exit)

	# Hover effects
	for btn in [btn_new_game, btn_continue, btn_load, btn_sandbox, btn_settings, btn_credits, btn_exit]:
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_unhover.bind(btn))

	version_label.text = "v7.0  |  Godot 4"
	_tip_idx = randi() % TIPS.size()
	tip_label.text = TIPS[_tip_idx]

	# Animate title in
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	_title_tween = create_tween().set_parallel(true)
	_title_tween.tween_property(title_label, "modulate:a", 1.0, 1.2).set_delay(0.3)
	_title_tween.tween_property(title_label, "position:y", title_label.position.y, 0.8)\
		.from(title_label.position.y - 30).set_delay(0.3)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_title_tween.tween_property(subtitle_label, "modulate:a", 1.0, 1.0).set_delay(0.7)

	# Animate buttons in
	var delay = 0.9
	for btn in [btn_new_game, btn_continue, btn_load, btn_sandbox, btn_settings, btn_credits, btn_exit]:
		btn.modulate.a = 0.0
		btn.position.x -= 40
		_title_tween.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(delay)
		_title_tween.tween_property(btn, "position:x", btn.position.x + 40, 0.35)\
			.set_delay(delay).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		delay += 0.07

	# Spawn floating particles
	_spawn_particles()

func _process(delta: float) -> void:
	_time += delta

	# Animate background gradient pulsing
	var bg_rect = background.get_node_or_null("BGRect")
	if bg_rect:
		var pulse = (sin(_time * 0.4) + 1.0) * 0.5
		bg_rect.material.set_shader_parameter("pulse", pulse)

	# Rotate/move particles
	for p in _particles:
		if is_instance_valid(p):
			p.position.y -= delta * p.get_meta("speed", 20.0)
			p.position.x += sin(_time * p.get_meta("drift", 1.0)) * delta * 8.0
			p.modulate.a = lerp(p.modulate.a, p.get_meta("target_alpha", 0.6), delta * 0.5)
			if p.position.y < -20:
				p.position.y = get_viewport_rect().size.y + 20
				p.position.x = randf() * get_viewport_rect().size.x

	# Tip rotation
	_tip_timer += delta
	if _tip_timer >= 5.0:
		_tip_timer = 0.0
		_tip_idx = (_tip_idx + 1) % TIPS.size()
		var tween = create_tween()
		tween.tween_property(tip_label, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): tip_label.text = TIPS[_tip_idx])
		tween.tween_property(tip_label, "modulate:a", 1.0, 0.4)

	# Title shimmer
	var shimmer = Color(
		lerp(0.3, 0.5, (sin(_time * 1.2) + 1.0) * 0.5),
		lerp(0.85, 1.0, (sin(_time * 0.9 + 1.0) + 1.0) * 0.5),
		lerp(0.3, 0.5, (sin(_time * 1.5 + 2.0) + 1.0) * 0.5)
	)
	title_label.add_theme_color_override("font_color", shimmer)

func _spawn_particles() -> void:
	var vp = get_viewport_rect().size
	var particle_data = [
		{"char": "🛒", "size": 28}, {"char": "💰", "size": 22},
		{"char": "📦", "size": 20}, {"char": "$", "size": 24},
		{"char": "🛍", "size": 26}, {"char": "★", "size": 18},
		{"char": "💎", "size": 20}, {"char": "🏪", "size": 24},
	]
	for i in range(18):
		var lbl = Label.new()
		var pd = particle_data[i % particle_data.size()]
		lbl.text = pd["char"]
		lbl.add_theme_font_size_override("font_size", pd["size"])
		lbl.position = Vector2(randf() * vp.x, randf() * vp.y)
		lbl.modulate.a = 0.0
		lbl.set_meta("speed", randf_range(15.0, 45.0))
		lbl.set_meta("drift", randf_range(0.5, 2.5))
		lbl.set_meta("target_alpha", randf_range(0.08, 0.22))
		particles_layer.add_child(lbl)
		_particles.append(lbl)

func _on_btn_hover(btn: Button) -> void:
	if _btn_hover_tween:
		_btn_hover_tween.kill()
	_btn_hover_tween = create_tween()
	_btn_hover_tween.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.12)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_btn_unhover(btn: Button) -> void:
	var t = create_tween()
	t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_new_game() -> void:
	_animate_out()
	await get_tree().create_timer(0.4).timeout
	GameManager.start_new_game("save_01", GameManager.PlayMode.CAREER)

func _on_continue() -> void:
	var slots = SaveManager.get_save_slots()
	if slots.is_empty(): return
	slots.sort()
	_animate_out()
	await get_tree().create_timer(0.4).timeout
	GameManager.load_game(slots[slots.size() - 1])

func _on_load() -> void:
	_animate_out()
	await get_tree().create_timer(0.3).timeout
	SceneManager.load_scene("res://scenes/menus/save_selection.tscn")

func _on_sandbox() -> void:
	_animate_out()
	await get_tree().create_timer(0.4).timeout
	GameManager.start_new_game("sandbox_01", GameManager.PlayMode.SANDBOX)

func _on_settings() -> void:
	var s = load("res://scenes/menus/settings_menu.tscn").instantiate()
	add_child(s)

func _on_credits() -> void:
	_show_credits()

func _on_exit() -> void:
	_animate_out()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()

func _animate_out() -> void:
	var t = create_tween().set_parallel(true)
	t.tween_property(background, "modulate:a", 0.0, 0.4)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)

func _show_credits() -> void:
	var dlg = Window.new()
	dlg.title = "Credits"
	dlg.size = Vector2i(500, 300)
	dlg.exclusive = true
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	for line in [
		"FRESH MART v7", "", "Engine: Godot 4.7.2",
		"Genre: Supermarket Sim / City Builder / RPG",
		"", "Built with Godot Engine — godotengine.org",
		"Character models: project assets",
		"", "© 2026 Fresh Mart Project",
	]:
		var l = Label.new()
		l.text = line
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if line == "FRESH MART v7":
			l.add_theme_font_size_override("font_size", 22)
			l.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		vbox.add_child(l)
	var close = Button.new()
	close.text = "Close"
	close.pressed.connect(dlg.queue_free)
	vbox.add_child(close)
	dlg.add_child(vbox)
	add_child(dlg)
	dlg.popup_centered()
