class_name JugaadPlayer
extends CharacterBody2D

@export_range(1.0, 1000.0) var movement_speed: float = 240.0
var active: bool = true
var facing: Vector2 = Vector2.RIGHT

func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * movement_speed if active else Vector2.ZERO
	if not velocity.is_zero_approx():
		facing = velocity.normalized()
	move_and_slide()
