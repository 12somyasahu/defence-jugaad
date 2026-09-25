class_name JugaadWeapon
extends Node2D

signal fired
signal placed
signal instability_changed(current: float, maximum: float)
signal jammed_changed(value: bool)
signal repair_hit(progress: int, required: int)
signal repaired
signal picked_up
signal power_changed(powered: bool)
# THANDA THANDA aura coverage changed (presentation hook).
signal cooled_changed(value: bool)

enum Kind { CHAKRI_GUN, DHAMAAL_BOX, PRESSURE_HORN, BIJLI_CHAKRI, TURBO_PANKHA, JHATKA_SLING, PRESSURE_CHAKRA, COOKER_CANNON, AANDHI_DJ }
const NAMES: Array[String] = ["Chakri Gun", "Dhamaal Box", "Pressure Horn", "Bijli Chakri", "Turbo Pankha", "Jhatka Sling", "Pressure Chakra", "Cooker Cannon", "Aandhi DJ"]
const SOURCE_PAIRS: Array = [[1, 5], [0, 3], [2, 3], [0, 1], [0, 4], [0, 5], [1, 2], [2, 4], [3, 4]]
const COMPONENT: PackedScene = preload("res://components/junk_component.tscn")
const PROJECTILE = preload("res://weapons/scrap_projectile.gd")
const CANNON_SHELL = preload("res://weapons/cannon_shell.gd")
# Indexed by Kind; keep existing IDs/stats stable when adding content.
const RANGES: Array[float] = [260.0, 140.0, 190.0, 95.0, 170.0, 380.0, 85.0, 330.0, 150.0]
const COOLDOWNS: Array[float] = [0.35, 1.2, 1.5, 0.45, 0.65, 2.4, 0.2, 2.8, 0.3]
const DAMAGE: Array[int] = [10, 12, 3, 6, 4, 60, 5, 42, 2]
const INSTABILITY_PER_ATTACK: Array[float] = [2.0, 20.0, 12.5, 6.0, 7.0, 12.0, 5.0, 22.0, 5.0]
# Push strength for knockback Jugaads (0 = no knockback behaviour).
const KNOCKBACK: Array[float] = [0.0, 0.0, 300.0, 0.0, 120.0, 0.0, 0.0, 0.0, 70.0]
# Presentation only, indexed by Kind. Dhamaal Box has no production PNG yet; its SVG placeholder is kept.
const TEXTURES: Array[Texture2D] = [
	preload("res://assets/jugaads/chakri_gun.png"),
	preload("res://assets/weapons/dhamaal_box.svg"),
	preload("res://assets/jugaads/pressure_horn.png"),
	null, null, null, null, null, null, # Source-component fallback until production art arrives.
]
const SPRITE_SIZE: float = 60.0

@export var kind: Kind = Kind.CHAKRI_GUN
@export_range(1.0, 1000.0) var maximum_instability: float = 100.0
@export_range(1, 10) var repair_hits_required: int = 3
var instability: float = 0.0
var jammed: bool = false
var repair_progress: int = 0
var active: bool = true
var is_placed: bool = false
# Temporary event state (BIJLI CHALI GAYI). Separate from jam/instability; never repairs anything.
var power_cut: bool = false
var facing: Vector2 = Vector2.RIGHT
var enemies: Node2D
var projectiles: Node2D
# M7A mods. Null (or nothing owned) means exact base stats.
var upgrades: UpgradeSystem
# Presentation state: inside a THANDA THANDA aura right now.
var cooled: bool = false
var _base_repair_hits: int = 3
var attack_range: float = 260.0
var attack_cooldown: float = 0.35
var _remaining: float = 0.0
var _flash: float = 0.0

func _ready() -> void:
	_base_repair_hits = repair_hits_required
	if upgrades != null:
		upgrades.mods_changed.connect(_on_mods_changed)
	refresh_stats()
	$Name.text = NAMES[kind]
	var sprite: Sprite2D = $Sprite
	sprite.texture = TEXTURES[kind]
	if sprite.texture != null:
		sprite.scale = Vector2.ONE * SPRITE_SIZE / maxf(sprite.texture.get_width(), sprite.texture.get_height())
		# The sprite already shows the combined parts; mini components are the no-texture fallback.
		$Parts.hide()
	for i in 2:
		var part: JunkComponent = COMPONENT.instantiate()
		part.component_type = SOURCE_PAIRS[kind][i]
		$Parts.add_child(part)
		part.set_held(true)
		part.position = Vector2(-12 if i == 0 else 12, 0)
		part.scale = Vector2.ONE * 0.65
	_update_maintenance()

## Re-reads mod-dependent stats. Base values are never mutated.
func refresh_stats() -> void:
	attack_range = RANGES[kind] * _mult("range")
	if attack_range > RANGES[kind]:
		attack_range = minf(attack_range, maxf(RANGES[kind], UpgradeTable.MAX_MODIFIED_RANGE))
	attack_cooldown = COOLDOWNS[kind] * _mult("cooldown")
	repair_hits_required = upgrades.repair_hits(kind, _base_repair_hits) if upgrades != null else _base_repair_hits
	if is_node_ready():
		_update_maintenance()
		queue_redraw()

func damage_per_hit() -> int:
	return roundi(DAMAGE[kind] * _mult("damage"))

func instability_per_attack() -> float:
	var value: float = INSTABILITY_PER_ATTACK[kind]
	if upgrades != null:
		value *= upgrades.multiplier(kind, "instability", self)
	return value

func knockback_strength() -> float:
	return KNOCKBACK[kind] * _mult("knockback")

func blast_radius_multiplier() -> float:
	return _mult("blast_radius")

func _mult(stat: String) -> float:
	return upgrades.multiplier(kind, stat) if upgrades != null else 1.0

func _on_mods_changed(_owned: Array[StringName]) -> void:
	refresh_stats()

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

func set_power_cut(value: bool) -> void:
	if power_cut == value:
		return
	power_cut = value
	var tint: Color = Color(0.45, 0.45, 0.6) if power_cut else Color.WHITE
	# self_modulate covers the drawn fallback body; labels stay readable.
	self_modulate = tint
	$Sprite.modulate = tint
	$Parts.modulate = tint
	power_changed.emit(not power_cut)
	_update_maintenance()

# Event breakdown: enters the normal jam state, repaired with the normal E x3.
func force_jam() -> bool:
	if jammed or not active or not is_placed:
		return false
	instability = maximum_instability
	instability_changed.emit(instability, maximum_instability)
	_jam()
	_update_maintenance()
	return true

func _add_instability() -> void:
	instability = minf(maximum_instability, instability + instability_per_attack())
	instability_changed.emit(instability, maximum_instability)
	if instability >= maximum_instability:
		_jam()
	_update_maintenance()

func _jam() -> void:
	jammed = true
	_flash = 0.0
	jammed_changed.emit(true)

func _update_maintenance() -> void:
	var ratio: float = instability / maximum_instability
	var warning: String = "STABLE" if ratio < 0.5 else ("UNSTABLE" if ratio < 0.8 else "WARNING")
	$Maintenance.text = "KHATAK! JAMMED\nE: THAK %d/%d" % [repair_progress, repair_hits_required] if jammed else "%s %d%%" % [warning, roundi(ratio * 100)]
	$Maintenance.modulate = Color.TOMATO if jammed or ratio >= 0.8 else (Color.GOLD if ratio >= 0.5 else Color.LIGHT_GREEN)
	if power_cut:
		$Maintenance.text += "\nBIJLI GAYI! OFFLINE"
		if not jammed:
			$Maintenance.modulate = Color.LIGHT_STEEL_BLUE
	if cooled:
		$Maintenance.text += "  THANDA"

func _physics_process(delta: float) -> void:
	_flash = maxf(0, _flash - delta)
	queue_redraw()
	var now_cooled: bool = upgrades != null and upgrades.is_cooled(self)
	if now_cooled != cooled:
		cooled = now_cooled
		cooled_changed.emit(cooled)
		_update_maintenance()
	if not active or jammed or power_cut or not is_placed or not is_instance_valid(enemies):
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
		if kind in [Kind.PRESSURE_HORN, Kind.TURBO_PANKHA] and offset.normalized().dot(facing) < 0.7071:
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
		Kind.CHAKRI_GUN, Kind.JHATKA_SLING:
			facing = (nearest.global_position - global_position).normalized()
			if facing.is_zero_approx():
				facing = Vector2.RIGHT
			var scrap: ScrapProjectile = PROJECTILE.new()
			scrap.damage = damage_per_hit()
			if kind == Kind.JHATKA_SLING:
				scrap.projectile_color = Color.CYAN
				scrap.projectile_size = Vector2(18, 8)
			scrap.direction = facing
			scrap.remaining_distance = attack_range + 25.0
			projectiles.add_child(scrap)
			scrap.global_position = global_position
		Kind.DHAMAAL_BOX, Kind.BIJLI_CHAKRI, Kind.PRESSURE_CHAKRA:
			for enemy in targets:
				enemy.receive_damage(damage_per_hit())
		Kind.PRESSURE_HORN, Kind.TURBO_PANKHA, Kind.AANDHI_DJ:
			var push: float = knockback_strength()
			for enemy in targets:
				enemy.receive_damage(damage_per_hit())
				var away: Vector2 = (enemy.global_position - global_position).normalized()
				enemy.apply_knockback((facing if away.is_zero_approx() else away) * push)
		Kind.COOKER_CANNON:
			var shell = CANNON_SHELL.new()
			shell.target_position = nearest.global_position
			shell.enemies = enemies
			shell.damage = damage_per_hit()
			shell.blast_radius *= blast_radius_multiplier()
			projectiles.add_child(shell)
			shell.global_position = global_position
	fired.emit()
	_add_instability()

func _draw() -> void:
	var sprite: Sprite2D = $Sprite
	if sprite.texture == null:
		draw_rect(Rect2(-25, -20, 50, 40), Color(0.2, 0.24, 0.28))
		draw_line(Vector2(-18, 12), Vector2(18, -12), Color.WHITE, 2)
	else:
		sprite.flip_h = facing.x < 0.0
	if kind in [Kind.CHAKRI_GUN, Kind.PRESSURE_HORN, Kind.TURBO_PANKHA, Kind.JHATKA_SLING, Kind.COOKER_CANNON]:
		draw_line(Vector2.ZERO, facing * 38, Color.WHITE, 3)
	if _flash > 0 and is_placed:
		var radius: float = attack_range * (1.0 - _flash / 0.22)
		if kind == Kind.DHAMAAL_BOX:
			draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color.MEDIUM_PURPLE, 4)
		elif kind in [Kind.BIJLI_CHAKRI, Kind.PRESSURE_CHAKRA, Kind.AANDHI_DJ]:
			var color: Color = Color.CYAN if kind == Kind.BIJLI_CHAKRI else (Color.ORANGE if kind == Kind.PRESSURE_CHAKRA else Color.LIGHT_SKY_BLUE)
			# Short rotating spokes vs sustained wind rings; source components stay visible.
			if kind == Kind.AANDHI_DJ:
				draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color, 2)
				draw_arc(Vector2.ZERO, radius * 0.65, 0, TAU, 32, color, 1)
			else:
				for i in 8:
					var ray: Vector2 = Vector2.from_angle(i * TAU / 8 + radius * 0.04)
					draw_line(ray * 28, ray * attack_range, color, 2)
		elif kind in [Kind.PRESSURE_HORN, Kind.TURBO_PANKHA]:
			var angle: float = facing.angle()
			var color: Color = Color.CORAL if kind == Kind.PRESSURE_HORN else Color.CYAN
			draw_arc(Vector2.ZERO, radius, angle - PI / 4, angle + PI / 4, 24, color, 5 if kind == Kind.PRESSURE_HORN else 2)
			draw_line(Vector2.ZERO, facing.rotated(-PI / 4) * radius, color, 2)
			draw_line(Vector2.ZERO, facing.rotated(PI / 4) * radius, color, 2)
