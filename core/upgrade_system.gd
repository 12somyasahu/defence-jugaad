class_name UpgradeSystem
extends Node

# M7A Jugaad Mods. Owns which mods this run has, the current preparation's mod offers and
# the one-mod / one-patch allowances, and answers stat queries for JugaadWeapon.
# Scrap stays in ScrapEconomy, HP in Workshop, the purchase point is the Kabadiwala.

# Owned set changed; weapons re-read their stats, views redraw.
signal mods_changed(owned: Array[StringName])
signal offers_changed(offers: Array[StringName])
# Preparation window opened/closed or an allowance was used.
signal shop_state_changed
signal mod_purchased(mod_id: StringName, cost: int)
signal patch_purchased(healed: int, cost: int)
signal feedback(message: String)

## 0 = random offers each run; any other value makes offers reproducible.
@export var random_seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var owned: Array[StringName] = []
# This preparation's offers in slot order; sold/closed slots keep their id (see mod_bought).
var offers: Array[StringName] = []
# The mod bought this preparation, or &"" if none yet. One per preparation.
var mod_bought: StringName = &""
var patch_used: bool = false
# True only during a legitimate between-wave PREPARATION/COUNTDOWN.
var session_open: bool = false
var economy: Node
var workshop: Workshop
var jugaad_loop: JugaadLoop
var wave_director: WaveDirector

func setup(currency: Node, workshop_node: Workshop, loop: JugaadLoop, waves: WaveDirector) -> void:
	economy = currency
	workshop = workshop_node
	jugaad_loop = loop
	wave_director = waves
	if random_seed != 0:
		rng.seed = random_seed
	else:
		rng.randomize()
	wave_director.state_changed.connect(_on_wave_state_changed)

func owns(mod_id: StringName) -> bool:
	return mod_id in owned

static func definition(mod_id: StringName) -> Dictionary:
	return UpgradeTable.MODS.get(mod_id, {})

static func contains_component(kind: int, component: int) -> bool:
	return component == UpgradeTable.ANY or component in JugaadWeapon.SOURCE_PAIRS[kind]

## Product of every owned mod's factor for this stat on this Jugaad kind (1.0 = unchanged).
## Pass the weapon to include placement-dependent effects (THANDA THANDA cooling).
func multiplier(kind: int, stat: String, weapon: JugaadWeapon = null) -> float:
	var result: float = 1.0
	for mod_id in owned:
		var mod: Dictionary = UpgradeTable.MODS[mod_id]
		if mod.has("modifiers") and contains_component(kind, mod.component):
			result *= float(mod.modifiers.get(stat, 1.0))
		if weapon != null and mod.has("aura") and is_cooled(weapon):
			result *= float(mod.aura.get(stat, 1.0))
	return result

## Repair hit requirement after mods, never above the weapon's own base.
func repair_hits(kind: int, base: int) -> int:
	var hits: int = base
	for mod_id in owned:
		var mod: Dictionary = UpgradeTable.MODS[mod_id]
		if mod.has("repair_hits") and contains_component(kind, mod.component):
			hits = mini(hits, int(mod.repair_hits))
	return maxi(1, hits)

## THANDA THANDA: placed within the aura radius of ANOTHER placed Table Fan Jugaad.
## Boolean, so overlapping fans never stack.
func is_cooled(weapon: JugaadWeapon) -> bool:
	if not owns(&"thanda_thanda") or not is_instance_valid(weapon) or not weapon.is_placed or not is_instance_valid(jugaad_loop):
		return false
	var aura: Dictionary = UpgradeTable.MODS[&"thanda_thanda"].aura
	var radius_squared: float = float(aura.radius) * float(aura.radius)
	for child in jugaad_loop.weapons.get_children():
		var fan: JugaadWeapon = child as JugaadWeapon
		if fan == null or fan == weapon or not fan.is_placed or not fan.active:
			continue
		if contains_component(fan.kind, UpgradeTable.MODS[&"thanda_thanda"].component) and fan.global_position.distance_squared_to(weapon.global_position) <= radius_squared:
			return true
	return false

func can_shop() -> bool:
	return session_open and is_instance_valid(wave_director) and wave_director.state in [WaveDirector.State.PREPARATION, WaveDirector.State.COUNTDOWN]

func buy_mod(slot: int) -> bool:
	if not can_shop() or slot < 0 or slot >= offers.size():
		return false
	if mod_bought != &"":
		feedback.emit("One mod per visit. Next preparation: new mods.")
		return false
	var mod_id: StringName = offers[slot]
	var cost: int = int(UpgradeTable.MODS[mod_id].cost)
	if economy.scrap < cost:
		feedback.emit("SCRAP KAM HAI!")
		return false
	if not economy.try_spend(cost):
		return false
	mod_bought = mod_id
	owned.append(mod_id)
	mods_changed.emit(owned.duplicate())
	shop_state_changed.emit()
	mod_purchased.emit(mod_id, cost)
	feedback.emit("MOD LAGA! %s: %s" % [UpgradeTable.MODS[mod_id].name, UpgradeTable.MODS[mod_id].effect])
	return true

func buy_patch() -> bool:
	if not can_shop() or not is_instance_valid(workshop):
		return false
	if patch_used:
		feedback.emit("One patch per preparation.")
		return false
	if workshop.current_hp >= workshop.maximum_hp:
		feedback.emit("Workshop already full HP.")
		return false
	if economy.scrap < UpgradeTable.PATCH_COST:
		feedback.emit("SCRAP KAM HAI!")
		return false
	if not economy.try_spend(UpgradeTable.PATCH_COST):
		return false
	var healed: int = workshop.heal(UpgradeTable.PATCH_HEAL)
	patch_used = true
	shop_state_changed.emit()
	patch_purchased.emit(healed, UpgradeTable.PATCH_COST)
	feedback.emit("TIRPAL-EENT LAG GAYA! +%d HP" % healed)
	return true

## DEBUG only: own a mod without paying (next unowned in ORDER if none given).
func debug_grant(mod_id: StringName = &"") -> StringName:
	if not OS.is_debug_build():
		return &""
	if mod_id == &"":
		for candidate in UpgradeTable.ORDER:
			if not owns(candidate):
				mod_id = candidate
				break
	if mod_id == &"" or owns(mod_id) or not UpgradeTable.MODS.has(mod_id):
		return &""
	owned.append(mod_id)
	mods_changed.emit(owned.duplicate())
	shop_state_changed.emit()
	return mod_id

func owned_names() -> Array[String]:
	var names: Array[String] = []
	for mod_id in owned:
		names.append(UpgradeTable.MODS[mod_id].name)
	return names

## New legitimate preparation: fresh unowned offers, allowances reset. Never rerolls mid-phase.
func start_preparation() -> void:
	var pool: Array[StringName] = []
	for mod_id in UpgradeTable.ORDER:
		if not owns(mod_id):
			pool.append(mod_id)
	# Seeded Fisher-Yates so seeded runs are reproducible.
	for i in range(pool.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: StringName = pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	offers.assign(pool.slice(0, UpgradeTable.OFFERS_PER_PREPARATION))
	mod_bought = &""
	patch_used = false
	session_open = true
	offers_changed.emit(offers.duplicate())
	shop_state_changed.emit()

func _on_wave_state_changed(state: WaveDirector.State, wave: int) -> void:
	if state == WaveDirector.State.PREPARATION and wave > 1:
		start_preparation()
	elif state in [WaveDirector.State.COMBAT, WaveDirector.State.VICTORY, WaveDirector.State.DEFEAT, WaveDirector.State.WAVE_CLEAR]:
		if session_open:
			session_open = false
			shop_state_changed.emit()
