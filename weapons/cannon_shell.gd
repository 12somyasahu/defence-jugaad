extends Node2D

signal exploded(at: Vector2, radius: float)

var target_position: Vector2
var enemies: Node2D
var damage: int = 42
var speed: float = 240.0
var blast_radius: float = 75.0
var _detonated: bool = false
var _flash_remaining: float = 0.18

func _physics_process(delta: float) -> void:
	if _detonated:
		_flash_remaining -= delta
		queue_redraw()
		if _flash_remaining <= 0.0:
			queue_free()
		return
	global_position = global_position.move_toward(target_position, speed * delta)
	queue_redraw()
	if global_position.distance_squared_to(target_position) > 0.01:
		return
	_detonated = true
	if is_instance_valid(enemies):
		for child in enemies.get_children():
			var enemy: Gunda = child as Gunda
			if enemy != null and enemy.active and enemy.current_hp > 0 and global_position.distance_to(enemy.global_position) <= blast_radius:
				enemy.receive_damage(damage)
	exploded.emit(global_position, blast_radius)
	queue_redraw()

func _draw() -> void:
	if _detonated:
		draw_arc(Vector2.ZERO, blast_radius * (1.0 - _flash_remaining / 0.18), 0, TAU, 32, Color.ORANGE, 4)
	else:
		draw_circle(Vector2.ZERO, 7, Color.ORANGE)
		# Fixed landing marker makes the delayed, dodgeable blast readable.
		draw_arc(to_local(target_position), blast_radius, 0, TAU, 32, Color(1, 0.65, 0, 0.4), 1)
