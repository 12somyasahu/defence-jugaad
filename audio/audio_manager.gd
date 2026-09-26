class_name GameAudio
extends Node

signal music_changed(id: String)
signal sfx_triggered(id: String)
signal subtitle_changed(text: String, seconds: float)
signal dialogue_started(id: String)

var music_id: String = ""
var dialogue_id: String = ""
var dialogue_locked: bool = false
var dialogue_remaining: float = 0.0
var duck_db: float = 0.0
var missing: Dictionary = {}
var _cache: Dictionary = {}
var _clock: float = 0.0
var _sfx_last: Dictionary = {}
var _dialogue_last: Dictionary = {}
var _last_bark: float = -100.0
var _music_gain: float = -12.0
var _first_craft: bool = false
var _critical: bool = false
var _last_hp: int = 500
var _warning_music_left: float = 0.0
var music: AudioStreamPlayer
var voice: AudioStreamPlayer
var engine: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _main: Node

func _ready() -> void:
	for bus in ["Music", "SFX", "Dialogue"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	music = _player("Music")
	voice = _player("Dialogue")
	engine = _player("SFX")
	engine.volume_db = -20.0
	for i in 10:
		_pool.append(_player("SFX"))

func _player(bus: String) -> AudioStreamPlayer:
	var node: AudioStreamPlayer = AudioStreamPlayer.new()
	node.bus = bus
	add_child(node)
	return node

func _optional(path: String, looped: bool = false) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if missing.has(path):
		return null
	# Missing files are recorded once, without issuing ResourceLoader errors.
	if not ResourceLoader.exists(path):
		missing[path] = true
		return null
	var stream: AudioStream = ResourceLoader.load(path) as AudioStream
	if stream is AudioStreamOggVorbis:
		stream = stream.duplicate()
		stream.loop = looped
	_cache[path] = stream
	return stream

func play_music(id: String) -> void:
	if music_id == id:
		return
	music_id = id
	music.stop()
	music.stream = _optional("res://audio/music/%s.ogg" % id, id in AudioCatalog.MUSIC_LOOPS)
	_music_gain = -36.0
	if music.stream != null:
		music.play()
	music_changed.emit(id)

func stop_music() -> void:
	music.stop()
	music_id = ""

func play_sfx(id: String, priority: bool = false) -> bool:
	var cooldown: float = 0.15 if id.begins_with("weapons/") or id.begins_with("enemies/") else 0.08
	if _clock - float(_sfx_last.get(id, -100.0)) < cooldown:
		return false
	_sfx_last[id] = _clock
	sfx_triggered.emit(id)
	var stream: AudioStream = _optional("res://audio/sfx/%s.ogg" % id)
	if stream == null:
		return true
	# Two reserved slots keep telegraphs audible even during rapid-fire combat.
	var start: int = 8 if priority else 0
	var end: int = 10 if priority else 8
	for i in range(start, end):
		if not _pool[i].playing:
			_pool[i].stream = stream
			_pool[i].volume_db = -3.0 if priority else -12.0
			_pool[i].pitch_scale = 1.0 if priority else randf_range(0.96, 1.04)
			_pool[i].play()
			return true
	if priority:
		_pool[8].stop()
		_pool[8].stream = stream
		_pool[8].play()
	return priority

func play_dialogue(id: String, seconds: float = 2.5, force: bool = false) -> bool:
	if not AudioCatalog.DIALOGUE.has(id) or (dialogue_locked and not force):
		return false
	if not force and (_clock - float(_dialogue_last.get(id, -100.0)) < 10.0 or _clock - _last_bark < 2.0):
		return false
	_dialogue_last[id] = _clock
	_last_bark = _clock
	dialogue_id = id
	dialogue_remaining = maxf(0.1, seconds)
	duck_db = -5.0
	voice.stop()
	voice.stream = _optional("res://audio/dialogue/%s.ogg" % id)
	if voice.stream != null:
		voice.play()
	subtitle_changed.emit(AudioCatalog.DIALOGUE[id], dialogue_remaining)
	dialogue_started.emit(id)
	return true

func cancel_dialogue() -> void:
	voice.stop()
	dialogue_remaining = 0.0
	dialogue_id = ""
	duck_db = 0.0
	music.volume_db = _music_gain
	subtitle_changed.emit("", 0.0)

func set_engine_running(value: bool) -> void:
	if not value:
		engine.stop()
	elif not engine.playing:
		engine.stream = _optional("res://audio/sfx/boss/engine_loop.ogg", true)
		if engine.stream != null:
			engine.play()

func _process(delta: float) -> void:
	_clock += delta
	_music_gain = move_toward(_music_gain, -12.0, delta * 60.0)
	music.volume_db = _music_gain + duck_db
	if dialogue_remaining > 0:
		dialogue_remaining = maxf(0.0, dialogue_remaining - delta)
		if dialogue_remaining == 0:
			cancel_dialogue()
	if _warning_music_left > 0:
		_warning_music_left = maxf(0.0, _warning_music_left - delta)
		if _warning_music_left == 0 and music_id == "thekedaar_warning":
			play_music("preparation_theme")

func boss_warning() -> void:
	play_music("thekedaar_warning")
	_warning_music_left = 3.0
	play_dialogue("thekedaar_warning", 2.5, true)

func setup(main: Node) -> void:
	_main = main
	var loop: JugaadLoop = main.get_node("JugaadLoop")
	loop.item_action.connect(func(id: StringName) -> void: play_sfx(String(id)))
	loop.weapon_crafted.connect(_on_crafted)
	loop.weapon_placed.connect(func(_w: JugaadWeapon) -> void: play_sfx("place_jugaad"))
	loop.weapon_picked_up.connect(func(_w: JugaadWeapon) -> void: play_sfx("pickup"))
	loop.weapons.child_entered_tree.connect(_register_weapon)
	main.get_node("Player").hit.connect(func(_direction: Vector2) -> void: play_sfx("player_hit"))
	main.get_node("Enemies").child_entered_tree.connect(_register_enemy)
	var shop: Node = main.get_node("Kabadiwala")
	shop.availability_changed.connect(func(open: bool) -> void:
		if open:
			play_sfx("shop_open")
			play_dialogue("kabadiwala_arrival")
	)
	shop.purchased.connect(func(_kind: int, _item: JunkComponent, _cost: int) -> void: play_sfx("purchase"))
	shop.feedback.connect(_shop_feedback)
	var upgrades: UpgradeSystem = main.get_node("UpgradeSystem")
	upgrades.feedback.connect(_shop_feedback)
	upgrades.mod_purchased.connect(func(_id: StringName, _cost: int) -> void: play_sfx("purchase"))
	upgrades.patch_purchased.connect(func(_hp: int, _cost: int) -> void: play_sfx("workshop_patch"))
	main.get_node("Workshop").health_changed.connect(_on_workshop_hp)
	main.get_node("Workshop").destroyed.connect(func() -> void: play_sfx("workshop_destroyed", true))
	var waves: WaveDirector = main.get_node("WaveDirector")
	waves.state_changed.connect(_on_phase)
	waves.announcement.connect(_on_announcement)
	subtitle_changed.connect(main.get_node("HUD").show_subtitle)
	play_dialogue("start_workshop_bachao", 3.0, true)

func _on_phase(state: WaveDirector.State, _wave: int) -> void:
	var waves: WaveDirector = _main.get_node("WaveDirector")
	match state:
		WaveDirector.State.PREPARATION:
			play_music("preparation_theme")
		WaveDirector.State.COMBAT:
			play_music("thekedaar_theme" if waves.boss_combat else "combat_theme")
			play_sfx("countdown_go", true)
		WaveDirector.State.WAVE_CLEAR:
			play_music("wave_clear")
			play_sfx("wave_clear")
			play_dialogue("wave_clear")
		WaveDirector.State.VICTORY:
			play_music("victory")
		WaveDirector.State.DEFEAT:
			cancel_dialogue()
			set_engine_running(false)
			play_music("defeat")

func _on_announcement(text: String, _seconds: float) -> void:
	if text.contains("INCOMING"):
		play_sfx("countdown_tick", true)
	elif text.contains("NAYA RAASTA"):
		play_sfx("route_open", true)

func _shop_feedback(text: String) -> void:
	if text.contains("SCRAP KAM"):
		play_sfx("purchase_fail")
		play_dialogue("scrap_kam_hai")
	elif text.begins_with("One ") or text.contains("already full") or text.contains("SOLD") or text.begins_with("Clear some space"):
		play_sfx("purchase_fail")

func _on_crafted(weapon: JugaadWeapon) -> void:
	_register_weapon(weapon)
	play_sfx("combine_success")
	if not _first_craft:
		_first_craft = true
		play_dialogue("first_jugaad", 2.5, true)

func _register_weapon(child: Node) -> void:
	var weapon: JugaadWeapon = child as JugaadWeapon
	if weapon == null or weapon.has_meta("audio_registered"):
		return
	weapon.set_meta("audio_registered", true)
	weapon.fired.connect(func() -> void: play_sfx("weapons/" + AudioCatalog.WEAPON_SOUNDS[weapon.kind]))
	weapon.repair_hit.connect(func(_progress: int, _required: int) -> void: play_sfx("repair_thak"))
	weapon.repaired.connect(func() -> void: play_sfx("repair_complete"))
	weapon.jammed_changed.connect(func(jammed: bool) -> void:
		if jammed:
			play_sfx("jammed")
			play_dialogue("jugaad_jammed")
	)
	weapon.instability_changed.connect(func(value: float, maximum: float) -> void:
		var warning: bool = value >= maximum * 0.8
		if warning and not weapon.get_meta("audio_warning", false):
			play_sfx("jam_warning")
		weapon.set_meta("audio_warning", warning)
	)

func _register_enemy(child: Node) -> void:
	var enemy: Gunda = child as Gunda
	if enemy == null or enemy is BossPart:
		return
	enemy.health_changed.connect(func(_hp: int, _max: int) -> void: play_sfx("enemies/enemy_hit"))
	enemy.died.connect(func() -> void: play_sfx("enemies/enemy_death"))
	enemy.attacked.connect(func() -> void:
		if enemy.name.contains("Chotu"):
			play_sfx("enemies/chotu_attack")
		elif enemy.name.contains("Pehelwan"):
			play_sfx("enemies/pehelwan_attack")
	)

func _on_workshop_hp(hp: int, maximum: int) -> void:
	if hp < _last_hp:
		play_sfx("workshop_hit", true)
	_last_hp = hp
	var critical: bool = hp > 0 and hp <= maximum * 0.25
	if critical and not _critical:
		play_sfx("workshop_critical", true)
		play_dialogue("workshop_critical", 2.5, true)
	_critical = critical

func debug_audio(id: String) -> void:
	if not OS.is_debug_build():
		return
	if id in AudioCatalog.MUSIC:
		play_music(id)
	elif AudioCatalog.DIALOGUE.has(id):
		play_dialogue(id, 2.5, true)
	else:
		play_sfx(id, true)
