class_name RunStats
extends Node

signal changed
var normal_waves_completed: int = 0
var enemies_thoked: int = 0
var jugaads_built: int = 0
var scrap_collected: int = 0
var thoks: int = 0
var mods_purchased: int = 0
var active: bool = true

func setup(main: Node) -> void:
	main.get_node("Enemies").child_entered_tree.connect(_register_enemy)
	main.get_node("JugaadLoop").weapon_crafted.connect(_on_crafted)
	main.get_node("JugaadLoop/Weapons").child_entered_tree.connect(_register_weapon)
	main.get_node("ScrapEconomy").scrap_earned.connect(func(amount: int) -> void:
		if active:
			scrap_collected += amount
			changed.emit()
	)
	main.get_node("WaveDirector").wave_cleared.connect(func(_wave: int) -> void:
		if active:
			normal_waves_completed += 1
			changed.emit()
	)
	main.get_node("UpgradeSystem").mod_purchased.connect(func(_id: StringName, _cost: int) -> void:
		if active:
			mods_purchased += 1
			changed.emit()
	)

func _register_enemy(child: Node) -> void:
	var enemy: Gunda = child as Gunda
	if enemy != null and not enemy is BossPart:
		enemy.died.connect(func() -> void:
			if active:
				enemies_thoked += 1
				changed.emit()
		, CONNECT_ONE_SHOT)

func _on_crafted(weapon: JugaadWeapon) -> void:
	if active:
		jugaads_built += 1
		changed.emit()
	_register_weapon(weapon)

func _register_weapon(child: Node) -> void:
	var weapon: JugaadWeapon = child as JugaadWeapon
	if weapon != null and not weapon.repair_hit.is_connected(_on_thak):
		weapon.repair_hit.connect(_on_thak)

func _on_thak(_progress: int, _required: int) -> void:
	if active:
		thoks += 1
		changed.emit()

func snapshot() -> Dictionary:
	return {"waves": normal_waves_completed, "kills": enemies_thoked, "built": jugaads_built, "scrap": scrap_collected, "thoks": thoks, "mods": mods_purchased}
