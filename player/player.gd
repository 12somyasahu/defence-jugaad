class_name JugaadPlayer
extends CharacterBody2D

signal hit(direction: Vector2)

@export_range(1.0, 1000.0) var movement_speed: float = 240.0
@export var contact_cooldown: float = 1.0
@export var contact_distance: float = 28.0
@export var knockback_speed: float = 300.0
@export var knockback_deceleration: float = 900.0
var active: bool = true
var facing: Vector2 = Vector2.RIGHT
var enemies: Node2D
var contact_remaining: float = 0.0
var knockback: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector2.ZERO
		return
	contact_remaining = maxf(0.0, contact_remaining - delta)
	if contact_remaining <= 0.0 and is_instance_valid(enemies):
		for child in enemies.get_children():
			var enemy: Gunda = child as Gunda
			if enemy != null and enemy.active and enemy.current_hp > 0 and global_position.distance_to(enemy.global_position) <= contact_distance:
				var direction: Vector2 = (global_position - enemy.global_position).normalized()
				if direction.is_zero_approx():
					direction = Vector2.LEFT
				contact_remaining = contact_cooldown
				knockback = direction * knockback_speed
				hit.emit(direction)
				break
	if knockback.length() > 5.0:
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, knockback_deceleration * delta)
	else:
		knockback = Vector2.ZERO
		velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * movement_speed
		if not velocity.is_zero_approx():
			facing = velocity.normalized()
	move_and_slide()
