class_name ThekedaarPresentation
extends Node2D

const TEX_WEST: Texture2D = preload("res://assets/enemies/thekedaar/thekedaar_west.png")
const TEX_EAST: Texture2D = preload("res://assets/enemies/thekedaar/thekedaar_east.png")
const TEX_NORTH: Texture2D = preload("res://assets/enemies/thekedaar/thekedaar_north.png")
const TEX_SOUTH: Texture2D = preload("res://assets/enemies/thekedaar/thekedaar_south.png")

@onready var sprite: Sprite2D = $Sprite2D
var _thekedaar: Thekedaar
var _hit_tween: Tween

func _ready() -> void:
	_thekedaar = get_parent() as Thekedaar
	if _thekedaar:
		_thekedaar.chassis_health_changed.connect(_on_health_changed)
		_update_direction()

func _process(_delta: float) -> void:
	if not sprite or not is_instance_valid(_thekedaar):
		return
	_update_direction()

func _update_direction() -> void:
	if not sprite or not _thekedaar:
		return
	var dir: Vector2 = _thekedaar.facing
	var tex: Texture2D = TEX_WEST
	if absf(dir.x) >= absf(dir.y):
		tex = TEX_EAST if dir.x > 0.0 else TEX_WEST
	else:
		tex = TEX_SOUTH if dir.y > 0.0 else TEX_NORTH
	if sprite.texture != tex:
		sprite.texture = tex
		var tex_size: Vector2 = tex.get_size()
		var max_dim: float = maxf(tex_size.x, tex_size.y)
		if max_dim > 0:
			var s: float = 140.0 / max_dim
			sprite.scale = Vector2(s, s)

func _on_health_changed(_current: int, _maximum: int) -> void:
	if not sprite:
		return
	if _hit_tween != null:
		_hit_tween.kill()
	sprite.modulate = Color(2.5, 0.5, 0.5, 1.0)
	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
