class_name JugaadWeapon
extends Node2D

signal fired
signal placed

enum Kind { CHAKRI_GUN, DHAMAAL_BOX, PRESSURE_HORN }
const NAMES: Array[String] = ["Chakri Gun", "Dhamaal Box", "Pressure Horn"]
const SOURCE_PAIRS: Array = [[1, 5], [0, 3], [2, 3]]
const COMPONENT: PackedScene = preload("res://components/junk_component.tscn")
const PROJECTILE = preload("res://weapons/scrap_projectile.gd")

@export var kind: Kind = Kind.CHAKRI_GUN
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

func place_at(world_position: Vector2, direction: Vector2) -> void:
	global_position = world_position
	facing = direction.normalized()
	is_placed = true
	_remaining = 0.0
	placed.emit()
	queue_redraw()

func _physics_process(delta: float) -> void:
	_flash = maxf(0, _flash - delta)
	queue_redraw()
	if not is_placed or not is_instance_valid(enemies):
		return
	_remaining = maxf(0, _remaining - delta)
	if _remaining > 0:
		return
	var targets: Array[Gunda] = []
	var nearest: Gunda
	var nearest_distance: float = INF
	for enemy: Gunda in enemies.get_children():
		if not enemy.active or enemy.current_hp <= 0:
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
