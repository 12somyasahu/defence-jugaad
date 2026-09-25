class_name PlayerPresentation
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var _player: JugaadPlayer
var _hit_tween: Tween

func _ready() -> void:
	_player = get_parent() as JugaadPlayer
	var placeholder: CanvasItem = get_parent().get_node_or_null("Placeholder") as CanvasItem
	if placeholder:
		placeholder.visible = false

	if _player:
		_player.hit.connect(_on_hit)

func _process(_delta: float) -> void:
	if not sprite or not is_instance_valid(_player):
		return
	if absf(_player.facing.x) > 0.1:
		sprite.flip_h = _player.facing.x < 0.0

func _on_hit(_direction: Vector2) -> void:
	if not sprite:
		return
	if _hit_tween != null:
		_hit_tween.kill()
	sprite.modulate = Color(2.0, 0.4, 0.4, 1.0)
	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
