extends Control
## SkillTreeUI — visual skill tree with unlock buttons.

@onready var close_btn: Button = $Panel/CloseBtn
@onready var points_label: Label = $Panel/PointsLabel
@onready var xp_label: Label = $Panel/XPLabel
@onready var scroll: ScrollContainer = $Panel/ScrollContainer
@onready var tree_container: VBoxContainer = $Panel/ScrollContainer/TreeContainer

var _skill_manager: Node = null

func _ready() -> void:
	close_btn.pressed.connect(func(): queue_free())
	_skill_manager = ServiceRegistry.get_service("SkillManager")
	if _skill_manager:
		_build_tree()
		_update_header()
	EventBus.skill_unlocked.connect(func(_id): _refresh())

func _build_tree() -> void:
	if _skill_manager == null:
		return
	var trees = {}
	for skill_id in SkillManager.SKILL_DEFINITIONS:
		var def = SkillManager.SKILL_DEFINITIONS[skill_id]
		var tree_name = def["tree"]
		if not trees.has(tree_name):
			trees[tree_name] = []
		trees[tree_name].append(skill_id)
	for tree_name in trees:
		var tree_lbl = Label.new()
		tree_lbl.text = "── %s ──" % tree_name.to_upper()
		tree_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		tree_lbl.add_theme_font_size_override("font_size", 18)
		tree_container.add_child(tree_lbl)
		for skill_id in trees[tree_name]:
			tree_container.add_child(_make_skill_row(skill_id))
		tree_container.add_child(HSeparator.new())

func _make_skill_row(skill_id: String) -> HBoxContainer:
	var def = SkillManager.SKILL_DEFINITIONS[skill_id]
	var level = _skill_manager.get_skill_level(skill_id)
	var max_level = def.get("max_level", 1)
	var row = HBoxContainer.new()
	row.name = "Row_" + skill_id
	# Level dots
	var dots_lbl = Label.new()
	dots_lbl.text = "●" .repeat(level) + "○".repeat(max_level - level)
	dots_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	dots_lbl.custom_minimum_size = Vector2(80, 0)
	# Name + desc
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_lbl = Label.new()
	name_lbl.text = def["name"]
	name_lbl.add_theme_font_size_override("font_size", 16)
	var desc_lbl = Label.new()
	desc_lbl.text = def["description"]
	desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	desc_lbl.add_theme_font_size_override("font_size", 13)
	if def.has("requires"):
		var req_lbl = Label.new()
		req_lbl.text = "Requires: %s" % SkillManager.SKILL_DEFINITIONS.get(def["requires"], {}).get("name", def["requires"])
		req_lbl.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
		req_lbl.add_theme_font_size_override("font_size", 12)
		info.add_child(req_lbl)
	info.add_child(name_lbl)
	info.add_child(desc_lbl)
	# Unlock button
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(100, 0)
	if level >= max_level:
		btn.text = "MAX"
		btn.disabled = true
	elif _skill_manager.can_unlock(skill_id):
		btn.text = "Unlock (%d pt)" % def.get("cost", 1)
		btn.pressed.connect(func():
			_skill_manager.unlock_skill(skill_id)
			_refresh()
		)
	else:
		btn.text = "Locked"
		btn.disabled = true
	row.add_child(dots_lbl)
	row.add_child(info)
	row.add_child(btn)
	return row

func _refresh() -> void:
	for child in tree_container.get_children():
		child.queue_free()
	_build_tree()
	_update_header()

func _update_header() -> void:
	if _skill_manager:
		points_label.text = "Skill Points: %d" % _skill_manager.skill_points
		xp_label.text = "Total XP: %d" % _skill_manager.total_xp
