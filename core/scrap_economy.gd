extends Node

signal scrap_changed(total: int)
signal scrap_earned(amount: int)

var scrap: int = 0
var active: bool = true

func register_enemy(enemy: Gunda) -> void:
	var callback: Callable = _on_enemy_died.bind(enemy)
	if not enemy.died.is_connected(callback):
		enemy.died.connect(callback, CONNECT_ONE_SHOT)

func _on_enemy_died(enemy: Gunda) -> void:
	# Only the real death signal pays; tree exits/restarts/despawns never do.
	if not active or not is_instance_valid(enemy) or enemy.current_hp != 0:
		return
	var reward: int = maxi(0, enemy.scrap_reward)
	if reward == 0:
		return
	scrap += reward
	scrap_changed.emit(scrap)
	scrap_earned.emit(reward)

func try_spend(amount: int) -> bool:
	if not active or amount <= 0 or scrap < amount:
		return false
	scrap -= amount
	scrap_changed.emit(scrap)
	return true
