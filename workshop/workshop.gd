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
