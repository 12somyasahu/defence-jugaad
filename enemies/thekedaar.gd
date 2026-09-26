class_name Thekedaar
extends Node2D

signal part_destroyed(part_id: StringName)
signal chassis_health_changed(current: int, maximum: int)
signal defeated
signal attack_cued(id: StringName)
signal attack_fired(id: StringName)
signal movement_changed(moving: bool)
signal hafta(threshold: int)

const PART_HP: Dictionary = {&"speaker": 300, &"battery": 300, &"engine": 400, &"chassis": 1500}
const PART_OFFSETS: Dictionary = {&"speaker": Vector2(0, -48), &"battery": Vector2(0, 48), &"engine": Vector2(48, 0), &"chassis": Vector2(-18, 0)}
@export var movement_speed: float = 35.0
@export var segment_distance: float = 150.0
@export var stop_seconds: float = 4.0
@export var speaker_interval: float = 12.0
@export var speaker_radius: float = 220.0
@export var battery_interval: float = 15.0
@export var battery_range: float = 300.0
@export var telegraph_seconds: float = 2.0
@export var outage_seconds: float = 6.0
var parts: Dictionary = {}
var active: bool = true
var moving: bool = true
var facing: Vector2 = Vector2.LEFT
var workshop: Workshop
var player: JugaadPlayer
var loop: JugaadLoop
var enemies: Node2D
var _segment_left: float = 150.0
var _stop_left: float = 0.0
var _speaker_left: float = 12.0
var _battery_left: float = 15.0
var speaker_charge: float = 0.0
var battery_charge: float = 0.0
var _speaker_flash: float = 0.0
var battery_targets: Array[JugaadWeapon] = []
var outages: Dictionary = {}
var _ram_left: float = 1.5
var _ram_warning: bool = false
var _hafta_done: Array[int] = []

func setup(home: Workshop, engineer: JugaadPlayer, gameplay: JugaadLoop, targets: Node2D, direction: Vector2) -> void:
	workshop = home
	player = engineer
	loop = gameplay
	enemies = targets
	facing = direction
	for id in PART_HP:
		var part: BossPart = BossPart.new()
		part.part_id = id
		part.name = "Boss_" + String(id)
		part.maximum_hp = PART_HP[id]
		part.workshop = workshop
		part.destroyed.connect(_on_part_destroyed)
		if id == &"chassis":
			part.health_changed.connect(_on_chassis_health)
		enemies.add_child(part)
		parts[id] = part
	_sync_parts()

func speed() -> float:
	return movement_speed * (1.0 if alive(&"engine") else 0.5)

func alive(id: StringName) -> bool:
	return parts.has(id) and is_instance_valid(parts[id]) and parts[id].current_hp > 0

func _sync_parts() -> void:
	for id in parts:
		if is_instance_valid(parts[id]):
			parts[id].global_position = global_position + Vector2(PART_OFFSETS[id]).rotated(facing.angle() - PI)

func _physics_process(delta: float) -> void:
	if not active:
		return
	_speaker_flash = maxf(0.0, _speaker_flash - delta)
	_tick_outages(delta)
	_speaker_left = maxf(0.0, _speaker_left - delta)
	_battery_left = maxf(0.0, _battery_left - delta)
	if speaker_charge > 0:
		speaker_charge = maxf(0.0, speaker_charge - delta)
		if speaker_charge == 0:
			_speaker_blast()
	if battery_charge > 0:
		battery_charge = maxf(0.0, battery_charge - delta)
		if battery_charge == 0:
			_battery_blast()
	if not active:
		return
	if alive(&"battery") and _battery_left <= 0:
		start_battery()
	var offset: Vector2 = workshop.global_position - global_position
	if offset.length() <= 105.0:
		_set_moving(false)
		_ram_left -= delta
		if _ram_left <= 0.5 and not _ram_warning:
			_ram_warning = true
			attack_cued.emit(&"workshop")
		if _ram_left <= 0:
			_ram_left = 1.5
			_ram_warning = false
			workshop.receive_damage(25)
			if active:
				attack_fired.emit(&"workshop")
	elif moving:
		var travel: float = minf(speed() * delta, minf(_segment_left, offset.length() - 105.0))
		global_position += offset.normalized() * travel
		_segment_left -= travel
		if _segment_left <= 0.01:
			_set_moving(false)
			_stop_left = stop_seconds * (0.75 if 33 in _hafta_done else 1.0)
	else:
		_stop_left -= delta
		if _stop_left <= 0 and speaker_charge <= 0:
			_segment_left = segment_distance
			_set_moving(true)
	if not moving and alive(&"speaker") and _speaker_left <= 0:
		start_speaker()
	_sync_parts()
	queue_redraw()

func _set_moving(value: bool) -> void:
	if moving != value:
		moving = value
		movement_changed.emit(value)

func start_speaker() -> bool:
	if not active or moving or not alive(&"speaker") or speaker_charge > 0:
		return false
	speaker_charge = telegraph_seconds
	_speaker_left = speaker_interval
	attack_cued.emit(&"speaker")
	queue_redraw()
	return true

func _speaker_blast() -> void:
	if not active or not alive(&"speaker"):
		return
	_speaker_flash = 0.35
	for child in loop.weapons.get_children():
		var weapon: JugaadWeapon = child as JugaadWeapon
		if weapon != null and weapon.is_placed and weapon.global_position.distance_to(global_position) <= speaker_radius:
			weapon.add_instability(40.0)
	if player.global_position.distance_to(global_position) <= speaker_radius:
		var away: Vector2 = (player.global_position - global_position).normalized()
		player.receive_disruption((away if not away.is_zero_approx() else facing) * 420.0)
	attack_fired.emit(&"speaker")

func _eligible(weapon: JugaadWeapon) -> bool:
	return is_instance_valid(weapon) and weapon.active and weapon.is_placed and JunkComponent.Type.BATTERY in JugaadWeapon.SOURCE_PAIRS[weapon.kind] and weapon.global_position.distance_to(global_position) <= battery_range

func start_battery() -> bool:
	if not active or not alive(&"battery") or battery_charge > 0:
		return false
	_battery_left = battery_interval
	battery_targets.clear()
	for child in loop.weapons.get_children():
		var weapon: JugaadWeapon = child as JugaadWeapon
		if weapon != null and _eligible(weapon) and not weapon.power_cut:
			battery_targets.append(weapon)
	battery_targets.sort_custom(func(a: JugaadWeapon, b: JugaadWeapon) -> bool: return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position))
	if battery_targets.size() > 2:
		battery_targets.resize(2)
	if battery_targets.is_empty():
		return false
	battery_charge = telegraph_seconds
	attack_cued.emit(&"battery")
	queue_redraw()
	return true

func _battery_blast() -> void:
	if not active or not alive(&"battery"):
		return
	for weapon in battery_targets:
		if is_instance_valid(weapon) and _eligible(weapon):
			weapon.set_power_cut(true)
			outages[weapon] = outage_seconds
	battery_targets.clear()
	attack_fired.emit(&"battery")

func _tick_outages(delta: float) -> void:
	for weapon in outages.keys():
		outages[weapon] -= delta
		if not is_instance_valid(weapon) or outages[weapon] <= 0:
			if is_instance_valid(weapon):
				weapon.set_power_cut(false)
			outages.erase(weapon)

func _on_part_destroyed(id: StringName) -> void:
	if id == &"chassis":
		stop()
		defeated.emit()
		return
	if id == &"speaker":
		speaker_charge = 0.0
	if id == &"battery":
		battery_charge = 0.0
		battery_targets.clear()
		_tick_outages(INF)
	part_destroyed.emit(id)
	queue_redraw()

func _on_chassis_health(current: int, maximum: int) -> void:
	chassis_health_changed.emit(current, maximum)
	if current <= 0:
		return
	for threshold in [66, 33]:
		if current * 100 <= maximum * threshold and not threshold in _hafta_done:
			_hafta_done.append(threshold)
			hafta.emit(threshold)

func stop() -> void:
	active = false
	speaker_charge = 0.0
	battery_charge = 0.0
	battery_targets.clear()
	_tick_outages(INF)
	for part in parts.values():
		if is_instance_valid(part):
			part.active = false
	queue_redraw()

func _exit_tree() -> void:
	for part in parts.values():
		if is_instance_valid(part) and not part.is_queued_for_deletion():
			part.queue_free()

func _draw() -> void:
	if not has_node("Presentation"):
		draw_rect(Rect2(-65, -67, 130, 134), Color(0.28, 0.2, 0.12))
		draw_rect(Rect2(-65, -67, 130, 134), Color.GOLD, false, 4)
		for y in [-58, 58]:
			for x in [-48, 48]:
				draw_circle(Vector2(x, y), 14, Color.DARK_SLATE_GRAY)
	if speaker_charge > 0:
		draw_arc(Vector2.ZERO, speaker_radius, 0, TAU, 64, Color(1, 0.3, 0.2, 0.5), 2)
		draw_arc(Vector2.ZERO, speaker_radius * (1.0 - speaker_charge / telegraph_seconds), 0, TAU, 64, Color.ORANGE_RED, 5)
	if _speaker_flash > 0:
		draw_arc(Vector2.ZERO, speaker_radius, 0, TAU, 64, Color(1, 0.9, 0.5, _speaker_flash / 0.35), 8)
	if battery_charge > 0:
		for weapon in battery_targets:
			if is_instance_valid(weapon):
				draw_line(Vector2.ZERO, to_local(weapon.global_position), Color.YELLOW, 3)
	if _ram_warning and active:
		draw_line(Vector2.ZERO, facing * 105.0, Color.RED, 8)
