class_name Gunda
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

@export_range(1.0, 500.0) var movement_speed: float = 90.0
@export_range(1, 1000) var maximum_hp: int = 30
@export_range(1, 100) var attack_damage: int = 5
@export_range(0.1, 10.0) var attack_cooldown: float = 1.0
@export_range(63.0, 100.0) var attack_distance: float = 66.0
var current_hp: int = 0
var workshop: Workshop
var active: bool = true
var _attack_remaining: float = 0.0

func _ready() -> void:
	current_hp = maximum_hp

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	if not active or current_hp == 0 or not is_instance_valid(workshop) or workshop.current_hp == 0:
		return
	_attack_remaining = maxf(0.0, _attack_remaining - delta)
	var offset: Vector2 = workshop.global_position - global_position
	if offset.length() > attack_distance:
		velocity = offset.normalized() * movement_speed
		move_and_slide()
	elif _attack_remaining <= 0.0:
		_attack_remaining = attack_cooldown
		workshop.receive_damage(attack_damage)

func receive_damage(amount: int) -> void:
	if amount <= 0 or current_hp == 0:
		return
	current_hp = maxi(0, current_hp - amount)
	health_changed.emit(current_hp, maximum_hp)
	if current_hp == 0:
		active = false
		died.emit()
		queue_free()
