extends Node
## FreshMartTheme — creates and applies the global UI theme.

static func create() -> Theme:
	var theme = Theme.new()
	
	# Color palette
	var c_bg = Color(0.08, 0.10, 0.08)           # near-black green
	var c_surface = Color(0.12, 0.16, 0.12)       # dark surface
	var c_surface2 = Color(0.15, 0.20, 0.15)      # slightly lighter
	var c_border = Color(0.22, 0.35, 0.22)         # dark border
	var c_accent = Color(0.27, 0.78, 0.27)         # bright green
	var c_accent_hover = Color(0.35, 0.90, 0.35)
	var c_accent_pressed = Color(0.18, 0.60, 0.18)
	var c_text = Color(0.92, 0.95, 0.90)           # near-white
	var c_text_dim = Color(0.60, 0.72, 0.60)       # dimmed text
	var c_danger = Color(0.85, 0.25, 0.25)
	var c_warning = Color(0.95, 0.75, 0.15)
	var c_success = Color(0.25, 0.85, 0.35)
	
	# ---- BUTTON ----
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.13, 0.22, 0.13)
	btn_normal.border_width_left = 1; btn_normal.border_width_top = 1
	btn_normal.border_width_right = 1; btn_normal.border_width_bottom = 2
	btn_normal.border_color = c_border
	btn_normal.corner_radius_top_left = 6; btn_normal.corner_radius_top_right = 6
	btn_normal.corner_radius_bottom_right = 6; btn_normal.corner_radius_bottom_left = 6
	btn_normal.content_margin_left = 16; btn_normal.content_margin_right = 16
	btn_normal.content_margin_top = 8; btn_normal.content_margin_bottom = 8
	
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color(0.18, 0.32, 0.18)
	btn_hover.border_color = c_accent
	btn_hover.border_width_bottom = 3
	
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = Color(0.10, 0.18, 0.10)
	btn_pressed.border_color = c_accent_pressed
	
	var btn_disabled = btn_normal.duplicate()
	btn_disabled.bg_color = Color(0.10, 0.12, 0.10)
	btn_disabled.border_color = Color(0.18, 0.22, 0.18)
	
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_color("font_color", "Button", c_text)
	theme.set_color("font_hover_color", "Button", c_accent)
	theme.set_color("font_pressed_color", "Button", c_text)
	theme.set_color("font_disabled_color", "Button", c_text_dim)
	theme.set_font_size("font_size", "Button", 17)
	
	# ---- PANEL ----
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.14, 0.10, 0.96)
	panel_style.border_width_left = 1; panel_style.border_width_top = 1
	panel_style.border_width_right = 1; panel_style.border_width_bottom = 1
	panel_style.border_color = c_border
	panel_style.corner_radius_top_left = 8; panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8; panel_style.corner_radius_bottom_left = 8
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 8
	theme.set_stylebox("panel", "Panel", panel_style)
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	
	# ---- LABEL ----
	theme.set_color("font_color", "Label", c_text)
	theme.set_font_size("font_size", "Label", 16)
	
	# ---- LINE EDIT ----
	var le_normal = StyleBoxFlat.new()
	le_normal.bg_color = Color(0.07, 0.10, 0.07)
	le_normal.border_width_bottom = 2
	le_normal.border_color = c_border
	le_normal.corner_radius_top_left = 4; le_normal.corner_radius_top_right = 4
	le_normal.corner_radius_bottom_right = 4; le_normal.corner_radius_bottom_left = 4
	le_normal.content_margin_left = 10; le_normal.content_margin_right = 10
	le_normal.content_margin_top = 6; le_normal.content_margin_bottom = 6
	var le_focus = le_normal.duplicate()
	le_focus.border_color = c_accent
	le_focus.border_width_bottom = 3
	theme.set_stylebox("normal", "LineEdit", le_normal)
	theme.set_stylebox("focus", "LineEdit", le_focus)
	theme.set_color("font_color", "LineEdit", c_text)
	theme.set_color("caret_color", "LineEdit", c_accent)
	
	# ---- TAB CONTAINER ----
	var tab_selected = StyleBoxFlat.new()
	tab_selected.bg_color = c_surface2
	tab_selected.border_width_bottom = 3
	tab_selected.border_color = c_accent
	tab_selected.corner_radius_top_left = 6; tab_selected.corner_radius_top_right = 6
	tab_selected.content_margin_left = 12; tab_selected.content_margin_right = 12
	tab_selected.content_margin_top = 6; tab_selected.content_margin_bottom = 6
	var tab_unsel = tab_selected.duplicate()
	tab_unsel.bg_color = c_surface
	tab_unsel.border_width_bottom = 1
	tab_unsel.border_color = c_border
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected)
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unsel)
	theme.set_color("font_selected_color", "TabContainer", c_accent)
	theme.set_color("font_unselected_color", "TabContainer", c_text_dim)
	
	# ---- SCROLL ----
	var scroll_bg = StyleBoxFlat.new()
	scroll_bg.bg_color = Color(0.08, 0.10, 0.08)
	var scroll_grab = StyleBoxFlat.new()
	scroll_grab.bg_color = c_border
	scroll_grab.corner_radius_top_left = 4; scroll_grab.corner_radius_top_right = 4
	scroll_grab.corner_radius_bottom_right = 4; scroll_grab.corner_radius_bottom_left = 4
	var scroll_grab_hover = scroll_grab.duplicate()
	scroll_grab_hover.bg_color = c_accent
	for ctrl in ["HScrollBar", "VScrollBar"]:
		theme.set_stylebox("scroll", ctrl, scroll_bg)
		theme.set_stylebox("grabber", ctrl, scroll_grab)
		theme.set_stylebox("grabber_highlight", ctrl, scroll_grab_hover)
	
	# ---- OPTION BUTTON ----
	theme.set_stylebox("normal", "OptionButton", btn_normal)
	theme.set_stylebox("hover", "OptionButton", btn_hover)
	theme.set_color("font_color", "OptionButton", c_text)
	
	# ---- CHECK BOX ----
	theme.set_color("font_color", "CheckBox", c_text)
	theme.set_font_size("font_size", "CheckBox", 16)
	
	# ---- SPIN BOX ----
	theme.set_color("font_color", "SpinBox", c_text)
	
	# ---- ITEM LIST ----
	var il_bg = StyleBoxFlat.new()
	il_bg.bg_color = Color(0.08, 0.11, 0.08)
	il_bg.border_width_left = 1; il_bg.border_width_right = 1
	il_bg.border_width_top = 1; il_bg.border_width_bottom = 1
	il_bg.border_color = c_border
	var il_selected = StyleBoxFlat.new()
	il_selected.bg_color = Color(0.15, 0.30, 0.15)
	il_selected.border_width_left = 2
	il_selected.border_color = c_accent
	theme.set_stylebox("panel", "ItemList", il_bg)
	theme.set_stylebox("selected", "ItemList", il_selected)
	theme.set_color("font_color", "ItemList", c_text)
	theme.set_color("font_selected_color", "ItemList", c_accent)
	
	# ---- WINDOW ----
	var win_style = StyleBoxFlat.new()
	win_style.bg_color = Color(0.10, 0.14, 0.10, 0.98)
	win_style.border_width_left = 1; win_style.border_width_top = 1
	win_style.border_width_right = 1; win_style.border_width_bottom = 1
	win_style.border_color = c_border
	win_style.corner_radius_top_left = 8; win_style.corner_radius_top_right = 8
	theme.set_stylebox("embedded_border", "Window", win_style)
	
	# ---- HSEPARATOR ----
	var sep = StyleBoxFlat.new()
	sep.bg_color = c_border
	sep.content_margin_top = 1; sep.content_margin_bottom = 1
	theme.set_stylebox("separator", "HSeparator", sep)
	
	# ---- PROGRESS BAR ----
	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.10, 0.14, 0.10)
	pb_bg.border_width_left = 1; pb_bg.border_width_right = 1
	pb_bg.border_width_top = 1; pb_bg.border_width_bottom = 1
	pb_bg.border_color = c_border
	pb_bg.corner_radius_top_left = 4; pb_bg.corner_radius_top_right = 4
	pb_bg.corner_radius_bottom_right = 4; pb_bg.corner_radius_bottom_left = 4
	var pb_fill = StyleBoxFlat.new()
	pb_fill.bg_color = c_accent
	pb_fill.corner_radius_top_left = 4; pb_fill.corner_radius_top_right = 4
	pb_fill.corner_radius_bottom_right = 4; pb_fill.corner_radius_bottom_left = 4
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)
	
	return theme
