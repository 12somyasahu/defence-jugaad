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
@onready var arena: PrototypeArena = $Arena
@onready var camera: Camera2D = $Camera2D
@onready var wave_director: WaveDirector = $WaveDirector
@onready var event_director: EventDirector = $EventDirector
@onready var upgrades: UpgradeSystem = $UpgradeSystem
const PROMPT_SECONDS: float = 4.0
var _prompt_message: String = ""
var _prompt_remaining: float = 0.0

func _ready() -> void:
	spawner.workshop = workshop
	spawner.enemies = enemies
	# Gameplay owns Scrap and wave state; the HUD only displays them.
	jugaad_loop.get_node("Feedback").hide()
	hud.set_wave_info_visible(true)
	hud.set_scrap_visible(true)
	economy.scrap_changed.connect(hud.set_scrap)
	economy.scrap_earned.connect(_on_scrap_earned)
	hud.set_scrap(economy.scrap)
	enemies.child_entered_tree.connect(_on_enemy_entered)
	for child in enemies.get_children():
		_on_enemy_entered(child)
	jugaad_loop.hands_changed.connect(_on_hands_changed)
	jugaad_loop.feedback.connect(_on_feedback)
	jugaad_loop.upgrades = upgrades
	jugaad_loop.setup(player, workshop, enemies)
	kabadiwala.setup(economy, jugaad_loop, player, upgrades)
	upgrades.setup(economy, workshop, jugaad_loop, wave_director)
	upgrades.feedback.connect(_on_feedback)
	upgrades.mods_changed.connect(_on_mods_changed)
	kabadiwala.feedback.connect(_on_feedback)
	kabadiwala.availability_changed.connect(_on_shop_availability_changed)
	arena.camera = camera
	arena.bounds_changed.connect(_on_arena_bounds_changed)
	var routes: Array[AttackRoute] = []
	for child in $AttackRoutes.get_children():
		routes.append(child as AttackRoute)
	wave_director.setup(workshop, enemies, kabadiwala, arena, routes)
	wave_director.status_changed.connect(_refresh_wave_hud)
	wave_director.announcement.connect(hud.show_announcement)
	wave_director.victory.connect(_on_victory)
	event_director.setup(wave_director, kabadiwala, jugaad_loop)
	event_director.status_changed.connect(_refresh_wave_hud)
	event_director.announcement.connect(hud.show_announcement)
	workshop.health_changed.connect(_on_health_changed)
	workshop.destroyed.connect(_on_destroyed)
	_on_health_changed(workshop.current_hp, workshop.maximum_hp)
	$PrototypeOverlay/DebugHint.text = "DEBUG: F3 damage | F4 Chotu | F5 Pehelwan (cap 6, not wave-owned) | F6 Kabadiwala open/close | F7 skip timer | F8 force next event | F11 +20 Scrap | F12 grant next mod"
	if not OS.is_debug_build():
		$PrototypeOverlay/DebugHint.hide()
	wave_director.start()

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
	# DEBUG override only; production opening/closing belongs to WaveDirector.
	if not OS.is_debug_build() or is_defeated:
		return
	if kabadiwala.available:
		kabadiwala.close_session()
		_on_feedback("DEBUG: KABADIWALA closed.")
	else:
		kabadiwala.open_session()
		# Mirrors M4B: wave spawning pauses while a debug shop is open mid-combat.
		wave_director.debug_spawning_paused = wave_director.state == WaveDirector.State.COMBAT

func _on_shop_availability_changed(available: bool) -> void:
	if not available:
		wave_director.debug_spawning_paused = false
	_refresh_wave_hud()

func _on_mods_changed(_owned: Array[StringName]) -> void:
	hud.set_owned_mods(upgrades.owned_names())

func _on_arena_bounds_changed(bounds: Rect2) -> void:
	jugaad_loop.arena = bounds

func _on_victory() -> void:
	hud.show_announcement("AREA DEFENDED\nVICTORY!\nPress R to play again", 0.0)
	hud.show_victory(wave_director.total_waves(), economy.scrap)
	_refresh_wave_hud()

func _refresh_wave_hud() -> void:
	var wave: int = wave_director.current_wave()
	hud.set_wave(maxi(1, wave), wave_director.total_waves())
	var seconds: int = ceili(wave_director.time_left)
	var clock: String = "%02d:%02d" % [floori(seconds / 60.0), seconds % 60]
	var text: String = ""
	match wave_director.state:
		WaveDirector.State.PREPARATION:
			text = ("WAVE %d CLEARED
" % (wave - 1) if wave > 1 else "PREPARE DEFENCES
")
			text += "KABADIWALA OPEN
" if kabadiwala.available else ""
			text += "NEXT WAVE: " + clock
		WaveDirector.State.COUNTDOWN:
			text = "WAVE %d INCOMING: %d" % [wave, ceili(wave_director.time_left)]
		WaveDirector.State.COMBAT:
			text = "ENEMIES REMAINING: %d" % wave_director.enemies_remaining()
		WaveDirector.State.WAVE_CLEAR:
			text = "WAVE %d CLEARED" % wave
		WaveDirector.State.VICTORY:
			text = "ALL %d WAVES CLEARED" % wave_director.total_waves()
	var events: String = event_director.status_text()
	if not events.is_empty() and not text.is_empty():
		text += "\n" + events
	hud.set_wave_status(text)

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
		elif event.physical_keycode == KEY_F7:
			wave_director.debug_skip_phase()
		elif event.physical_keycode == KEY_F8:
			var forced: String = event_director.debug_force_next()
			_on_feedback("DEBUG EVENT: " + forced if not forced.is_empty() else "DEBUG: no event eligible right now.")
		elif event.physical_keycode == KEY_F11:
			economy.debug_grant(20)
			_on_feedback("DEBUG: +20 Scrap")
		elif event.physical_keycode == KEY_F12:
			var granted: StringName = upgrades.debug_grant()
			_on_feedback("DEBUG MOD: " + UpgradeTable.MODS[granted].name if granted != &"" else "DEBUG: all mods owned.")
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
	wave_director.stop()
	player.active = false
	player.velocity = Vector2.ZERO
	spawner.active = false
	jugaad_loop.stop()
	for child in enemies.get_children():
		var enemy: Gunda = child as Gunda
		if enemy != null:
			enemy.active = false
			enemy.velocity = Vector2.ZERO
	defeat_label.hide()
	hud.show_announcement("", 0.0)
	hud.show_defeat(wave_director.current_wave(), economy.scrap)
	_refresh_wave_hud()
	_update_prompt()
	defeated.emit()
