class_name JugaadWeapon
extends Node2D

signal fired
signal placed
signal instability_changed(current: float, maximum: float)
signal jammed_changed(value: bool)
signal repair_hit(progress: int, required: int)
signal repaired
signal picked_up

enum Kind { CHAKRI_GUN, DHAMAAL_BOX, PRESSURE_HORN }
const NAMES: Array[String] = ["Chakri Gun", "Dhamaal Box", "Pressure Horn"]
const SOURCE_PAIRS: Array = [[1, 5], [0, 3], [2, 3]]
const COMPONENT: PackedScene = preload("res://components/junk_component.tscn")
const PROJECTILE = preload("res://weapons/scrap_projectile.gd")
const INSTABILITY_PER_ATTACK: Array[float] = [2.0, 20.0, 12.5]

@export var kind: Kind = Kind.CHAKRI_GUN
@export_range(1.0, 1000.0) var maximum_instability: float = 100.0
@export_range(1, 10) var repair_hits_required: int = 3
var instability: float = 0.0
var jammed: bool = false
var repair_progress: int = 0
var active: bool = true
var is_placed: bool = false
var facing: Vector2 = Vector2.RIGHT
var enemies: Node2D
var projectiles: Node2D
var attack_range: float = 260.0
var attack_cooldown: float = 0.35
var _remaining: float = 0.0
var _flash: float = 0.0

func _ready() -> void:
	attack_range = [260.0, 140.0, 190.0][kind]
	attack_cooldown = [0.35, 1.2, 1.5][kind]
	$Name.text = NAMES[kind]
	for i in 2:
		var part: JunkComponent = COMPONENT.instantiate()
		part.component_type = SOURCE_PAIRS[kind][i]
		$Parts.add_child(part)
		part.set_held(true)
		part.position = Vector2(-12 if i == 0 else 12, 0)
		part.scale = Vector2.ONE * 0.65
	_update_maintenance()

func place_at(world_position: Vector2, direction: Vector2) -> void:
	global_position = world_position
	facing = direction.normalized()
	is_placed = true
	placed.emit()
	queue_redraw()

func pick_up() -> void:
	is_placed = false
	_flash = 0.0
	picked_up.emit()
	queue_redraw()

func repair() -> bool:
	if not active or not is_placed or not jammed:
		return false
	repair_progress += 1
	repair_hit.emit(repair_progress, repair_hits_required)
	if repair_progress >= repair_hits_required:
		instability = 0.0
		jammed = false
		repair_progress = 0
		_remaining = attack_cooldown
		instability_changed.emit(instability, maximum_instability)
		jammed_changed.emit(false)
		repaired.emit()
	_update_maintenance()
	return true

func _add_instability() -> void:
	instability = minf(maximum_instability, instability + INSTABILITY_PER_ATTACK[kind])
	instability_changed.emit(instability, maximum_instability)
	if instability >= maximum_instability:
		jammed = true
		_flash = 0.0
		jammed_changed.emit(true)
	_update_maintenance()

func _update_maintenance() -> void:
	var ratio: float = instability / maximum_instability
	var warning: String = "STABLE" if ratio < 0.5 else ("UNSTABLE" if ratio < 0.8 else "WARNING")
	$Maintenance.text = "KHATAK! JAMMED\nE: THAK %d/%d" % [repair_progress, repair_hits_required] if jammed else "%s %d%%" % [warning, roundi(ratio * 100)]
	$Maintenance.modulate = Color.TOMATO if jammed or ratio >= 0.8 else (Color.GOLD if ratio >= 0.5 else Color.LIGHT_GREEN)

func _physics_process(delta: float) -> void:
	_flash = maxf(0, _flash - delta)
	queue_redraw()
	if not active or jammed or not is_placed or not is_instance_valid(enemies):
		return
	_remaining = maxf(0, _remaining - delta)
	if _remaining > 0:
		return
	var targets: Array[Gunda] = []
	var nearest: Gunda
	var nearest_distance: float = INF
	for child in enemies.get_children():
		var enemy: Gunda = child as Gunda
		if enemy == null or not enemy.active or enemy.current_hp <= 0:
			continue
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length() > attack_range:
			continue
		if kind == Kind.PRESSURE_HORN and offset.normalized().dot(facing) < 0.7071:
			continue
		targets.append(enemy)
		if offset.length_squared() < nearest_distance:
			nearest = enemy
			nearest_distance = offset.length_squared()
	if targets.is_empty():
		return
	_remaining = attack_cooldown
	_flash = 0.22
	match kind:
		Kind.CHAKRI_GUN:
			facing = (nearest.global_position - global_position).normalized()
			if facing.is_zero_approx():
				facing = Vector2.RIGHT
			var scrap: ScrapProjectile = PROJECTILE.new()
			scrap.direction = facing
			scrap.remaining_distance = attack_range + 25.0
			projectiles.add_child(scrap)
			scrap.global_position = global_position
		Kind.DHAMAAL_BOX:
			for enemy in targets:
				enemy.receive_damage(12)
		Kind.PRESSURE_HORN:
			for enemy in targets:
				enemy.receive_damage(3)
				enemy.apply_knockback((enemy.global_position - global_position).normalized() * 300.0)
	fired.emit()
	_add_instability()

func _draw() -> void:
	draw_rect(Rect2(-25, -20, 50, 40), Color(0.2, 0.24, 0.28))
	draw_line(Vector2(-18, 12), Vector2(18, -12), Color.WHITE, 2)
	if kind != Kind.DHAMAAL_BOX:
		draw_line(Vector2.ZERO, facing * 38, Color.WHITE, 3)
	if _flash > 0 and is_placed:
		var radius: float = attack_range * (1.0 - _flash / 0.22)
		if kind == Kind.DHAMAAL_BOX:
			draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color.MEDIUM_PURPLE, 4)
		elif kind == Kind.PRESSURE_HORN:
			var angle: float = facing.angle()
			draw_arc(Vector2.ZERO, radius, angle - PI / 4, angle + PI / 4, 24, Color.CORAL, 5)
			draw_line(Vector2.ZERO, facing.rotated(-PI / 4) * radius, Color.CORAL, 2)
			draw_line(Vector2.ZERO, facing.rotated(PI / 4) * radius, Color.CORAL, 2)
