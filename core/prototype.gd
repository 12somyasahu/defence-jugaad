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
@onready var economy: Node = $ScrapEconomy
@onready var kabadiwala: Node2D = $Kabadiwala
var _debug_shop_spawner_was_active: bool = false
const PROMPT_SECONDS: float = 4.0
var _prompt_message: String = ""
var _prompt_remaining: float = 0.0

func _ready() -> void:
	spawner.workshop = workshop
	spawner.enemies = enemies
	# Gameplay owns Scrap; the HUD only displays it. Waves do not exist yet.
	jugaad_loop.get_node("Feedback").hide()
	hud.set_wave_info_visible(false)
	hud.set_scrap_visible(true)
	economy.scrap_changed.connect(hud.set_scrap)
	economy.scrap_earned.connect(_on_scrap_earned)
	hud.set_scrap(economy.scrap)
	enemies.child_entered_tree.connect(_on_enemy_entered)
	for child in enemies.get_children():
		_on_enemy_entered(child)
	jugaad_loop.hands_changed.connect(_on_hands_changed)
	jugaad_loop.feedback.connect(_on_feedback)
	jugaad_loop.setup(player, workshop, enemies)
	kabadiwala.setup(economy, jugaad_loop, player)
	kabadiwala.feedback.connect(_on_feedback)
	workshop.health_changed.connect(_on_health_changed)
	workshop.destroyed.connect(_on_destroyed)
	_on_health_changed(workshop.current_hp, workshop.maximum_hp)
	$PrototypeOverlay/DebugHint.text = "DEBUG: F3 damage | F4 Chotu | F5 Pehelwan (cap 6) | F6 Kabadiwala open/close"
	if not OS.is_debug_build():
		$PrototypeOverlay/DebugHint.hide()

func _process(delta: float) -> void:
	_prompt_remaining = maxf(0.0, _prompt_remaining - delta)
	_update_prompt()

func _on_enemy_entered(child: Node) -> void:
	var enemy: Gunda = child as Gunda
	if enemy != null:
		economy.register_enemy(enemy)

func _on_scrap_earned(amount: int) -> void:
	_on_feedback("+%d SCRAP" % amount)

func debug_toggle_shop() -> void:
	if not OS.is_debug_build() or is_defeated:
		return
	if kabadiwala.available:
		kabadiwala.close_session()
		spawner.active = _debug_shop_spawner_was_active
		_on_feedback("KABADIWALA closed.")
	else:
		_debug_shop_spawner_was_active = spawner.active
		kabadiwala.open_session()
		spawner.active = false

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
	elif OS.is_debug_build() and not is_defeated and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F6:
			debug_toggle_shop()
		elif event.physical_keycode in [KEY_F4, KEY_F5]:
			var enemy: Gunda = spawner.debug_spawn_variant(0 if event.physical_keycode == KEY_F4 else 1)
			_on_feedback("DEBUG: spawned " + enemy.name if enemy != null else "DEBUG: spawning paused or enemy cap reached.")

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
	economy.active = false
	kabadiwala.stop()
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
