extends SceneTree

# M7A Jugaad Mods regression. Instantiates the real main scene with timers frozen and
# drives preparation through WaveDirector's own state transitions.
# Run (from the project folder):
#   <Godot 4.7 exe> --headless --path . -s res://tests/test_m7a.gd
# Exit code 0 = all passed.

const MAIN: PackedScene = preload("res://main.tscn")
var passed: int = 0
var failed: int = 0
var main: Node
var up: UpgradeSystem
var economy: Node
var wd: WaveDirector
var kab: Node
var loop: JugaadLoop
var workshop: Workshop

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", label)

func near(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001

func _run() -> void:
	await _fresh()
	_test_baseline()
	_test_offers_and_allowance()
	_test_costs_and_sale()
	_test_effects()
	_test_thanda()
	_test_stacking()
	_test_repair()
	_test_patch()
	_test_outside_preparation()
	_test_all_owned()
	await _test_reset()
	print("M7A tests: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _fresh() -> void:
	if is_instance_valid(main):
		main.queue_free()
		await process_frame
	main = MAIN.instantiate()
	root.add_child(main)
	await process_frame
	up = main.get_node("UpgradeSystem")
	economy = main.get_node("ScrapEconomy")
	wd = main.get_node("WaveDirector")
	kab = main.get_node("Kabadiwala")
	loop = main.get_node("JugaadLoop")
	workshop = main.get_node("Workshop")
	# Freeze timers/spawns and random events; tests drive transitions explicitly.
	wd.process_mode = Node.PROCESS_MODE_DISABLED
	main.get_node("EventDirector").running = false
	up.set("rng", RandomNumberGenerator.new())
	up.rng.seed = 1234

func _enter_preparation(wave: int = 2) -> void:
	wd.wave_index = wave - 1
	kab.restock()
	kab.open_session()
	wd._enter(WaveDirector.State.PREPARATION, 25.0)

func _set_owned(ids: Array[StringName]) -> void:
	up.owned.assign(ids)
	up.mods_changed.emit(up.owned.duplicate())

func _weapon(kind: int, at: Vector2) -> JugaadWeapon:
	var weapon: JugaadWeapon = JugaadLoop.WEAPON.instantiate()
	weapon.kind = kind
	weapon.enemies = main.get_node("Enemies")
	weapon.projectiles = loop.projectiles
	weapon.upgrades = up
	loop.weapons.add_child(weapon)
	weapon.place_at(at, Vector2.RIGHT)
	return weapon

func _clear_weapons() -> void:
	for child in loop.weapons.get_children():
		loop.weapons.remove_child(child)
		child.free()

func _all_kinds() -> Array[JugaadWeapon]:
	_clear_weapons()
	var list: Array[JugaadWeapon] = []
	for kind in JugaadWeapon.NAMES.size():
		# Spread far apart so no aura touches another.
		list.append(_weapon(kind, Vector2(-2000 + kind * 500, 3000)))
	return list

func _test_baseline() -> void:
	_set_owned([])
	for weapon in _all_kinds():
		var k: int = weapon.kind
		check(weapon.attack_range == JugaadWeapon.RANGES[k], "base range %s" % JugaadWeapon.NAMES[k])
		check(weapon.attack_cooldown == JugaadWeapon.COOLDOWNS[k], "base cooldown %s" % JugaadWeapon.NAMES[k])
		check(weapon.damage_per_hit() == JugaadWeapon.DAMAGE[k], "base damage %s" % JugaadWeapon.NAMES[k])
		check(weapon.instability_per_attack() == JugaadWeapon.INSTABILITY_PER_ATTACK[k], "base instability %s" % JugaadWeapon.NAMES[k])
		check(weapon.knockback_strength() == JugaadWeapon.KNOCKBACK[k], "base knockback %s" % JugaadWeapon.NAMES[k])
		check(weapon.blast_radius_multiplier() == 1.0, "base blast %s" % JugaadWeapon.NAMES[k])
		check(weapon.repair_hits_required == 3, "base repair hits %s" % JugaadWeapon.NAMES[k])
		check(not weapon.cooled, "base not cooled %s" % JugaadWeapon.NAMES[k])
	# M6 contracts untouched.
	check(kab.component_price == 3, "component price still 3")
	check(WaveTable.WAVES.size() == 5 and WaveTable.WAVES[4].gunda == 15, "wave table unchanged")

func _test_offers_and_allowance() -> void:
	_set_owned([])
	economy.scrap = 200
	_enter_preparation(2)
	check(up.can_shop(), "shop open in legitimate preparation")
	check(up.offers.size() == 3, "3 offers")
	var unique: Dictionary = {}
	for id in up.offers:
		unique[id] = true
	check(unique.size() == 3, "offers unique")
	var first: Array[StringName] = up.offers.duplicate()
	# Reopening the shop in the same preparation never rerolls.
	kab.close_session()
	kab.open_session()
	check(up.offers == first, "no reroll on reopen")
	var bought: StringName = up.offers[0]
	var cost: int = UpgradeTable.MODS[bought].cost
	check(up.buy_mod(0), "buy first mod")
	check(economy.scrap == 200 - cost, "spent exactly once")
	check(up.owns(bought), "mod owned")
	check(not up.buy_mod(1), "second mod blocked this preparation")
	check(not up.buy_mod(0), "same slot rebuy blocked")
	check(economy.scrap == 200 - cost, "blocked purchases spent nothing")
	check(kab.get_node("ShopPanel/Panel/Offers").text.contains("closed"), "panel shows closed offers")
	# Components still purchasable after a mod.
	main.get_node("Player").global_position = kab.global_position + Vector2(0, -50)
	var before: int = economy.scrap
	check(kab.buy(1), "component purchase after mod")
	check(economy.scrap == before - 3, "component still 3")
	# Next preparation: allowance resets, owned mod never offered again.
	wd._enter(WaveDirector.State.COMBAT, 0.0)
	check(not up.can_shop(), "closed in combat")
	_enter_preparation(3)
	check(up.mod_bought == &"" and not up.patch_used, "allowances reset")
	check(not bought in up.offers and up.offers.size() == 3, "owned mod not re-offered")
	check(up.buy_mod(2), "can buy again next preparation")

func _test_costs_and_sale() -> void:
	var expected: Dictionary = {&"fevi_tight": 20, &"master_jugaadu": 12, &"overvoltage": 15, &"ball_bearing": 18, &"do_rubber": 12, &"nayi_seeti": 15, &"thanda_thanda": 15, &"dj_wale_babu": 15}
	for id in UpgradeTable.ORDER:
		_set_owned([])
		_enter_preparation(2)
		up.offers.assign([id])
		kab.set_sale_price(2) # M6 SALE must not discount mods.
		var cost: int = expected[id]
		check(UpgradeTable.MODS[id].cost == cost, "cost table %s" % id)
		economy.scrap = cost - 1
		check(not up.buy_mod(0), "insufficient blocks %s" % id)
		check(economy.scrap == cost - 1, "failed purchase spends nothing %s" % id)
		economy.scrap = cost
		check(up.buy_mod(0), "exact Scrap buys %s" % id)
		check(economy.scrap == 0, "sale does not discount %s" % id)
		kab.clear_sale_price()
	check(kab.current_price() == 3, "sale cleared back to 3")

func _has(kind: int, component: int) -> bool:
	return component in JugaadWeapon.SOURCE_PAIRS[kind]

func _test_effects() -> void:
	var weapons: Array[JugaadWeapon] = _all_kinds()
	var T = JunkComponent.Type
	_set_owned([&"fevi_tight"])
	for w in weapons:
		check(near(w.instability_per_attack(), JugaadWeapon.INSTABILITY_PER_ATTACK[w.kind] * 0.7), "fevi %s" % JugaadWeapon.NAMES[w.kind])
	_set_owned([&"overvoltage"])
	for w in weapons:
		var f: float = 1.5 if _has(w.kind, T.BATTERY) else 1.0
		check(w.damage_per_hit() == roundi(JugaadWeapon.DAMAGE[w.kind] * f), "overvoltage dmg %s" % JugaadWeapon.NAMES[w.kind])
		check(near(w.instability_per_attack(), JugaadWeapon.INSTABILITY_PER_ATTACK[w.kind] * f), "overvoltage inst %s" % JugaadWeapon.NAMES[w.kind])
	_set_owned([&"ball_bearing"])
	for w in weapons:
		var f: float = 0.75 if _has(w.kind, T.CYCLE_WHEEL) else 1.0
		check(near(w.attack_cooldown, JugaadWeapon.COOLDOWNS[w.kind] * f), "ball bearing %s" % JugaadWeapon.NAMES[w.kind])
		check(w.instability_per_attack() == JugaadWeapon.INSTABILITY_PER_ATTACK[w.kind], "ball bearing adds no instability %s" % JugaadWeapon.NAMES[w.kind])
	_set_owned([&"do_rubber"])
	for w in weapons:
		var f: float = 1.3 if _has(w.kind, T.RUBBER_BAND) else 1.0
		check(near(w.attack_range, JugaadWeapon.RANGES[w.kind] * f), "do rubber %s" % JugaadWeapon.NAMES[w.kind])
	_set_owned([&"dj_wale_babu"])
	for w in weapons:
		var f: float = 1.3 if _has(w.kind, T.SPEAKER) else 1.0
		check(near(w.attack_range, JugaadWeapon.RANGES[w.kind] * f), "dj wale babu %s" % JugaadWeapon.NAMES[w.kind])
	_set_owned([&"nayi_seeti"])
	for w in weapons:
		var f: float = 1.5 if _has(w.kind, T.PRESSURE_COOKER) else 1.0
		check(near(w.knockback_strength(), JugaadWeapon.KNOCKBACK[w.kind] * f), "nayi seeti push %s" % JugaadWeapon.NAMES[w.kind])
	var cannon: JugaadWeapon = weapons[JugaadWeapon.Kind.COOKER_CANNON]
	var shell = JugaadWeapon.CANNON_SHELL.new()
	check(near(shell.blast_radius * cannon.blast_radius_multiplier(), 100.0), "cannon blast 100")
	shell.free()
	check(near(weapons[JugaadWeapon.Kind.PRESSURE_HORN].knockback_strength(), 450.0), "horn push 450")
	check(weapons[JugaadWeapon.Kind.PRESSURE_CHAKRA].knockback_strength() == 0.0, "no invented knockback")
	check(weapons[JugaadWeapon.Kind.AANDHI_DJ].knockback_strength() == 70.0, "non-cooker push unchanged")
	_set_owned([])

func _test_thanda() -> void:
	_clear_weapons()
	_set_owned([&"thanda_thanda"])
	var fan: JugaadWeapon = _weapon(JugaadWeapon.Kind.TURBO_PANKHA, Vector2(0, 2000))
	var gun: JugaadWeapon = _weapon(JugaadWeapon.Kind.CHAKRI_GUN, Vector2(100, 2000))
	check(up.is_cooled(gun), "within 120 cooled")
	check(near(gun.instability_per_attack(), 2.0 * 0.7), "cooled instability x0.7")
	check(not up.is_cooled(fan), "fan does not cool itself")
	gun.place_at(Vector2(200, 2000), Vector2.RIGHT)
	check(not up.is_cooled(gun), "outside 120 not cooled")
	check(gun.instability_per_attack() == 2.0, "uncooled instability base")
	gun.place_at(Vector2(110, 2000), Vector2.RIGHT)
	check(up.is_cooled(gun), "reposition updates cooling")
	var fan2: JugaadWeapon = _weapon(JugaadWeapon.Kind.AANDHI_DJ, Vector2(60, 2060))
	check(near(gun.instability_per_attack(), 2.0 * 0.7), "overlapping auras do not stack")
	check(up.is_cooled(fan), "fan cooled by another fan")
	gun.pick_up()
	check(not up.is_cooled(gun), "carried Jugaad not cooled")
	_set_owned([])
	gun.place_at(Vector2(110, 2000), Vector2.RIGHT)
	check(not up.is_cooled(gun), "no mod, no cooling")
	fan2.pick_up()

func _test_stacking() -> void:
	_clear_weapons()
	_set_owned([&"overvoltage", &"dj_wale_babu", &"fevi_tight", &"thanda_thanda"])
	var box: JugaadWeapon = _weapon(JugaadWeapon.Kind.DHAMAAL_BOX, Vector2(0, 2500))
	check(box.damage_per_hit() == 18, "stack damage 12 x1.5")
	check(near(box.attack_range, 140.0 * 1.3), "stack range 140 x1.3")
	check(near(box.instability_per_attack(), 20.0 * 1.5 * 0.7), "stack instability uncooled")
	_weapon(JugaadWeapon.Kind.COOKER_CANNON, Vector2(50, 2500)) # Table Fan Jugaad nearby
	check(near(box.instability_per_attack(), 20.0 * 1.5 * 0.7 * 0.7), "stack instability cooled")
	# Range cap hook only limits modified ranges.
	_set_owned([&"do_rubber"])
	var sling: JugaadWeapon = _weapon(JugaadWeapon.Kind.JHATKA_SLING, Vector2(900, 2500))
	check(near(sling.attack_range, 494.0) and sling.attack_range <= UpgradeTable.MAX_MODIFIED_RANGE, "sling range 494 under cap")
	_set_owned([])
	check(box.attack_range == 140.0 and box.damage_per_hit() == 12, "stats return to base when mods cleared")

func _test_repair() -> void:
	_clear_weapons()
	_set_owned([])
	var weapon: JugaadWeapon = _weapon(JugaadWeapon.Kind.CHAKRI_GUN, Vector2(0, 2800))
	var existing_before: int = weapon.repair_hits_required
	_set_owned([&"master_jugaadu"])
	check(existing_before == 3 and weapon.repair_hits_required == 2, "existing Jugaad updates to 2 hits")
	var future: JugaadWeapon = _weapon(JugaadWeapon.Kind.PRESSURE_HORN, Vector2(300, 2800))
	check(future.repair_hits_required == 2, "future Jugaad 2 hits")
	check(weapon.force_jam(), "jam")
	weapon.repair()
	check(weapon.jammed, "still jammed after 1 hit")
	weapon.repair()
	check(not weapon.jammed and weapon.instability == 0.0, "repaired after 2 hits via normal repair()")
	_set_owned([])
	check(weapon.repair_hits_required == 3, "back to 3 without mod")

func _test_patch() -> void:
	_set_owned([])
	_enter_preparation(2)
	economy.scrap = 50
	workshop.current_hp = 400
	var hp_signal: Array = []
	var capture: Callable = func(current: int, _maximum: int) -> void: hp_signal.append(current)
	workshop.health_changed.connect(capture)
	check(up.buy_patch(), "patch buys")
	check(workshop.current_hp == 475 and economy.scrap == 40, "patch +75 for 10")
	check(hp_signal == [475], "health_changed emitted for HUD")
	check(not up.buy_patch() and economy.scrap == 40, "one patch per preparation")
	_enter_preparation(3)
	workshop.current_hp = 480
	check(up.buy_patch() and workshop.current_hp == workshop.maximum_hp and economy.scrap == 30, "patch caps at max, still 10")
	_enter_preparation(4)
	check(not up.buy_patch() and economy.scrap == 30, "blocked at full HP, no spend")
	workshop.current_hp = 300
	economy.scrap = 9
	check(not up.buy_patch() and economy.scrap == 9 and workshop.current_hp == 300, "insufficient Scrap blocks patch")
	kab.set_sale_price(2)
	economy.scrap = 10
	check(up.buy_patch() and economy.scrap == 0, "sale does not discount patch")
	kab.clear_sale_price()
	workshop.health_changed.disconnect(capture)
	workshop.current_hp = workshop.maximum_hp

func _test_outside_preparation() -> void:
	_set_owned([])
	economy.scrap = 100
	_enter_preparation(2)
	wd._enter(WaveDirector.State.COUNTDOWN, 5.0)
	check(up.can_shop(), "countdown still legitimate (shop open)")
	wd._enter(WaveDirector.State.COMBAT, 0.0)
	check(not up.buy_mod(0) and not up.buy_patch() and economy.scrap == 100, "no purchases in combat")
	# First preparation (wave 1) has no shop session.
	wd.wave_index = 0
	wd._enter(WaveDirector.State.PREPARATION, 20.0)
	check(not up.can_shop(), "no mod shop before wave 1")

func _test_all_owned() -> void:
	_set_owned(UpgradeTable.ORDER.duplicate())
	_enter_preparation(5)
	check(up.offers.is_empty(), "no offers when all owned")
	_set_owned(UpgradeTable.ORDER.slice(0, 6))
	_enter_preparation(5)
	check(up.offers.size() == 2, "shows only remaining mods")

func _test_reset() -> void:
	_set_owned([&"fevi_tight"])
	await _fresh()
	check(up.owned.is_empty() and up.offers.is_empty() and up.mod_bought == &"" and not up.patch_used, "fresh run clears upgrade state")
