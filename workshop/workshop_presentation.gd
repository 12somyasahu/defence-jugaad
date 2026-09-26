class_name WorkshopPresentation
extends Node2D

const TEX_100: Texture2D = preload("res://assets/workshop/workshop.png")
const TEX_75: Texture2D = preload("res://assets/workshop/workshop_damaged_75.png")
const TEX_50: Texture2D = preload("res://assets/workshop/workshop_damaged_50.png")
const TEX_25: Texture2D = preload("res://assets/workshop/workshop_damaged_25.png")
const TEX_0: Texture2D = preload("res://assets/workshop/workshop_destroyed.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var smoke_particles: CPUParticles2D = $SmokeParticles

var _workshop: Workshop
var _flash_tween: Tween
var _shake_tween: Tween
var _orig_sprite_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	_workshop = get_parent() as Workshop
	if sprite:
		_orig_sprite_pos = sprite.position
	if smoke_particles:
		smoke_particles.emitting = false

	# Hide primitive placeholder if present
	var placeholder: CanvasItem = get_parent().get_node_or_null("Placeholder") as CanvasItem
	if placeholder:
		placeholder.visible = false

	if _workshop:
		_workshop.health_changed.connect(_on_health_changed)
		_workshop.destroyed.connect(_on_destroyed)
		var max_hp: int = _workshop.maximum_hp
		var cur_hp: int = _workshop.current_hp if _workshop.current_hp > 0 else max_hp
		_update_visual_state(cur_hp, max_hp, false)

func _update_visual_state(current_hp: int, max_hp: int, animate: bool = true) -> void:
	if not sprite:
		return
	var ratio: float = float(current_hp) / float(max(1, max_hp))
	var target_tex: Texture2D = TEX_100
	if ratio <= 0.0:
		target_tex = TEX_0
	elif ratio <= 0.25:
		target_tex = TEX_25
	elif ratio <= 0.50:
		target_tex = TEX_50
	elif ratio <= 0.75:
		target_tex = TEX_75
	else:
		target_tex = TEX_100

	sprite.texture = target_tex

	# Low-HP smoke warning below 25%
	if smoke_particles:
		smoke_particles.emitting = (ratio > 0.0 and ratio <= 0.25)

	if animate and ratio > 0.0:
		_play_hit_effects()

func _play_hit_effects() -> void:
	if not sprite:
		return
	# Red/white damage flash
	if _flash_tween != null:
		_flash_tween.kill()
	sprite.modulate = Color(2.0, 0.7, 0.7, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)

	# Impact shake
	if _shake_tween != null:
		_shake_tween.kill()
	_shake_tween = create_tween()
	_shake_tween.tween_property(sprite, "position", _orig_sprite_pos + Vector2(randf_range(-4, 4), randf_range(-4, 4)), 0.05)
	_shake_tween.tween_property(sprite, "position", _orig_sprite_pos + Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.05)
	_shake_tween.tween_property(sprite, "position", _orig_sprite_pos, 0.08)

func _on_health_changed(current: int, maximum: int) -> void:
	_update_visual_state(current, maximum, true)

func _on_destroyed() -> void:
	_update_visual_state(0, _workshop.maximum_hp, false)
	if smoke_particles:
		smoke_particles.emitting = true
		smoke_particles.amount = 30
