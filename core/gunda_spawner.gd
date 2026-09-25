class_name GundaSpawner
extends Node2D

const GUNDA: PackedScene = preload("res://enemies/gunda.tscn")
const DEBUG_VARIANTS: Array[PackedScene] = [preload("res://enemies/chotu.tscn"), preload("res://enemies/pehelwan.tscn")]
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
		_spawn(GUNDA)

func debug_spawn_variant(index: int) -> Gunda:
	if not OS.is_debug_build() or index < 0 or index >= DEBUG_VARIANTS.size():
		return null
	return _spawn(DEBUG_VARIANTS[index])

func _spawn(scene: PackedScene) -> Gunda:
	if not active or not is_instance_valid(workshop) or workshop.current_hp <= 0 or not is_instance_valid(enemies):
		return null
	var count: int = 0
	for child in enemies.get_children():
		var existing: Gunda = child as Gunda
		if existing != null and existing.current_hp > 0:
			count += 1
	if count >= maximum_enemies:
		return null
	var enemy: Gunda = scene.instantiate()
	enemy.workshop = workshop
	enemies.add_child(enemy)
	# Three deterministic entry positions, all on the east side, including debug variants.
	enemy.global_position = global_position + Vector2(0, (_spawn_index % 3 - 1) * 80)
	_spawn_index += 1
	return enemy
