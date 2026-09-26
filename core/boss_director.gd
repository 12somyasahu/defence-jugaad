class_name BossDirector
extends Node

signal preparation_started(route: AttackRoute)
signal boss_started(boss: Thekedaar)
signal finale_started
signal finale_finished
signal reinforcement_announced(routes: Array[String])

const TEMPO: PackedScene = preload("res://enemies/thekedaar.tscn")
@export var preparation_seconds: float = 30.0
@export var escort_interval: float = 7.0
var boss: Thekedaar
var route: AttackRoute
var stage: StringName = &"idle"
var main: Node
var waves: WaveDirector
var hud: HUD
var audio: GameAudio
var _reinforcements: Array[Dictionary] = []
var _reinforcement_left: float = 0.0
var _escort_left: float = 5.0
var _escorts_spawned: int = 0
var _warning_left: float = 0.0
var _finale_left: float = 0.0
var _finale_step: int = 0

func setup(root_node: Node) -> void:
	main = root_node
	waves = main.get_node("WaveDirector")
	hud = main.get_node("HUD")
	audio = main.get_node("AudioManager")
	waves.normal_waves_completed.connect(begin_preparation)
	waves.boss_combat_started.connect(_start_combat)
	main.get_node("Workshop").destroyed.connect(cancel)

func begin_preparation() -> void:
	if stage != &"idle" or main.get_node("Workshop").current_hp <= 0:
		return
	# Wave 5 clear already ends route-blocking events before this selection.
	var usable: Array[AttackRoute] = waves.usable_routes()
	if usable.is_empty():
		return
	route = usable.pick_random()
	stage = &"preparation"
	waves.begin_boss_preparation(preparation_seconds)
	hud.show_announcement("THEKEDAAR AA RAHA HAI!", 2.5)
	audio.boss_warning()
	_warning_left = 2.5
	preparation_started.emit(route)
	main._refresh_wave_hud()

func _start_combat() -> void:
	if stage != &"preparation":
		return
	stage = &"combat"
	_warning_left = 0
	main.get_node("EventDirector")._end_combat_events()
	main.get_node("EventDirector")._scheduled_at = -1.0
	boss = TEMPO.instantiate()
	main.add_child(boss)
	boss.global_position = route.global_position - route.direction * 75.0
	boss.setup(main.get_node("Workshop"), main.get_node("Player"), main.get_node("JugaadLoop"), main.get_node("Enemies"), -route.direction)
	boss.defeated.connect(_on_defeated)
	boss.chassis_health_changed.connect(func(_hp: int, _max: int) -> void: _update_hud())
	boss.part_destroyed.connect(_on_part_destroyed)
	boss.hafta.connect(_queue_hafta)
	boss.attack_cued.connect(_on_attack_cued)
	boss.attack_fired.connect(_on_attack_fired)
	boss.movement_changed.connect(func(moving: bool) -> void:
		audio.set_engine_running(moving and boss.alive(&"engine"))
		if not moving:
			audio.play_sfx("boss/stop")
	)
	hud.show_announcement("FINAL: THEKEDAAR!\nFROM %s!" % route.route_name, 3.0)
	audio.play_sfx("boss/arrival", true)
	audio.play_dialogue("thekedaar_arrival", 3.0, true)
	audio.set_engine_running(true)
	_update_hud()
	boss_started.emit(boss)

func _process(delta: float) -> void:
	if stage == &"preparation" and _warning_left > 0:
		_warning_left = maxf(0.0, _warning_left - delta)
		if _warning_left == 0:
			hud.show_announcement("FROM %s!" % route.route_name, 3.0)
	elif stage == &"combat":
		_escort_left -= delta
		if _escort_left <= 0 and _escorts_spawned < 10:
			_escort_left = escort_interval
			var routes: Array[AttackRoute] = _other_routes()
			var escort_route: AttackRoute = routes[_escorts_spawned % routes.size()]
			# Six Gunda and four Chotu over the fight; never Pehelwan.
			var kind: String = "gunda" if _escorts_spawned in [0, 2, 3, 5, 7, 8] else "chotu"
			waves.reserve_event_spawns(1)
			waves.spawn_event_enemy(WaveDirector.ENEMY_SCENES[kind], escort_route)
			_escorts_spawned += 1
		_reinforcement_left -= delta
		if _reinforcement_left <= 0 and not _reinforcements.is_empty():
			_reinforcement_left = 0.35
			var entry: Dictionary = _reinforcements.pop_front()
			waves.spawn_event_enemy(WaveDirector.ENEMY_SCENES[entry.kind], entry.route)
	elif stage == &"finale":
		_finale_left -= delta
		if _finale_left <= 0:
			_advance_finale()

func _other_routes() -> Array[AttackRoute]:
	var result: Array[AttackRoute] = []
	for candidate in waves.usable_routes():
		if candidate != route:
			result.append(candidate)
	if result.is_empty():
		result.append(route)
	return result

func _queue_hafta(_threshold: int) -> void:
	if stage != &"combat":
		return
	var routes: Array[AttackRoute] = _other_routes()
	var names: Array[String] = []
	for i in mini(2, routes.size()):
		names.append(routes[i].route_name)
		for kind in ["gunda", "gunda", "gunda", "chotu"]:
			_reinforcements.append({"kind": kind, "route": routes[i]})
	waves.reserve_event_spawns(mini(2, routes.size()) * 4)
	# Give the announced routes two seconds before the first arrival.
	_reinforcement_left = 2.0
	hud.show_announcement("HAFTA VASOOLI!\nFROM " + " + ".join(names), 2.0)
	audio.play_sfx("boss/hafta_horn", true)
	audio.play_dialogue("thekedaar_hafta", 2.0, true)
	reinforcement_announced.emit(names)

func _on_attack_cued(id: StringName) -> void:
	if id == &"speaker":
		audio.play_sfx("boss/speaker_charge", true)
		audio.play_dialogue("thekedaar_speaker")
	elif id == &"battery":
		audio.play_sfx("boss/battery_charge", true)
		audio.play_dialogue("thekedaar_bijli")

func _on_attack_fired(id: StringName) -> void:
	if id == &"speaker":
		audio.play_sfx("boss/speaker_blast", true)
	elif id == &"battery":
		audio.play_sfx("boss/battery_zap", true)
	# Workshop impact already drives workshop_hit and world flash/shake.

func _on_part_destroyed(id: StringName) -> void:
	audio.play_sfx("boss/module_destroyed", true)
	audio.play_dialogue(String(id) + "_destroyed", 2.0, true)
	if id == &"engine":
		audio.set_engine_running(false)
	_update_hud()

func _update_hud() -> void:
	if is_instance_valid(boss):
		hud.update_boss(boss.parts[&"chassis"].current_hp, 1500, boss.alive(&"speaker"), boss.alive(&"battery"), boss.alive(&"engine"))

func _on_defeated() -> void:
	if stage != &"combat":
		return
	stage = &"finale"
	_reinforcements.clear()
	waves.finish_boss_combat()
	main.get_node("EventDirector").running = false
	main.get_node("EastSpawn").active = false
	main.get_node("RunStats").active = false
	main.get_node("ScrapEconomy").active = false
	main.get_node("JugaadLoop").stop()
	main.get_node("Player").active = false
	main.get_node("Kabadiwala").stop()
	# Despawn rather than receive_damage: fleeing gang earns no Scrap or kills.
	for child in main.get_node("Enemies").get_children():
		var enemy: Gunda = child as Gunda
		if enemy != null:
			enemy.active = false
			if not enemy is BossPart:
				enemy.queue_free()
	hud.hide_boss()
	audio.set_engine_running(false)
	audio.cancel_dialogue()
	audio.dialogue_locked = true
	audio.play_sfx("boss/chassis_destroyed", true)
	hud.show_announcement("THEKEDAAR HAAR GAYA!", 2.5)
	audio.play_dialogue("thekedaar_defeated", 2.5, true)
	_finale_step = 0
	_finale_left = 3.0
	finale_started.emit()

func _advance_finale() -> void:
	var lines: Array[String] = ["ending_engineering", "ending_nahi", "ending_jugaad_hai"]
	var durations: Array[float] = [3.0, 1.5, 2.5]
	if _finale_step < lines.size():
		audio.play_dialogue(lines[_finale_step], durations[_finale_step], true)
		_finale_left = durations[_finale_step] + 0.5
		_finale_step += 1
	else:
		stage = &"complete"
		audio.cancel_dialogue()
		hud.show_announcement("", 0)
		waves.victory.emit()
		finale_finished.emit()

func cancel() -> void:
	stage = &"cancelled"
	_reinforcements.clear()
	_warning_left = 0
	_finale_left = 0
	if is_instance_valid(boss):
		boss.stop()
	waves.cancel_event_spawns()
	audio.set_engine_running(false)
	audio.cancel_dialogue()
	hud.hide_boss()

func debug_jump_to_preparation() -> void:
	if not OS.is_debug_build() or stage != &"idle" or main.get_node("Workshop").current_hp <= 0:
		return
	waves._queue.clear()
	main.get_node("EventDirector")._end_combat_events()
	waves._enter(WaveDirector.State.WAVE_CLEAR, 0)
	for child in main.get_node("Enemies").get_children():
		child.queue_free()
	waves.wave_index = 4
	waves._apply_wave_layout(true)
	begin_preparation()

func debug_damage_part(id: StringName, amount: int = 100) -> void:
	if OS.is_debug_build() and is_instance_valid(boss) and boss.parts.has(id):
		boss.parts[id].receive_damage(amount)
