class_name ScrapProjectile
extends Node2D

var direction: Vector2 = Vector2.RIGHT
var damage: int = 10
var speed: float = 520.0
var remaining_distance: float = 300.0

func _physics_process(delta: float) -> void:
	var travel: float = minf(speed * delta, remaining_distance)
	var destination: Vector2 = global_position + direction * travel
	# Sweep each step against the enemy layer so fast scrap cannot tunnel.
	var query := PhysicsRayQueryParameters2D.create(global_position, destination, 4)
	query.hit_from_inside = true
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var enemy: Gunda = hit.collider as Gunda
		if is_instance_valid(enemy) and enemy.current_hp > 0:
			enemy.receive_damage(damage)
		queue_free()
		return
	global_position = destination
	remaining_distance -= travel
	if remaining_distance <= 0:
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(-5, -3, 10, 6), Color.LIME_GREEN)
