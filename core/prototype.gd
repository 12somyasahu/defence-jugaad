extends Node2D

signal defeated

var is_defeated: bool = false
@onready var player: JugaadPlayer = $Player
@onready var workshop: Workshop = $Workshop
@onready var enemies: Node2D = $Enemies
@onready var spawner: GundaSpawner = $EastSpawn
@onready var status: Label = $PrototypeOverlay/Status
@onready var defeat_label: Label = $PrototypeOverlay/Defeat
@onready var jugaad_loop: JugaadLoop = $JugaadLoop

func _ready() -> void:
	spawner.workshop = workshop
	spawner.enemies = enemies
	jugaad_loop.setup(player, workshop, enemies)
	workshop.health_changed.connect(_on_health_changed)
	workshop.destroyed.connect(_on_destroyed)
	_on_health_changed(workshop.current_hp, workshop.maximum_hp)
	if not OS.is_debug_build():
		$PrototypeOverlay/DebugHint.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and not event.is_echo():
		get_tree().reload_current_scene()
	elif OS.is_debug_build() and event.is_action_pressed("debug_damage_gunda") and not event.is_echo():
		debug_damage_gunda()

func debug_damage_gunda() -> void:
	# Temporary M1 test control; deliberately unrelated to player position/combat.
	if not OS.is_debug_build() or is_defeated:
		return
	for child in enemies.get_children():
		var enemy: Gunda = child as Gunda
		if enemy != null and enemy.current_hp > 0:
			enemy.receive_damage(15)
			break

func _on_health_changed(current: int, maximum: int) -> void:
	status.text = "Workshop HP: %d / %d   |   WASD / arrows: move   |   R: restart" % [current, maximum]

func _on_destroyed() -> void:
	if is_defeated:
		return
	is_defeated = true
	player.active = false
	player.velocity = Vector2.ZERO
	spawner.active = false
	jugaad_loop.stop()
	for child in enemies.get_children():
		var enemy: Gunda = child as Gunda
		if enemy != null:
			enemy.active = false
			enemy.velocity = Vector2.ZERO
	defeat_label.show()
	defeated.emit()
