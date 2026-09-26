class_name EventDirector
extends Node

# M6 "Desi Chaos". Decides when events happen and coordinates existing systems through
# their public APIs. Owns only temporary event state; Scrap, waves, enemy health, Jugaad
# maintenance and shop stock stay with their owners.
#
# Adding an event: add its id to COMBAT_EVENTS or PREPARATION_EVENTS plus TITLES, then
# implement _can_<id>() -> bool, _start_<id>() and (for timed events) _end_<id>().

signal event_started(event_id: StringName, title: String, detail: String)
signal event_ended(event_id: StringName)
# Active event set or its whole-second timer changed; views re-read status_text().
signal status_changed
signal announcement(text: String, seconds: float)

const COMBAT_EVENTS: Array[StringName] = [&"bijli", &"rush", &"breakdown", &"rasta_band"]
const PREPARATION_EVENTS: Array[StringName] = [&"sale"]
const DEBUG_ORDER: Array[StringName] = [&"bijli", &"sale", &"rush", &"breakdown", &"rasta_band"]
const TITLES: Dictionary = {
	&"bijli": "BIJLI CHALI GAYI!",
	&"sale": "KABADIWALA SALE!",
	&"rush": "GUNDA RUSH!",
	&"breakdown": "JUGAAD BREAKDOWN!",
	&"rasta_band": "RASTA BAND!",
}
const GUNDA: PackedScene = preload("res://enemies/gunda.tscn")
# GAME_SPEC "LIGHT GAYI": electrical Jugaads stop, mechanical ones keep working.
const POWERED_COMPONENTS: Array[int] = [JunkComponent.Type.BATTERY, JunkComponent.Type.SPEAKER, JunkComponent.Type.TABLE_FAN]

## 0 = random each run; any other value makes rolls reproducible.
@export var random_seed: int = 0
@export_range(1, 20) var first_event_wave: int = 2
@export_range(0.0, 1.0) var combat_event_chance: float = 0.55
@export var combat_event_window: Vector2 = Vector2(8.0, 18.0)
@export_range(0.0, 1.0) var sale_chance: float = 0.25
@export_range(1, 100) var sale_price: int = 2
@export_range(1.0, 60.0) var bijli_seconds: float = 10.0
@export_range(1, 10) var bijli_max_targets: int = 2
@export_range(1, 20) var rush_count: int = 3
@export_range(0.1, 2.0) var rush_spacing: float = 0.4
@export_range(1.0, 60.0) var rasta_band_seconds: float = 12.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var wave_director: WaveDirector
var kabadiwala: Node
var jugaad_loop: JugaadLoop
var running: bool = true
# Started events in order, for tests/debugging.
var history: Array[StringName] = []
# Timed/phase-bound events currently active: id -> seconds left (INF = until phase ends).
var _timers: Dictionary = {}
var _scheduled_at: float = -1.0
var _combat_elapsed: float = 0.0
var _bijli_targets: Array[JugaadWeapon] = []
var _blocked_route: AttackRoute
var _rush_route: AttackRoute
var _rush_left: int = 0
var _rush_remaining: float = 0.0
var _debug_index: int = 0
var _last_status: String = ""

func setup(waves: WaveDirector, shop: Node, loop: JugaadLoop) -> void:
	wave_director = waves
	kabadiwala = shop
	jugaad_loop = loop
	if random_seed != 0:
		rng.seed = random_seed
	else:
		rng.randomize()
	wave_director.state_changed.connect(_on_wave_state_changed)
	wave_director.wave_started.connect(_on_wave_started)

func set_seed(value: int) -> void:
	rng.seed = value

func is_active(event_id: StringName) -> bool:
	return _timers.has(event_id) or (event_id == &"rush" and _rush_left > 0)

func can_start(event_id: StringName) -> bool:
	return running and TITLES.has(event_id) and not is_active(event_id) and call("_can_%s" % event_id)

## Starts an event now if it is eligible. Used by the scheduler, F8 and tests.
func force_event(event_id: StringName) -> bool:
	if not can_start(event_id):
		return false
	call("_start_%s" % event_id)
	history.append(event_id)
	_emit_status()
	return true

## DEBUG: start the next eligible event in DEBUG_ORDER; returns its title or "".
func debug_force_next() -> String:
	for i in DEBUG_ORDER.size():
		var index: int = (_debug_index + i) % DEBUG_ORDER.size()
		if force_event(DEBUG_ORDER[index]):
			_debug_index = (index + 1) % DEBUG_ORDER.size()
			return TITLES[DEBUG_ORDER[index]]
	return ""

func status_text() -> String:
	var lines: Array[String] = []
	for id in _timers:
		var title: String = String(TITLES[id]).trim_suffix("!")
		if id == &"rasta_band" and is_instance_valid(_blocked_route):
			title += " (%s)" % _blocked_route.route_name
		if id == &"sale":
			lines.append("SALE: COMPONENTS %d SCRAP" % kabadiwala.current_price())
		else:
			lines.append("EVENT: %s - %02ds" % [title, ceili(_timers[id])])
	if _rush_left > 0 and is_instance_valid(_rush_route):
		lines.append("EVENT: GUNDA RUSH (%s)" % _rush_route.route_name)
	return "\n".join(lines)

func _process(delta: float) -> void:
	if not running:
		return
	if wave_director.state == WaveDirector.State.COMBAT:
		_combat_elapsed += delta
		if not wave_director.boss_combat and _scheduled_at >= 0.0 and _combat_elapsed >= _scheduled_at:
			_scheduled_at = -1.0
			_start_random(COMBAT_EVENTS)
		if _rush_left > 0:
			_rush_remaining -= delta
			if _rush_remaining <= 0.0:
				_rush_remaining = rush_spacing
				_spawn_rush_enemy()
	for id in _timers.keys():
		_timers[id] -= delta
		if _timers[id] <= 0.0:
			_end(id)
	if status_text() != _last_status:
		_emit_status()

func _on_wave_started(wave: int) -> void:
	_combat_elapsed = 0.0
	_scheduled_at = -1.0
	# At most one normal combat event per wave, never in the first wave(s).
	if running and not wave_director.boss_combat and wave >= first_event_wave and rng.randf() < combat_event_chance:
		_scheduled_at = rng.randf_range(combat_event_window.x, combat_event_window.y)

func _on_wave_state_changed(state: WaveDirector.State, wave: int) -> void:
	if state != WaveDirector.State.COMBAT:
		# Waves can end before the scheduled time; combat-only effects never outlive combat.
		_scheduled_at = -1.0
		_end_combat_events()
	if state in [WaveDirector.State.COMBAT, WaveDirector.State.VICTORY, WaveDirector.State.DEFEAT]:
		# The shop closes at combat start, which is where the sale's preparation ends.
		if _timers.has(&"sale"):
			_end(&"sale")
	if state in [WaveDirector.State.VICTORY, WaveDirector.State.DEFEAT]:
		running = false
		_emit_status()
	elif state == WaveDirector.State.PREPARATION and wave > 1 and running and rng.randf() < sale_chance:
		_start_random(PREPARATION_EVENTS)

func _start_random(pool: Array[StringName]) -> void:
	var eligible: Array[StringName] = []
	for id in pool:
		if can_start(id):
			eligible.append(id)
	if not eligible.is_empty():
		force_event(eligible[rng.randi_range(0, eligible.size() - 1)])

func _end(event_id: StringName) -> void:
	if not _timers.erase(event_id):
		return
	if has_method("_end_%s" % event_id):
		call("_end_%s" % event_id)
	event_ended.emit(event_id)
	_emit_status()

func _end_combat_events() -> void:
	for id in _timers.keys():
		if id in COMBAT_EVENTS:
			_end(id)
	if _rush_left > 0:
		_rush_left = 0
		wave_director.cancel_event_spawns()
		event_ended.emit(&"rush")
		_emit_status()

func _announce(event_id: StringName, detail: String, seconds: float = 3.0) -> void:
	event_started.emit(event_id, TITLES[event_id], detail)
	announcement.emit("%s\n%s" % [TITLES[event_id], detail], seconds)

func _emit_status() -> void:
	_last_status = status_text()
	status_changed.emit()

func _in_combat() -> bool:
	return wave_director.state == WaveDirector.State.COMBAT

func _placed_weapons() -> Array[JugaadWeapon]:
	var placed: Array[JugaadWeapon] = []
	for child in jugaad_loop.weapons.get_children():
		var weapon: JugaadWeapon = child as JugaadWeapon
		if weapon != null and is_instance_valid(weapon) and weapon.active and weapon.is_placed:
			placed.append(weapon)
	return placed

func _pick(items: Array) -> Variant:
	return items[rng.randi_range(0, items.size() - 1)]

func _shuffled(items: Array) -> Array:
	# Seeded Fisher-Yates so forced/seeded runs stay reproducible.
	var copy: Array = items.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: Variant = copy[i]
		copy[i] = copy[j]
		copy[j] = swap
	return copy

# --- BIJLI CHALI GAYI: powered Jugaads go offline; jam state is untouched. ---

func _bijli_candidates() -> Array[JugaadWeapon]:
	var candidates: Array[JugaadWeapon] = []
	for weapon in _placed_weapons():
		var pair: Array = JugaadWeapon.SOURCE_PAIRS[weapon.kind]
		if not weapon.power_cut and (int(pair[0]) in POWERED_COMPONENTS or int(pair[1]) in POWERED_COMPONENTS):
			candidates.append(weapon)
	return candidates

func _can_bijli() -> bool:
	return _in_combat() and not _bijli_candidates().is_empty()

func _start_bijli() -> void:
	# Prefer Jugaads that are currently firing so the outage actually matters.
	var working: Array = []
	var jammed: Array = []
	for weapon in _bijli_candidates():
		if weapon.jammed:
			jammed.append(weapon)
		else:
			working.append(weapon)
	var ordered: Array = _shuffled(working) + _shuffled(jammed)
	_bijli_targets.clear()
	for weapon in ordered.slice(0, bijli_max_targets):
		weapon.set_power_cut(true)
		_bijli_targets.append(weapon)
	_timers[&"bijli"] = bijli_seconds
	var count: int = _bijli_targets.size()
	_announce(&"bijli", "%d Jugaad%s temporarily offline" % [count, "" if count == 1 else "s"])

func _end_bijli() -> void:
	for weapon in _bijli_targets:
		if is_instance_valid(weapon):
			weapon.set_power_cut(false)
	_bijli_targets.clear()
	if _in_combat():
		announcement.emit("LIGHT AA GAYI!", 1.5)

# --- KABADIWALA SALE: temporary price for this preparation only. ---

func _can_sale() -> bool:
	var phase: bool = wave_director.state in [WaveDirector.State.PREPARATION, WaveDirector.State.COUNTDOWN]
	return phase and is_instance_valid(kabadiwala) and kabadiwala.available

func _start_sale() -> void:
	kabadiwala.set_sale_price(sale_price)
	_timers[&"sale"] = INF
	event_started.emit(&"sale", TITLES[&"sale"], "COMPONENTS: %d SCRAP" % sale_price)
	# Let the wave-clear / expansion banner finish before announcing.
	var tween: Tween = create_tween()
	tween.tween_interval(4.2 if wave_director.time_left > 20.0 else 0.0)
	tween.tween_callback(_announce_sale)

func _announce_sale() -> void:
	if _timers.has(&"sale") and wave_director.state == WaveDirector.State.PREPARATION:
		announcement.emit("%s\nCOMPONENTS: %d SCRAP" % [TITLES[&"sale"], sale_price], 3.0)

func _end_sale() -> void:
	if is_instance_valid(kabadiwala):
		kabadiwala.clear_sale_price()

# --- GUNDA RUSH: extra event-owned Gundas from one route. ---

func _can_rush() -> bool:
	return _in_combat() and not wave_director.usable_routes().is_empty()

func _start_rush() -> void:
	_rush_route = _pick(wave_director.usable_routes())
	_rush_left = rush_count
	_rush_remaining = 0.0
	wave_director.reserve_event_spawns(rush_count)
	_announce(&"rush", "%s SE AA RAHE HAIN! / RUSH FROM %s" % [_rush_route.route_name, _rush_route.route_name])

func _spawn_rush_enemy() -> void:
	# A route blocked mid-rush (only possible via debug forcing) hands over to another.
	if not is_instance_valid(_rush_route) or _rush_route.blocked or not _rush_route.active:
		var usable: Array[AttackRoute] = wave_director.usable_routes()
		if not usable.is_empty():
			_rush_route = usable[0]
	wave_director.spawn_event_enemy(GUNDA, _rush_route)
	_rush_left -= 1
	if _rush_left == 0:
		event_ended.emit(&"rush")
		_emit_status()

# --- JUGAAD BREAKDOWN: one working Jugaad enters the normal jam state. ---

func _breakdown_candidates() -> Array[JugaadWeapon]:
	var candidates: Array[JugaadWeapon] = []
	for weapon in _placed_weapons():
		if not weapon.jammed and not weapon.power_cut:
			candidates.append(weapon)
	return candidates

func _can_breakdown() -> bool:
	return _in_combat() and not _breakdown_candidates().is_empty()

func _start_breakdown() -> void:
	var weapon: JugaadWeapon = _pick(_breakdown_candidates())
	weapon.force_jam()
	# Persistent until repaired through the existing E x3 repair; nothing to time out.
	_announce(&"breakdown", "%s JAMMED!" % JugaadWeapon.NAMES[weapon.kind].to_upper())

# --- RASTA BAND: one active route temporarily stops receiving spawns. ---

func _can_rasta_band() -> bool:
	return _in_combat() and wave_director.usable_routes().size() >= 2

func _start_rasta_band() -> void:
	_blocked_route = _pick(wave_director.usable_routes())
	_blocked_route.set_blocked(true)
	_timers[&"rasta_band"] = rasta_band_seconds
	_announce(&"rasta_band", "%s ROUTE BLOCKED" % _blocked_route.route_name)

func _end_rasta_band() -> void:
	if is_instance_valid(_blocked_route):
		_blocked_route.set_blocked(false)
		if _in_combat():
			announcement.emit("RASTA KHUL GAYA!\n%s ROUTE OPEN" % _blocked_route.route_name, 1.5)
	_blocked_route = null
