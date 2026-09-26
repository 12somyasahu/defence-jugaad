class_name JunkComponent
extends Node2D

enum Type { BATTERY, CYCLE_WHEEL, PRESSURE_COOKER, SPEAKER, TABLE_FAN, RUBBER_BAND }
const DISPLAY_NAMES: Array[String] = ["Battery", "Cycle Wheel", "Pressure Cooker", "Speaker", "Table Fan", "Rubber Band"]
const COLORS: Array[Color] = [Color.YELLOW, Color.LIGHT_GRAY, Color.CORAL, Color.MEDIUM_PURPLE, Color.LIGHT_SKY_BLUE, Color.LIME_GREEN]
# Presentation only, indexed by Type.
const TEXTURES: Array[Texture2D] = [
	preload("res://assets/components/battery.png"),
	preload("res://assets/components/cycle_wheel.png"),
	preload("res://assets/components/pressure_cooker.png"),
	preload("res://assets/components/speaker.png"),
	preload("res://assets/components/table_fan.png"),
	preload("res://assets/components/rubber_band.png"),
]
const SPRITE_SIZE: float = 40.0

@export var component_type: Type = Type.BATTERY
var held: bool = false

func _ready() -> void:
	$Name.text = display_name()
	var sprite: Sprite2D = $Sprite
	sprite.texture = TEXTURES[component_type]
	if sprite.texture != null:
		sprite.scale = Vector2.ONE * SPRITE_SIZE / maxf(sprite.texture.get_width(), sprite.texture.get_height())
	queue_redraw()

func icon() -> Texture2D:
	return TEXTURES[component_type]

func display_name() -> String:
	return DISPLAY_NAMES[component_type]

func set_held(value: bool) -> void:
	held = value
	$Name.visible = not held

func _draw() -> void:
	# Procedural shapes remain as a fallback if a texture is ever missing.
	if $Sprite.texture != null:
		return
	var color: Color = COLORS[component_type]
	match component_type:
		Type.BATTERY:
			draw_rect(Rect2(-10, -14, 20, 28), color)
			draw_rect(Rect2(-5, -18, 10, 4), color)
		Type.CYCLE_WHEEL:
			draw_arc(Vector2.ZERO, 15, 0, TAU, 24, color, 3)
			draw_line(Vector2(-15, 0), Vector2(15, 0), color, 2)
			draw_line(Vector2(0, -15), Vector2(0, 15), color, 2)
		Type.PRESSURE_COOKER:
			draw_rect(Rect2(-14, -9, 28, 22), color)
			draw_line(Vector2(-18, -12), Vector2(18, -12), color, 4)
			draw_line(Vector2.ZERO, Vector2(0, -19), color, 4)
		Type.SPEAKER:
			draw_rect(Rect2(-13, -17, 26, 34), color)
			draw_circle(Vector2(0, 5), 8, Color(0.12, 0.12, 0.18))
			draw_circle(Vector2(0, -10), 4, Color(0.12, 0.12, 0.18))
		Type.TABLE_FAN:
			draw_arc(Vector2(0, -4), 13, 0, TAU, 20, color, 2)
			for i in 3:
				draw_line(Vector2(0, -4), Vector2(0, -4) + Vector2.RIGHT.rotated(i * TAU / 3) * 11, color, 5)
			draw_line(Vector2(0, 8), Vector2(0, 18), color, 4)
			draw_line(Vector2(-9, 18), Vector2(9, 18), color, 3)
		Type.RUBBER_BAND:
			draw_arc(Vector2.ZERO, 13, 0, TAU, 20, color, 4)
