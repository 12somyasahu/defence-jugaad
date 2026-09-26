class_name ShellStyle
extends RefCounted

# Shared look + navigation for the game shell (menu, pause, end-screen buttons).
# Presentation only: gameplay never depends on this file.

const MENU_SCENE: String = "res://ui/shell/main_menu.tscn"
const GAME_SCENE: String = "res://main.tscn"
const FONT: FontFile = preload("res://assets/fonts/videotype.otf")
const GOLD: Color = Color(1.0, 0.82, 0.25)
const CREAM: Color = Color(0.96, 0.91, 0.8)
const CLICK_SFX: String = "res://audio/sfx/pickup.ogg"

static func panel_style() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.06, 0.05, 0.94)
	box.border_color = Color(0.85, 0.68, 0.22, 0.9)
	box.set_border_width_all(3)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(28)
	box.shadow_color = Color(0, 0, 0, 0.5)
	box.shadow_size = 10
	return box

static func _button_box(bg: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

static func button(text: String, font_size: int = 20) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 46)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_focus_color", GOLD)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color.BLACK)
	b.add_theme_constant_override("outline_size", 4)
	b.add_theme_stylebox_override("normal", _button_box(Color(0.2, 0.14, 0.08, 0.95), Color(0.62, 0.48, 0.18)))
	b.add_theme_stylebox_override("hover", _button_box(Color(0.32, 0.22, 0.1, 0.98), GOLD))
	b.add_theme_stylebox_override("focus", _button_box(Color(0.32, 0.22, 0.1, 0.0), GOLD))
	b.add_theme_stylebox_override("pressed", _button_box(Color(0.12, 0.08, 0.05, 1.0), GOLD))
	return b

static func label(text: String, font_size: int, color: Color = CREAM, outline: int = 4) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.0))
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func click_player(parent: Node) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.volume_db = -6.0
	if ResourceLoader.exists(CLICK_SFX):
		player.stream = load(CLICK_SFX)
	parent.add_child(player)
	return player

## Full-screen black rect used for the short scene fades.
static func fade_rect() -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect
