class_name Workshop
extends StaticBody2D

signal health_changed(current: int, maximum: int)
signal destroyed

@export_range(1, 10000) var maximum_hp: int = 500
var current_hp: int = 0

func _ready() -> void:
	current_hp = maximum_hp

func receive_damage(amount: int) -> void:
	if amount <= 0 or current_hp == 0:
		return
	current_hp = maxi(0, current_hp - amount)
	health_changed.emit(current_hp, maximum_hp)
	if current_hp == 0:
		destroyed.emit()

## Restores HP up to maximum_hp; returns the amount actually restored. A destroyed Workshop stays destroyed.
func heal(amount: int) -> int:
	if amount <= 0 or current_hp == 0 or current_hp >= maximum_hp:
		return 0
	var before: int = current_hp
	current_hp = mini(maximum_hp, current_hp + amount)
	health_changed.emit(current_hp, maximum_hp)
	return current_hp - before
