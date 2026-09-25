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
@onready var hud: HUD = $HUD
const PROMPT_SECONDS: float = 4.0
var _prompt_message: String = ""
var _prompt_remaining: float = 0.0

func _ready() -> void:
	spawner.workshop = workshop
	spawner.enemies = enemies
	# HUD replaces the prototype hand/message labels; wave and scrap systems do not exist yet.
	jugaad_loop.get_node("Feedback").hide()
	hud.set_wave_info_visible(false)
	jugaad_loop.hands_changed.connect(_on_hands_changed)
	jugaad_loop.feedback.connect(_on_feedback)
	jugaad_loop.setup(player, workshop, enemies)
	workshop.health_changed.connect(_on_health_changed)
	workshop.destroyed.connect(_on_destroyed)
	_on_health_changed(workshop.current_hp, workshop.maximum_hp)
	if not OS.is_debug_build():
		$PrototypeOverlay/DebugHint.hide()

func _process(delta: float) -> void:
	_prompt_remaining = maxf(0.0, _prompt_remaining - delta)
	_update_prompt()

func _on_hands_changed(left: JunkComponent, right: JunkComponent) -> void:
	hud.set_left_hand_item(left.icon() if is_instance_valid(left) else null, left.display_name() if is_instance_valid(left) else "")
	hud.set_right_hand_item(right.icon() if is_instance_valid(right) else null, right.display_name() if is_instance_valid(right) else "")

func _on_feedback(message: String) -> void:
	_prompt_message = message
	_prompt_remaining = PROMPT_SECONDS
	_update_prompt()

func _update_prompt() -> void:
	if is_defeated:
		hud.set_prompt("")
	elif _prompt_remaining > 0.0:
		hud.set_prompt(_prompt_message)
	elif is_instance_valid(jugaad_loop.carried_weapon):
		hud.set_prompt("[E] PLACE %s" % JugaadWeapon.NAMES[jugaad_loop.carried_weapon.kind])
	elif is_instance_valid(jugaad_loop.left_hand) and is_instance_valid(jugaad_loop.right_hand):
		hud.set_prompt("[Q] COMBINE   [1] / [2] DROP")
	else:
		hud.set_prompt("")

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
	hud.update_workshop_hp(current, maximum)
	status.text = "WASD / arrows: move   E: pick up / place / repair   Q: combine   1 / 2: drop   R: restart"

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
	_update_prompt()
	defeated.emit()
