class_name EnemyPresentation
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var _enemy: Gunda
var _hit_tween: Tween

func _ready() -> void:
	_enemy = get_parent() as Gunda
	var placeholder: CanvasItem = get_parent().get_node_or_null("Placeholder") as CanvasItem
	if placeholder:
		placeholder.visible = false

	if _enemy:
		_enemy.health_changed.connect(_on_health_changed)

func _process(_delta: float) -> void:
	if not sprite or not is_instance_valid(_enemy):
		return
	if absf(_enemy.velocity.x) > 5.0:
		sprite.flip_h = _enemy.velocity.x < 0.0

func _on_health_changed(_current: int, _maximum: int) -> void:
	if not sprite:
		return
	if _hit_tween != null:
		_hit_tween.kill()
	sprite.modulate = Color(2.5, 0.5, 0.5, 1.0)
	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
