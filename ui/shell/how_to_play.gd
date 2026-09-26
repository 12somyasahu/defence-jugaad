class_name HowToPlay
extends Control

# Shared How To Play card, used by the main menu and the pause menu.
signal closed

const CONTROLS: Array = [
	["WASD / ARROWS", "Move"],
	["E", "Pick Up / Interact / Place / Repair"],
	["Q", "Combine the two items you're holding"],
	["1 / 2", "Drop left / right held component"],
	["ESC", "Pause"],
]

var back_button: Button
var _click: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 0)
	panel.add_theme_stylebox_override("panel", ShellStyle.panel_style())
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	box.add_child(ShellStyle.label("HOW TO PLAY", 30, ShellStyle.GOLD, 6))
	box.add_child(_heading("OBJECTIVE"))
	var objective: Label = ShellStyle.label("Protect the Jugaad Workshop. Collect junk, combine two items into Jugaad weapons, place them around the Workshop and survive the attacks.", 15)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size = Vector2(620, 0)
	box.add_child(objective)

	box.add_child(_heading("CONTROLS"))
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for row in CONTROLS:
		var key: Label = ShellStyle.label(row[0], 15, ShellStyle.GOLD)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		key.custom_minimum_size = Vector2(170, 0)
		grid.add_child(key)
		var action: Label = ShellStyle.label(row[1], 15)
		action.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(action)
	box.add_child(grid)

	box.add_child(_heading("CORE LOOP"))
	box.add_child(ShellStyle.label("COLLECT  >  COMBINE  >  PLACE  >  DEFEND  >  REPAIR", 18, Color(0.45, 0.9, 1.0)))
	var hint: Label = ShellStyle.label("Which junk makes which Jugaad? Try it and find out.", 13, Color(0.8, 0.75, 0.65), 3)
	box.add_child(hint)

	back_button = ShellStyle.button("BACK")
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(close)
	box.add_child(back_button)
	_click = ShellStyle.click_player(self)
	hide()

func _heading(text: String) -> Label:
	return ShellStyle.label(text, 17, Color(1.0, 0.6, 0.25))

func open() -> void:
	show()
	back_button.grab_focus()

func close() -> void:
	if not visible:
		return
	if _click.stream:
		_click.play()
	hide()
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close()
