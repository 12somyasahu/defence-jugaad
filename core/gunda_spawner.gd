class_name GundaSpawner
extends Node2D

const GUNDA: PackedScene = preload("res://enemies/gunda.tscn")
@export_range(0.2, 30.0) var spawn_interval: float = 3.0
@export_range(1, 30) var maximum_enemies: int = 6
var workshop: Workshop
var enemies: Node2D
var active: bool = true
var _remaining: float = 1.0
var _spawn_index: int = 0

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(workshop) or workshop.current_hp == 0:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		_remaining = spawn_interval
		var count: int = 0
		for child in enemies.get_children():
			var existing: Gunda = child as Gunda
			if existing != null and existing.current_hp > 0:
				count += 1
		if count < maximum_enemies:
			var enemy: Gunda = GUNDA.instantiate()
			enemy.workshop = workshop
			enemies.add_child(enemy)
			# Three deterministic entry positions, all on the east side.
			enemy.global_position = global_position + Vector2(0, (_spawn_index % 3 - 1) * 80)
			_spawn_index += 1
