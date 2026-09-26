extends "res://tests/test_m7a.gd"

var bd: BossDirector
var boss: Thekedaar
var sound: GameAudio
var stats: RunStats
var hud: HUD

func _run() -> void:
	await _flow()
	await _parts_and_weapons()
	await _speaker()
	await _battery()
	await _reinforcements()
	await _victory()
	await _defeat()
	await _stats()
	await _audio()
	await _restart()
	print("M7B tests: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _frames(count: int) -> void:
	for i in count:
		await physics_frame
	await process_frame

func _fixture(combat: bool = true) -> void:
	await _fresh()
	current_scene = main
	bd = main.get_node("BossDirector")
	bd.set_process(false)
	sound = main.get_node("AudioManager")
	stats = main.get_node("RunStats")
	hud = main.get_node("HUD")
	wd.wave_index = 4
	wd._apply_wave_layout(false)
	wd._enter(WaveDirector.State.COMBAT, 0)
	wd._check_clear()
	if combat:
		wd._advance()
		wd._advance()
		boss = bd.boss
		boss.set_physics_process(false)
		main.get_node("Player").set_physics_process(false)

func _flow() -> void:
	await _fixture(false)
	check(wd.state == WaveDirector.State.PREPARATION and wd.boss_pending, "Wave 5 boss prep")
	check(not hud.victory_panel.visible and bd.stage == &"preparation", "not immediate victory")
	check(wd.time_left == 30.0 and bd.preparation_seconds == 30.0, "30 seconds")
	check(bd.route in wd.usable_routes(), "route selected usable")
	var locked: AttackRoute = bd.route
	bd.begin_preparation()
	check(bd.route == locked and wd.time_left == 30.0, "repeat entry cannot reroll route")
	check(kab.available and up.can_shop() and up.offers.size() == 3, "final shop and mods")
	economy.debug_grant(100)
	main.get_node("Player").position = kab.position
	check(kab.buy(0), "final component buy")
	check(up.buy_mod(0) and not up.buy_mod(1), "one final mod")
	workshop.receive_damage(80)
	check(up.buy_patch() and workshop.current_hp == 495, "final patch")
	bd._process(2.5)
	check(hud.announcement_label.text == "FROM %s!" % locked.route_name, "route announcement")
	var events: EventDirector = main.get_node("EventDirector")
	events.running = true
	check(events.force_event(&"sale") and kab.current_price() == 2, "final prep sale")
	wd._advance()
	check(wd.state == WaveDirector.State.COUNTDOWN and wd.time_left == 5.0, "five second countdown")
	wd._process(0.01)
	check(hud.announcement_label.text.contains("THEKEDAAR INCOMING"), "boss countdown label")
	wd._advance()
	boss = bd.boss
	boss.set_physics_process(false)
	check(bd.stage == &"combat" and wd.boss_combat, "boss combat begins")
	check(not kab.available and not up.can_shop() and kab.current_price() == 3, "combat closes final shop and sale")
	check(boss.position == locked.position - locked.direction * 75.0, "spawn on locked route")
	check(hud.get_node("BossPanel").visible, "boss HUD visible")
	events.combat_event_chance = 1.0
	events._on_wave_started(5)
	check(events._scheduled_at < 0.0, "random scheduler disabled")
	events._scheduled_at = 0.0
	var history_size: int = events.history.size()
	events._process(30.0)
	check(events.history.size() == history_size, "no scheduled boss random event")
	check(sound.music_id == "thekedaar_theme", "boss music state")

func _parts_and_weapons() -> void:
	await _fixture()
	for id in Thekedaar.PART_HP:
		var part: BossPart = boss.parts[id]
		check(part.current_hp == Thekedaar.PART_HP[id], "HP " + String(id))
		check(part.scrap_reward == 0 and part.knockback_multiplier == 0, "reward/knockback " + String(id))
		part.apply_knockback(Vector2(300, 100))
		check(part._knockback == Vector2.ZERO, "immune " + String(id))
		check(part.collision_layer == 4 and part.get_parent() == main.get_node("Enemies"), "target interface " + String(id))
	boss.parts[&"chassis"].receive_damage(10)
	check(boss.parts[&"chassis"].current_hp == 1490 and boss.alive(&"speaker"), "chassis immediately vulnerable")
	check(boss.speed() == 35.0, "base speed")
	boss.parts[&"engine"].receive_damage(400)
	check(boss.speed() == 17.5 and not boss.alive(&"engine"), "engine slows by half")
	check(economy.scrap == 0 and stats.enemies_thoked == 0, "module gives no Scrap or gang kill")
	boss.position = Vector2(400, 0)
	var before: Vector2 = boss.position
	boss._physics_process(1.0)
	check(near(before.distance_to(boss.position), 17.5), "controller moves whole vehicle")
	check(boss.parts[&"chassis"].position == boss.position + Vector2(Thekedaar.PART_OFFSETS[&"chassis"]).rotated(boss.facing.angle() - PI), "parts follow")
	boss.position = Vector2(100, 0)
	boss._ram_left = 0.4
	var cues: Array[StringName] = []
	boss.attack_cued.connect(func(id: StringName) -> void: cues.append(id))
	boss._physics_process(0.1)
	check(&"workshop" in cues and workshop.current_hp == 500, "Workshop ram warning")
	boss._physics_process(0.4)
	check(workshop.current_hp == 475, "ram damage 25")
	boss._physics_process(0.5)
	check(workshop.current_hp == 475, "ram cooldown")
	for kind in 9:
		await _fixture()
		boss.position = Vector2(280, -100)
		boss.facing = Vector2.LEFT
		boss._sync_parts()
		var weapon: JugaadWeapon = _weapon(kind, Vector2(190, -100))
		var total_before: int = _boss_hp()
		await _frames(45)
		check(_boss_hp() < total_before, "weapon hits parts %d" % kind)
		check(weapon.instability > 0, "normal wear vs boss %d" % kind)

func _boss_hp() -> int:
	var total: int = 0
	for part in boss.parts.values():
		total += part.current_hp
	return total

func _speaker() -> void:
	await _fixture()
	boss.position = Vector2(300, 0)
	boss._sync_parts()
	boss.moving = false
	boss._stop_left = 10
	var weapon: JugaadWeapon = _weapon(0, Vector2(200, 0))
	weapon.set_physics_process(false)
	var far: JugaadWeapon = _weapon(0, Vector2(-300, 0))
	far.set_physics_process(false)
	main.get_node("Player").position = Vector2(220, 0)
	var cues: Array[String] = []
	sound.sfx_triggered.connect(func(id: String) -> void: cues.append(id))
	check(boss.start_speaker() and boss.speaker_charge == 2.0, "speaker telegraph")
	check("boss/speaker_charge" in cues, "speaker SFX hook")
	boss._physics_process(1.0)
	check(weapon.instability == 0.0, "speaker not instant")
	boss._physics_process(1.0)
	check(weapon.instability == 40 and far.instability == 0, "speaker radius and 40 wear")
	check(not weapon.jammed and main.get_node("Player").knockback.length() == 420.0, "speaker normal wear and player disruption")
	check("boss/speaker_blast" in cues, "speaker blast SFX")
	weapon.instability = 70
	boss.start_speaker()
	boss._physics_process(2.0)
	check(weapon.jammed and weapon.instability == 100, "speaker uses regular jam threshold")
	boss.start_speaker()
	boss.parts[&"speaker"].receive_damage(300)
	check(boss.speaker_charge == 0 and not boss.start_speaker(), "speaker destruction cancels and disables")

func _battery() -> void:
	await _fixture()
	boss.position = Vector2(300, 0)
	boss._sync_parts()
	var a: JugaadWeapon = _weapon(1, Vector2(200, 0))
	var b: JugaadWeapon = _weapon(3, Vector2(150, 0))
	var c: JugaadWeapon = _weapon(4, Vector2(80, 0))
	var mechanical: JugaadWeapon = _weapon(0, Vector2(280, 0))
	for weapon in [a, b, c, mechanical]:
		weapon.set_physics_process(false)
	var cues: Array[String] = []
	sound.sfx_triggered.connect(func(id: String) -> void: cues.append(id))
	check(boss.start_battery() and boss.battery_targets == [a, b], "two nearest Battery recipes")
	check("boss/battery_charge" in cues and not a.power_cut, "battery telegraph SFX and delay")
	boss._physics_process(2.0)
	check(a.power_cut and b.power_cut and not c.power_cut and not mechanical.power_cut, "power cut selected electrical only")
	check(boss.outages[a] == 6.0 and "boss/battery_zap" in cues, "six second outage hook")
	boss._tick_outages(6.0)
	check(not a.power_cut and not b.power_cut, "outage expires")
	boss.start_battery()
	a.pick_up()
	b.position = Vector2(-500, 0)
	boss._physics_process(2.0)
	check(not a.power_cut and not b.power_cut, "picked up and escaped targets cancelled")
	a.place_at(Vector2(200, 0), Vector2.RIGHT)
	b.place_at(Vector2(150, 0), Vector2.RIGHT)
	boss.start_battery()
	boss._physics_process(2.0)
	boss.parts[&"battery"].receive_damage(300)
	check(not a.power_cut and not b.power_cut and not boss.start_battery(), "destroyed battery clears outages/disables")

func _reinforcements() -> void:
	await _fixture()
	var announcements: Array = []
	bd.reinforcement_announced.connect(func(routes: Array[String]) -> void: announcements.append(routes))
	boss.parts[&"chassis"].receive_damage(510)
	check(bd._reinforcements.size() == 8 and wd._event_pending == 8, "66 percent eight reserved")
	check(announcements.size() == 1 and announcements[0].size() == 2 and not bd.route.route_name in announcements[0], "HAFTA other two routes")
	var gunda_count: int = 0
	var chotu_count: int = 0
	for entry in bd._reinforcements:
		gunda_count += int(entry.kind == "gunda")
		chotu_count += int(entry.kind == "chotu")
	check(gunda_count == 6 and chotu_count == 2, "HAFTA mix")
	boss.parts[&"chassis"].receive_damage(1)
	check(bd._reinforcements.size() == 8, "66 cannot retrigger")
	boss.parts[&"chassis"].receive_damage(494)
	check(bd._reinforcements.size() == 16 and announcements.size() == 2, "33 percent once")
	boss.parts[&"chassis"].receive_damage(1)
	check(bd._reinforcements.size() == 16, "33 cannot retrigger")
	bd._escort_left = 1000
	for i in 16:
		bd._process(2.1 if i == 0 else 0.4)
	check(wd.event_spawned == 16 and wd._event_pending == 0, "HAFTA existing spawn accounting")
	await _fixture()
	for i in 10:
		bd._process(7.1)
	check(bd._escorts_spawned == 10 and wd.event_spawned == 10, "ten trickled escorts")
	gunda_count = 0
	chotu_count = 0
	for child in main.get_node("Enemies").get_children():
		if child is BossPart:
			continue
		gunda_count += int(child.maximum_hp == 30)
		chotu_count += int(child.maximum_hp == 15)
	check(gunda_count == 6 and chotu_count == 4, "escort composition")
	bd._process(100)
	check(bd._escorts_spawned == 10, "escort cap")

func _victory() -> void:
	await _fixture()
	bd._process(7.0)
	boss.parts[&"chassis"].receive_damage(510)
	var scrap: int = economy.scrap
	var kills: int = stats.enemies_thoked
	var dialogue: Array[String] = []
	sound.dialogue_started.connect(func(id: String) -> void: dialogue.append(id))
	boss.parts[&"chassis"].receive_damage(9999)
	check(bd.stage == &"finale" and not boss.active, "chassis immediately starts finale")
	check(boss.alive(&"speaker") and boss.alive(&"battery"), "modules need not die")
	check(bd._reinforcements.is_empty() and wd._event_pending == 0 and wd.state == WaveDirector.State.VICTORY, "reserved/queued spawns cancelled")
	check(not main.get_node("EventDirector").running and not loop.active and not main.get_node("Player").active, "finale freezes gameplay")
	await _frames(2)
	check(main.get_node("Enemies").get_child_count() == 4, "remaining gang despawns")
	check(economy.scrap == scrap and stats.enemies_thoked == kills, "flee gives no reward/kill")
	check(sound.music_id == "victory" and not hud.victory_panel.visible, "sting before end panel")
	for i in 4:
		bd._process(4.0)
	check(dialogue == ["thekedaar_defeated", "ending_engineering", "ending_nahi", "ending_jugaad_hai"], "ordered deterministic finale dialogue")
	check(bd.stage == &"complete" and hud.victory_panel.visible and hud.victory_stats.text.contains("Enemies Thoked"), "final stats panel")
	check(not boss.start_speaker() and not boss.start_battery(), "no attacks after victory")

func _defeat() -> void:
	for combat in [false, true]:
		await _fixture(combat)
		if combat:
			boss.parts[&"chassis"].receive_damage(510)
		workshop.receive_damage(9999)
		check(bd.stage == &"cancelled" and wd.state == WaveDirector.State.DEFEAT, "defeat cancels boss stage")
		check(bd._reinforcements.is_empty() and wd._event_pending == 0, "defeat cancels reservations")
		bd._process(100.0)
		check(hud.defeat_panel.visible and not hud.victory_panel.visible, "no finale after defeat")
		check(sound.music_id == "defeat" and sound.dialogue_id == "", "defeat audio cancellation")
		if combat:
			check(not boss.active and not boss.start_battery(), "dead Workshop stops abilities")

func _stats() -> void:
	await _fixture(false)
	var foe: Gunda = WaveDirector.ENEMY_SCENES["gunda"].instantiate()
	foe.workshop = workshop
	main.get_node("Enemies").add_child(foe)
	foe.receive_damage(30)
	foe.receive_damage(30)
	check(stats.enemies_thoked == 1 and stats.scrap_collected == 2, "death and earned stats once")
	economy.debug_grant(100)
	economy.try_spend(3)
	check(stats.scrap_collected == 2, "debug grants/spending not earned")
	for kind in [1, 5]:
		for child in loop.components.get_children():
			if child.component_type == kind:
				main.get_node("Player").position = child.position
				loop.interact()
				break
	loop.combine()
	check(stats.jugaads_built == 1, "craft signal counted")
	main.get_node("Player").position = Vector2(136, -100)
	main.get_node("Player").facing = Vector2.RIGHT
	loop.interact()
	var weapon: JugaadWeapon = loop.weapons.get_child(0)
	weapon.force_jam()
	weapon.repair()
	weapon.repair()
	weapon.repair()
	check(stats.thoks == 3, "three valid THOKs")
	weapon.repair()
	check(stats.thoks == 3, "invalid repair not counted")
	weapon.pick_up()
	weapon.place_at(Vector2(210, 100), Vector2.RIGHT)
	weapon.force_jam()
	weapon.repair()
	check(stats.thoks == 4 and stats.jugaads_built == 1, "reposition doesn't duplicate tracking")
	check(up.buy_mod(0) and stats.mods_purchased == 1, "mod stats")
	check(stats.normal_waves_completed == 1, "wave clear signal counted")

func _audio() -> void:
	await _fixture(false)
	sound.cancel_dialogue()
	check(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("Dialogue") >= 0 and AudioServer.get_bus_index("SFX") >= 0, "audio buses")
	var transitions: Array[String] = []
	sound.music_changed.connect(func(id: String) -> void: transitions.append(id))
	sound.play_music("combat_theme")
	sound.play_music("combat_theme")
	check(transitions == ["combat_theme"], "same music doesn't restart")
	for id in AudioCatalog.MUSIC:
		sound.play_music(id)
		check(sound.music_id == id, "music optional " + id)
	for id in AudioCatalog.SFX:
		sound.play_sfx(id, true)
	check(sound.missing.has("res://audio/sfx/boss/speaker_charge.ogg") or sound._cache.has("res://audio/sfx/boss/speaker_charge.ogg"), "optional SFX handled")
	check(sound.play_dialogue("ending_engineering", 2.0, true), "subtitle optional voice")
	check(hud.get_node("CinematicOverlay/Subtitle").visible and hud.get_node("CinematicOverlay/Subtitle").text == "Yeh sab engineering hai?", "subtitle text without voice")
	check(sound.duck_db == -5.0, "dialogue ducks music")
	sound._process(2.1)
	check(sound.duck_db == 0 and not hud.get_node("CinematicOverlay/Subtitle").visible, "duck and subtitle restore")
	sound._process(10)
	check(sound.play_dialogue("jugaad_jammed"), "rate-limited bark first")
	check(not sound.play_dialogue("jugaad_jammed"), "duplicate bark blocked")
	check(not sound.play_dialogue("scrap_kam_hai"), "global bark cooldown")
	sound.dialogue_locked = true
	check(not sound.play_dialogue("first_jugaad"), "finale dialogue lock")
	check(sound.play_dialogue("ending_jugaad_hai", 2, true), "finale force allowed")
	var shots: Array[String] = []
	sound.sfx_triggered.connect(func(id: String) -> void: shots.append(id))
	sound._process(1)
	sound.play_sfx("weapons/mechanical_shot")
	sound.play_sfx("weapons/mechanical_shot")
	check(shots == ["weapons/mechanical_shot"], "rapid SFX rate limited")
	check(sound._pool.size() == 10, "bounded SFX pool")

func _restart() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_R
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(3)
	event.pressed = false
	Input.parse_input_event(event)
	check(current_scene != main and current_scene.get_node("BossDirector").stage == &"idle", "R resets entire boss run")
	check(current_scene.get_node("RunStats").snapshot() == {"waves":0, "kills":0, "built":0, "scrap":0, "thoks":0, "mods":0}, "stats all reset")
	check(not current_scene.get_node("HUD/BossPanel").visible and not current_scene.get_node("HUD").end_game_overlay.visible, "boss and end HUD reset")
	check(current_scene.get_node("AudioManager").music_id == "preparation_theme" and not current_scene.get_node("AudioManager").dialogue_locked, "audio resets to new run")
