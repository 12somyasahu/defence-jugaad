extends "res://tests/test_m7a.gd"

# Integration regression; reuses the M7A fixture without changing its 244 checks.
func _run() -> void:
	await _fresh()
	current_scene = main
	await _shop_and_visuals()
	await _combat_regression()
	await _waves_and_events()
	await _restart_and_defeat()
	print("Presentation integration: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _frames(count: int) -> void:
	for i in count:
		await physics_frame
	await process_frame

func _key(code: int) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(1)
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(1)

func _shop_and_visuals() -> void:
	var hud: HUD = main.get_node("HUD")
	var visual: WorkshopPresentation = workshop.get_node("Presentation")
	_enter_preparation()
	main.get_node("Player").position = kab.position + Vector2(0, -50)
	economy.debug_grant(100)
	kab._update_panel()
	await _frames(1)
	check(kab.get_node("OpenBadge").is_visible_in_tree(), "shop badge visible")
	for i in 3:
		var slot: Node = kab.get_node("ShopPanel/Panel/SlotContainer/Slot%d" % i)
		check(slot.get_node("Icon").texture == JunkComponent.TEXTURES[kab.offers[i]], "component icon %d" % i)
		check(slot.get_node("Tag").text.contains("3 Scrap"), "component price %d" % i)
		var before: int = economy.scrap
		await _key(KEY_1 + i)
		check(kab.offers[i] == -1 and economy.scrap == before - 3, "component key %d" % i)
		check(slot.get_node("Tag").text.contains("SOLD"), "sold card %d" % i)
	for i in 3:
		_enter_preparation(i + 2)
		var id: StringName = up.offers[i]
		await _key(KEY_4 + i)
		check(up.owns(id) and up.mod_bought == id, "mod key %d" % (4 + i))
		check(hud.mods_label.visible and hud.mods_label.text.contains(UpgradeTable.MODS[id].name), "owned strip")
		check(kab.get_node("ShopPanel/Panel/Offers").text.contains("closed"), "other choices close")
	_enter_preparation()
	workshop.receive_damage(400)
	check(visual.sprite.texture == visual.TEX_25 and visual.smoke_particles.emitting, "low HP sprite and smoke")
	var before: int = economy.scrap
	await _key(KEY_7)
	check(workshop.current_hp == 175 and economy.scrap == before - 10, "patch input heals and spends")
	check(visual.sprite.texture == visual.TEX_50 and not visual.smoke_particles.emitting, "healing reverses sprite and stops smoke")
	check(hud.health_bar.value == 175 and not hud._low_hp, "healing updates HUD and stops pulse")
	workshop.heal(999)
	check(workshop.current_hp == 500 and visual.sprite.texture == visual.TEX_100, "heal capped with restored sprite")
	for entry in [["NEXT WAVE: 00:20", "55ff99"], ["NEXT WAVE: 00:04", "ffbb33"], ["WAVE 2 INCOMING: 3", "ffbb33"], ["ENEMIES REMAINING: 4", "ff4444"], ["WAVE 2 CLEARED", "ffd700"]]:
		hud.set_wave_status(entry[0])
		check(hud.phase_label.modulate == Color(entry[1]), "phase color " + entry[0])
	hud.show_announcement("test", 0.4)
	await create_timer(0.45).timeout
	hud.show_announcement("persistent", 0)
	await create_timer(0.6).timeout
	check(hud.announcement_label.visible and hud.announcement_band.visible and hud.announcement_band.modulate.a == 1.0, "persistent replacement banner")
	_set_owned([&"master_jugaadu"])
	var weapon: JugaadWeapon = _weapon(0, Vector2(250, 0))
	weapon.force_jam()
	weapon.repair()
	await _frames(1)
	check(weapon.jammed and weapon.get_node("Presentation/RepairFeedback").text == "THAK! [1/2]", "MASTER denominator and partial repair")
	weapon.repair()
	check(not weapon.jammed and weapon.get_node("Presentation/RepairFeedback").text == "REPAIRED!", "MASTER completion VFX")
	_set_owned([])
	weapon.force_jam()
	weapon.repair()
	check(weapon.get_node("Presentation/RepairFeedback").text == "THAK! [1/3]", "base repair denominator")

func _pickup(kind: int) -> void:
	for child in loop.components.get_children():
		var item: JunkComponent = child as JunkComponent
		if item != null and item.component_type == kind:
			main.get_node("Player").position = item.global_position
			loop.interact()
			return

func _combat_regression() -> void:
	for kind in 9:
		await _fresh()
		current_scene = main
		var pair: Array = JugaadWeapon.SOURCE_PAIRS[kind]
		check(JugaadRecipes.resolve(pair[1], pair[0]) == kind, "unordered recipe %d" % kind)
		_pickup(pair[0])
		_pickup(pair[1])
		check(is_instance_valid(loop.left_hand) and is_instance_valid(loop.right_hand), "two hands %d" % kind)
		loop.combine()
		var weapon: JugaadWeapon = loop.carried_weapon
		check(weapon != null and weapon.kind == kind and not weapon.is_placed, "craft carry %d" % kind)
		main.get_node("Player").position = Vector2(136, -100)
		main.get_node("Player").facing = Vector2.RIGHT
		loop.interact()
		check(weapon.is_placed and loop.carried_weapon == null, "place %d" % kind)
		var target: Gunda = WaveDirector.ENEMY_SCENES["pehelwan"].instantiate()
		target.workshop = workshop
		main.get_node("Enemies").add_child(target)
		target.position = Vector2(260, -100)
		target.current_hp = 50000
		target.set_physics_process(false)
		await _frames(45)
		check(target.current_hp < 50000 and weapon.instability > 0, "attack damage/wear %d" % kind)
		weapon.force_jam()
		await _frames(60)
		var hp: int = target.current_hp
		await _frames(10)
		check(target.current_hp == hp, "jam stops damage %d" % kind)
		weapon.repair()
		weapon.repair()
		check(weapon.jammed, "two base hits still jammed %d" % kind)
		weapon.repair()
		check(not weapon.jammed, "third hit restores %d" % kind)
		main.get_node("Player").position = Vector2(170, -100)
		loop.interact()
		check(loop.carried_weapon == weapon and not weapon.is_placed, "reposition pickup %d" % kind)
		main.get_node("Player").position = Vector2(140, 80)
		loop.interact()
		check(weapon.is_placed, "reposition place %d" % kind)
	await _fresh()
	current_scene = main
	var player: JugaadPlayer = main.get_node("Player")
	var start: Vector2 = player.position
	Input.action_press("move_right")
	Input.action_press("move_up")
	await _frames(8)
	check(player.position.x > start.x and player.position.y < start.y and near(player.velocity.length(), player.movement_speed), "normalized movement")
	Input.action_release("move_right")
	Input.action_release("move_up")
	_pickup(0)
	_pickup(2)
	var left: JunkComponent = loop.left_hand
	var right: JunkComponent = loop.right_hand
	loop.combine()
	check(loop.left_hand == left and loop.right_hand == right, "unsupported preserves both")
	_pickup(4)
	check(loop.left_hand == left and loop.right_hand == right, "third item blocked")
	loop.drop_hand(true)
	loop.interact()
	check(loop.left_hand == left, "drop/re-pick same instance")
	var enemy: Gunda = WaveDirector.ENEMY_SCENES["gunda"].instantiate()
	enemy.workshop = workshop
	main.get_node("Enemies").add_child(enemy)
	enemy.position = player.position + Vector2(10, 0)
	await _frames(2)
	check(player.knockback.length() > 0 and loop.left_hand == null and loop.right_hand == null, "contact knockback scatters hands")
	check(left.get_parent() == loop.components and right.get_parent() == loop.components, "scatter preserves components")
	enemy.queue_free()
	await _frames(1)
	for type in ["gunda", "chotu", "pehelwan"]:
		var foe: Gunda = WaveDirector.ENEMY_SCENES[type].instantiate()
		foe.workshop = workshop
		main.get_node("Enemies").add_child(foe)
		foe.position = Vector2(65, 0)
		var before: int = workshop.current_hp
		await _frames(2)
		check(workshop.current_hp < before, "Workshop attack " + type)
		var scrap: int = economy.scrap
		var reward: int = foe.scrap_reward
		foe.receive_damage(999)
		foe.receive_damage(999)
		await _frames(1)
		check(economy.scrap == scrap + reward, "one death reward " + type)

func _waves_and_events() -> void:
	await _fresh()
	current_scene = main
	var events: EventDirector = main.get_node("EventDirector")
	events.running = true
	events.sale_chance = 0.0
	events.combat_event_chance = 0.0
	for index in 5:
		check(wd.wave_index == index, "progression wave %d" % (index + 1))
		if index > 0:
			check(up.can_shop() and kab.available, "real preparation shop")
			check(events.force_event(&"sale") and kab.current_price() == 2, "sale event")
		wd._advance()
		check(wd.state == WaveDirector.State.COUNTDOWN, "countdown")
		wd._advance()
		check(wd.state == WaveDirector.State.COMBAT and kab.current_price() == 3, "combat clears sale")
		check(wd.usable_routes().size() == int(WaveTable.WAVES[index].routes), "route count")
		if index == 2:
			var electric: JugaadWeapon = _weapon(1, Vector2(-100, 200))
			check(events.force_event(&"bijli") and electric.power_cut, "power outage")
			events._end(&"bijli")
			check(not electric.power_cut, "power restored")
			check(events.force_event(&"breakdown") and electric.jammed, "breakdown")
			var routes_before: int = wd.usable_routes().size()
			check(events.force_event(&"rasta_band") and wd.usable_routes().size() == routes_before - 1, "blocked route")
			events._end(&"rasta_band")
			check(events.force_event(&"rush"), "rush begins")
			for i in 3:
				events._spawn_rush_enemy()
			check(wd.event_spawned == 3, "rush tracked spawns")
		while not wd._queue.is_empty():
			wd._spawn_next()
		for foe in main.get_node("Enemies").get_children():
			foe.receive_damage(999)
		await _frames(2)
		if index < 4:
			check(wd.state == WaveDirector.State.WAVE_CLEAR, "wave clear")
			wd._advance()
	check(wd.state == WaveDirector.State.VICTORY and main.get_node("HUD").victory_panel.visible, "Wave 5 victory panel unchanged")
	check(main.get_node("Arena").stage > 0 and main.get_node("Camera2D").zoom.x < 1.0, "expanded arena and camera")

func _restart_and_defeat() -> void:
	await _key(KEY_R)
	main = current_scene
	wd = main.get_node("WaveDirector")
	wd.set_process(false)
	check(main.get_node("UpgradeSystem").owned.is_empty() and main.get_node("ScrapEconomy").scrap == 0, "R clears upgrades and Scrap")
	check(not main.get_node("HUD").end_game_overlay.visible and main.get_node("JugaadLoop/Weapons").get_child_count() == 0, "R clears panels and weapons")
	main.get_node("Workshop").receive_damage(999)
	check(main.get_node("HUD").defeat_panel.visible and not main.get_node("JugaadLoop").active, "defeat panel and stop")
	await _key(KEY_R)
	check(current_scene.get_node("Workshop").current_hp == 500 and not current_scene.get_node("HUD").end_game_overlay.visible, "restart after defeat")
