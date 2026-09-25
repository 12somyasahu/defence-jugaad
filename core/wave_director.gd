class_name WaveDirector
extends Node

# Orchestrates the M5 loop. Owns wave state and wave-owned enemies only:
# Scrap stays in ScrapEconomy, offers stay in Kabadiwala, bounds stay in PrototypeArena.
enum State { IDLE, PREPARATION, COUNTDOWN, COMBAT, WAVE_CLEAR, VICTORY, DEFEAT }

signal state_changed(state: State, wave: int)
# Remaining enemies or the whole-second timer changed; views re-read public state.
signal status_changed
signal announcement(text: String, seconds: float)
signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal victory

const ENEMY_SCENES: Dictionary = {
	"gunda": preload("res://enemies/gunda.tscn"),
	"chotu": preload("res://enemies/chotu.tscn"),
	"pehelwan": preload("res://enemies/pehelwan.tscn"),
}
const WAVE_ENEMY_GROUP: StringName = &"wave_enemy"
# Extra enemies added by EventDirector (e.g. GUNDA RUSH). The wave waits for them too.
const EVENT_ENEMY_GROUP: StringName = &"event_enemy"

@export_range(1.0, 120.0) var first_preparation_seconds: float = 20.0
@export_range(1.0, 120.0) var preparation_seconds: float = 25.0
@export_range(1, 10) var countdown_seconds: int = 5
@export_range(0.5, 10.0) var wave_clear_seconds: float = 3.0
@export_range(0.1, 10.0) var first_spawn_delay: float = 1.0
var waves: Array[Dictionary] = WaveTable.WAVES
var state: State = State.IDLE
# 0-based index of the current (COMBAT) or upcoming (PREPARATION/COUNTDOWN) wave.
var wave_index: int = -1
var time_left: float = 0.0
var scheduled: int = 0
var spawned: int = 0
var debug_spawning_paused: bool = false
var routes: Array[AttackRoute] = []
var workshop: Workshop
var enemies: Node2D
var kabadiwala: Node
var arena: PrototypeArena
var event_spawned: int = 0
var _queue: Array[PackedScene] = []
# Every enemy the current wave waits for (WAVE and EVENT owned), keyed by instance id.
var _alive: Dictionary = {}
var _event_pending: int = 0
var _spawn_remaining: float = 0.0
var _route_cursor: int = 0
var _shown_second: int = -1

func setup(workshop_node: Workshop, enemy_container: Node2D, shop: Node, arena_node: PrototypeArena, route_nodes: Array[AttackRoute]) -> void:
	workshop = workshop_node
	enemies = enemy_container
	kabadiwala = shop
	arena = arena_node
	routes = route_nodes
	arena.bounds_changed.connect(_on_bounds_changed)
	_on_bounds_changed(arena.bounds)

func start() -> void:
	if state != State.IDLE or waves.is_empty():
		return
	wave_index = 0
	_apply_wave_layout(false)
	_enter(State.PREPARATION, first_preparation_seconds)
	announcement.emit("PREPARE THE WORKSHOP\nGundas arrive from the %s" % _active_route_names(), 3.5)

func stop() -> void:
	# Defeat/shutdown: no more spawning or phase changes. Existing enemies are frozen by their owner.
	_queue.clear()
	_enter(State.DEFEAT, 0.0)

func total_waves() -> int:
	return waves.size()

func current_wave() -> int:
	return wave_index + 1

func enemies_remaining() -> int:
	return scheduled - spawned + _alive.size() + _event_pending

func alive_wave_enemies() -> int:
	return _alive.size()

# Routes scheduled/event spawns may use right now: active and not blocked by an event.
func usable_routes() -> Array[AttackRoute]:
	var usable: Array[AttackRoute] = []
	for route in _active_routes():
		if not route.blocked:
			usable.append(route)
	return usable

# EventDirector announces extra spawns up front so the wave cannot clear between them.
func reserve_event_spawns(count: int) -> void:
	if state == State.COMBAT:
		_event_pending += maxi(0, count)
		status_changed.emit()

func cancel_event_spawns() -> void:
	_event_pending = 0
	status_changed.emit()
	_check_clear.call_deferred()

# Spawns one event-owned enemy for the current wave; consumes one reservation.
func spawn_event_enemy(scene: PackedScene, route: AttackRoute) -> Gunda:
	_event_pending = maxi(0, _event_pending - 1)
	if state != State.COMBAT or route == null:
		status_changed.emit()
		_check_clear.call_deferred()
		return null
	event_spawned += 1
	return _spawn_tracked(scene, route, EVENT_ENEMY_GROUP)

func debug_skip_phase() -> void:
	if state in [State.PREPARATION, State.COUNTDOWN, State.WAVE_CLEAR]:
		time_left = 0.0

func _process(delta: float) -> void:
	match state:
		State.PREPARATION, State.COUNTDOWN, State.WAVE_CLEAR:
			time_left = maxf(0.0, time_left - delta)
			var second: int = ceili(time_left)
			if second != _shown_second:
				_shown_second = second
				if state == State.COUNTDOWN and second > 0:
					announcement.emit("WAVE %d INCOMING\n%d" % [current_wave(), second], 1.0)
				status_changed.emit()
			if time_left <= 0.0:
				_advance()
		State.COMBAT:
			if debug_spawning_paused or _queue.is_empty():
				return
			_spawn_remaining -= delta
			if _spawn_remaining <= 0.0:
				_spawn_remaining = float(waves[wave_index].get("spawn_interval", 2.0))
				_spawn_next()

func _advance() -> void:
	match state:
		State.PREPARATION:
			_enter(State.COUNTDOWN, float(countdown_seconds))
		State.COUNTDOWN:
			_begin_combat()
		State.WAVE_CLEAR:
			wave_index += 1
			_apply_wave_layout(true)
			if is_instance_valid(kabadiwala):
				# One fresh stock per legitimate shop phase; reopening never rerolls.
				kabadiwala.restock()
				kabadiwala.open_session()
			_enter(State.PREPARATION, preparation_seconds)

func _enter(next: State, seconds: float) -> void:
	state = next
	time_left = seconds
	_shown_second = -1
	state_changed.emit(state, current_wave())
	status_changed.emit()

func _begin_combat() -> void:
	if is_instance_valid(kabadiwala):
		kabadiwala.close_session()
	var wave: Dictionary = waves[wave_index]
	_queue.clear()
	for key in ENEMY_SCENES:
		for i in int(wave.get(key, 0)):
			_queue.append(ENEMY_SCENES[key])
	_queue.shuffle()
	scheduled = _queue.size()
	spawned = 0
	event_spawned = 0
	_event_pending = 0
	_alive.clear()
	_spawn_remaining = first_spawn_delay
	_enter(State.COMBAT, 0.0)
	wave_started.emit(current_wave())
	announcement.emit("WAVE %d\nAAYE GUNDE!" % current_wave(), 1.5)
	_check_clear()

func _spawn_next() -> void:
	# Blocked routes are skipped, so their share is redistributed rather than lost.
	var usable: Array[AttackRoute] = usable_routes()
	if usable.is_empty():
		usable = _active_routes()
	if usable.is_empty() or not is_instance_valid(enemies) or not is_instance_valid(workshop):
		return
	var route: AttackRoute = usable[_route_cursor % usable.size()]
	_route_cursor += 1
	_spawn_tracked(_queue.pop_front(), route, WAVE_ENEMY_GROUP)
	spawned += 1
	status_changed.emit()

func _spawn_tracked(scene: PackedScene, route: AttackRoute, group: StringName) -> Gunda:
	if not is_instance_valid(enemies) or not is_instance_valid(workshop):
		return null
	var enemy: Gunda = scene.instantiate()
	enemy.workshop = workshop
	enemy.add_to_group(group)
	var id: int = enemy.get_instance_id()
	_alive[id] = enemy
	# Any exit counts as gone (death or despawn); only ScrapEconomy decides payment, via `died`.
	enemy.tree_exiting.connect(_on_wave_enemy_exiting.bind(id), CONNECT_ONE_SHOT)
	enemies.add_child(enemy)
	enemy.global_position = route.next_spawn_position()
	status_changed.emit()
	return enemy

func _on_wave_enemy_exiting(id: int) -> void:
	if not _alive.erase(id):
		return
	status_changed.emit()
	# Deferred: the enemy is still in the tree, and scene teardown drops the call with us.
	_check_clear.call_deferred()

func _check_clear() -> void:
	if not is_inside_tree() or state != State.COMBAT or spawned < scheduled or _event_pending > 0 or not _alive.is_empty():
		return
	wave_cleared.emit(current_wave())
	if wave_index >= waves.size() - 1:
		_enter(State.VICTORY, 0.0)
		victory.emit()
	else:
		_enter(State.WAVE_CLEAR, wave_clear_seconds)
		announcement.emit("WAVE %d CLEARED!\nKABADIWALA IS COMING" % current_wave(), wave_clear_seconds)

func _apply_wave_layout(announce: bool) -> void:
	var wave: Dictionary = waves[wave_index]
	var expanded: bool = int(wave.get("arena_stage", 0)) > arena.stage
	arena.set_stage(int(wave.get("arena_stage", 0)), announce)
	var count: int = clampi(int(wave.get("routes", 1)), 1, routes.size())
	var opened: Array[String] = []
	for i in routes.size():
		if i < count and not routes[i].active:
			opened.append(routes[i].route_name)
		routes[i].set_active(i < count)
	if not announce:
		return
	var lines: Array[String] = []
	if expanded:
		lines.append("AREA EXPANDED!")
	if not opened.is_empty():
		lines.append("NAYA RAASTA KHUL GAYA!\nNEW ATTACK ROUTE: " + ", ".join(opened))
	if not lines.is_empty():
		announcement.emit("\n".join(lines), 4.0)

func _active_routes() -> Array[AttackRoute]:
	var active: Array[AttackRoute] = []
	for route in routes:
		if route.active:
			active.append(route)
	return active

func _active_route_names() -> String:
	var names: Array[String] = []
	for route in _active_routes():
		names.append(route.route_name)
	return ", ".join(names)

func _on_bounds_changed(bounds: Rect2) -> void:
	for route in routes:
		route.place_on(bounds)
