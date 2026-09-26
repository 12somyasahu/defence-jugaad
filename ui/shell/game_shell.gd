class_name GameShell
extends CanvasLayer

# In-game shell: ESC pause menu, clickable end-screen buttons and short fades.
# Sits beside gameplay in main.tscn; restart reuses the existing scene-reload path (same as R).

var main: Node
var hud: HUD
var pause_root: Control
var how_to_play: HowToPlay
var resume_button: Button
var pause_how_button: Button
var end_buttons: Dictionary = {} # end panel -> its first button
var _fade: ColorRect
var _click: AudioStreamPlayer
var _leaving: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	main = get_parent()
	hud = main.get_node_or_null("HUD") as HUD
	_build_pause_menu()
	how_to_play = HowToPlay.new()
	add_child(how_to_play)
	how_to_play.closed.connect(func() -> void: pause_how_button.grab_focus())
	_click = ShellStyle.click_player(self)
	if hud:
		_add_end_buttons(hud.victory_panel, "PLAY AGAIN")
		_add_end_buttons(hud.defeat_panel, "TRY AGAIN")
	_fade = ShellStyle.fade_rect()
	add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.35)

func _build_pause_menu() -> void:
	pause_root = Control.new()
	pause_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(pause_root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_root.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_root.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ShellStyle.panel_style())
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(ShellStyle.label("PAUSED", 40, ShellStyle.GOLD, 8))
	resume_button = _button(box, "RESUME", resume)
	pause_how_button = _button(box, "HOW TO PLAY", func() -> void: how_to_play.open())
	_button(box, "RESTART RUN", restart_run)
	_button(box, "MAIN MENU", to_main_menu)
	_button(box, "QUIT GAME", func() -> void: get_tree().quit())
	pause_root.hide()

func _button(parent: Control, text: String, action: Callable) -> Button:
	var b: Button = ShellStyle.button(text)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void:
		if _click.stream:
			_click.play()
		action.call()
	)
	parent.add_child(b)
	return b

func _add_end_buttons(panel: Control, again_text: String) -> void:
	if panel == null or not panel.has_node("VBox"):
		return
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	var again: Button = _button(row, again_text, restart_run)
	again.custom_minimum_size = Vector2(220, 44)
	var menu: Button = _button(row, "MAIN MENU", to_main_menu)
	menu.custom_minimum_size = Vector2(220, 44)
	panel.get_node("VBox").add_child(row)
	end_buttons[panel] = again

func _process(_delta: float) -> void:
	# Keyboard players: focus the first end-screen button once its panel appears.
	for panel in end_buttons:
		var first: Button = end_buttons[panel]
		if panel.is_visible_in_tree() and get_viewport().gui_get_focus_owner() == null:
			first.grab_focus()

func can_pause() -> bool:
	if _leaving or pause_root.visible:
		return false
	if main.get("is_defeated") == true:
		return false
	return hud == null or not hud.end_game_overlay.visible

func is_paused() -> bool:
	return pause_root.visible

func pause() -> void:
	if not can_pause():
		return
	get_tree().paused = true
	pause_root.show()
	resume_button.grab_focus()

func resume() -> void:
	if _leaving:
		return
	how_to_play.hide()
	pause_root.hide()
	get_tree().paused = false

func restart_run() -> void:
	_leave(func() -> void: get_tree().reload_current_scene())

func to_main_menu() -> void:
	_leave(func() -> void: get_tree().change_scene_to_file(ShellStyle.MENU_SCENE))

func _leave(then: Callable) -> void:
	if _leaving:
		return
	_leaving = true
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.25)
	tween.tween_callback(func() -> void:
		get_tree().paused = false
		then.call()
	)

func _unhandled_input(event: InputEvent) -> void:
	if _leaving or not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if pause_root.visible:
		resume()
	elif can_pause():
		pause()
	else:
		return
	get_viewport().set_input_as_handled()
