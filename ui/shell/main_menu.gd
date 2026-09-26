class_name MainMenu
extends Control

# Title screen. PLAY loads a fresh main.tscn; the run itself initialises as it always has.

const GROUND: Texture2D = preload("res://assets/terrain/base_ground_tile_01.png")
const WORKSHOP: Texture2D = preload("res://assets/workshop/workshop.png")
const THEKEDAAR: Texture2D = preload("res://assets/enemies/thekedaar/thekedaar_west.png")
const ART: Array[Texture2D] = [
	preload("res://assets/jugaads/chakri_gun.png"),
	preload("res://assets/jugaads/pressure_horn.png"),
	preload("res://assets/jugaads/turbo_pankha.png"),
	preload("res://assets/jugaads/aandhi_dj.png"),
	preload("res://assets/jugaads/jhatka_sling.png"),
	preload("res://assets/components/pressure_cooker.png"),
	preload("res://assets/components/cycle_wheel.png"),
	preload("res://assets/components/battery.png"),
]
const MUSIC: String = "res://audio/music/preparation_theme.ogg"

var play_button: Button
var how_button: Button
var quit_button: Button
var how_to_play: HowToPlay
var music: AudioStreamPlayer
var _fade: ColorRect
var _click: AudioStreamPlayer
var _leaving: bool = false

func _ready() -> void:
	get_tree().paused = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_menu()
	how_to_play = HowToPlay.new()
	add_child(how_to_play)
	how_to_play.closed.connect(func() -> void: how_button.grab_focus())
	_click = ShellStyle.click_player(self)
	music = AudioStreamPlayer.new()
	music.volume_db = -8.0
	if ResourceLoader.exists(MUSIC):
		var stream: AudioStream = load(MUSIC)
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		music.stream = stream
	add_child(music)
	if music.stream:
		music.play()
	_fade = ShellStyle.fade_rect()
	add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.4)
	play_button.grab_focus()

func _build_background() -> void:
	var ground: TextureRect = TextureRect.new()
	ground.texture = GROUND
	ground.stretch_mode = TextureRect.STRETCH_TILE
	# Same seam-hiding shader the arena ground uses.
	var ground_material: ShaderMaterial = ShaderMaterial.new()
	ground_material.shader = preload("res://arena/ground_tile.gdshader")
	ground.material = ground_material
	ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ground.modulate = Color(0.62, 0.55, 0.5)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	# Art cluster on the left: the Workshop surrounded by its ridiculous defences.
	var art: Control = Control.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	art.custom_minimum_size = Vector2(560, 0)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	_sprite(art, WORKSHOP, Vector2(290, 350), 230.0)
	_sprite(art, THEKEDAAR, Vector2(500, 150), 130.0).modulate = Color(1, 1, 1, 0.9)
	var spots: Array[Vector2] = [Vector2(120, 210), Vector2(470, 330), Vector2(120, 470), Vector2(430, 520), Vector2(270, 170), Vector2(60, 340), Vector2(290, 560), Vector2(520, 440)]
	for i in ART.size():
		var sprite: TextureRect = _sprite(art, ART[i], spots[i], 70.0 if i < 5 else 44.0)
		sprite.rotation = deg_to_rad([-8, 6, -4, 10, -12, 14, -6, 8][i])
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.05, 0.03, 0.02, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

func _sprite(parent: Control, tex: Texture2D, center: Vector2, longest: float) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var ratio: float = longest / maxf(tex.get_width(), tex.get_height())
	rect.size = Vector2(tex.get_width(), tex.get_height()) * ratio
	rect.position = center - rect.size * 0.5
	rect.pivot_offset = rect.size * 0.5
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect

func _build_menu() -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.anchor_left = 0.52
	column.anchor_right = 0.97
	column.anchor_top = 0.0
	column.anchor_bottom = 1.0
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	column.add_child(ShellStyle.label("DEFENCE", 64, ShellStyle.GOLD, 10))
	column.add_child(ShellStyle.label("JUGAAD", 84, Color(1.0, 0.55, 0.15), 12))
	column.add_child(ShellStyle.label("JODO. BANAO. BACHAO.", 22, ShellStyle.CREAM, 5))
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	column.add_child(spacer)
	play_button = _menu_button(column, "PLAY", _on_play)
	how_button = _menu_button(column, "HOW TO PLAY", _on_how)
	quit_button = _menu_button(column, "QUIT", _on_quit)
	var footer: Label = ShellStyle.label("Made for MP Game Udaan 2026", 12, Color(0.85, 0.8, 0.7, 0.7), 3)
	footer.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	footer.position = Vector2(-200, -30)
	footer.size = Vector2(400, 20)
	footer.anchor_left = 0.745
	footer.anchor_right = 0.745
	add_child(footer)

func _menu_button(parent: Control, text: String, action: Callable) -> Button:
	var b: Button = ShellStyle.button(text, 22)
	b.custom_minimum_size = Vector2(300, 52)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void:
		if _click.stream:
			_click.play()
		action.call()
	)
	parent.add_child(b)
	return b

func _on_play() -> void:
	if _leaving:
		return
	_leaving = true
	for b in [play_button, how_button, quit_button]:
		b.disabled = true
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_fade, "color:a", 1.0, 0.3)
	tween.tween_property(music, "volume_db", -40.0, 0.3)
	tween.chain().tween_callback(func() -> void: get_tree().change_scene_to_file(ShellStyle.GAME_SCENE))

func _on_how() -> void:
	how_to_play.open()

func _on_quit() -> void:
	get_tree().quit()
