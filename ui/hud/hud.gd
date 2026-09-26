class_name HUD
extends CanvasLayer

const SLOT_EMPTY = preload("res://assets/ui/hud_slot_empty.png")
const SLOT_ACTIVE = preload("res://assets/ui/hud_slot_active.png")
const TEX_WARNING_PANEL = preload("res://assets/ui/panels/warning_panel.png")
const TEX_NOTIFICATION_PANEL = preload("res://assets/ui/panels/notification_panel.png")

@onready var health_bar: TextureProgressBar = $MarginContainer/TopPanel/WorkshopHealth/ProgressBar
@onready var workshop_hp_label: Label = $MarginContainer/TopPanel/WorkshopHealth/Label
@onready var wave_label: Label = $MarginContainer/TopPanel/WaveInfo/WaveLabel
@onready var scrap_container: HBoxContainer = $MarginContainer/TopPanel/WaveInfo/ScrapContainer
@onready var scrap_label: Label = $MarginContainer/TopPanel/WaveInfo/ScrapContainer/ScrapLabel
@onready var phase_container: HBoxContainer = $MarginContainer/TopPanel/WaveInfo/PhaseContainer
@onready var watch_icon: TextureRect = $MarginContainer/TopPanel/WaveInfo/PhaseContainer/WatchIcon
@onready var phase_label: Label = $MarginContainer/TopPanel/WaveInfo/PhaseContainer/PhaseLabel
@onready var mods_label: Label = $MarginContainer/TopPanel/WaveInfo/ModsLabel
@onready var announcement_band: ColorRect = $CinematicOverlay/AnnouncementBand
@onready var announcement_frame: TextureRect = $CinematicOverlay.get_node_or_null("AnnouncementFrame")
@onready var announcement_label: Label = $CinematicOverlay/Announcement
var _announcement_tween: Tween
var _hp_flash_tween: Tween
var _last_hp: float = -1.0
var _pulse_time: float = 0.0
var _urgent: bool = false
var _low_hp: bool = false

func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse: float = 0.78 + 0.22 * sin(_pulse_time * 8.0)
	if phase_label:
		phase_label.modulate.a = pulse if _urgent else 1.0
	if watch_icon and _urgent:
		watch_icon.modulate.a = pulse
	elif watch_icon:
		watch_icon.modulate.a = 1.0
	if workshop_hp_label:
		workshop_hp_label.modulate.a = pulse if _low_hp else 1.0

@onready var left_slot: TextureRect = $MarginContainer/BottomPanel/Hands/LeftHand/SlotBackground
@onready var left_icon: TextureRect = $MarginContainer/BottomPanel/Hands/LeftHand/SlotBackground/ItemIcon
@onready var right_slot: TextureRect = $MarginContainer/BottomPanel/Hands/RightHand/SlotBackground
@onready var right_icon: TextureRect = $MarginContainer/BottomPanel/Hands/RightHand/SlotBackground/ItemIcon
@onready var prompt_container: HBoxContainer = $MarginContainer/BottomPanel/PromptContainer
@onready var keycap_rect: TextureRect = $MarginContainer/BottomPanel/PromptContainer/Keycap
@onready var keycap_label: Label = $MarginContainer/BottomPanel/PromptContainer/Keycap/KeyLabel
@onready var prompt_label: Label = $MarginContainer/BottomPanel/PromptContainer/PromptLabel

@onready var end_game_overlay: Control = $EndGameOverlay
@onready var victory_panel: PanelContainer = $EndGameOverlay/VictoryPanel
@onready var defeat_panel: PanelContainer = $EndGameOverlay/DefeatPanel
@onready var victory_stats: Label = $EndGameOverlay/VictoryPanel/VBox/Stats
@onready var defeat_stats: Label = $EndGameOverlay/DefeatPanel/VBox/Stats

func _ready() -> void:
	if health_bar:
		update_workshop_hp(health_bar.value, health_bar.max_value)
	update_hand_slot(left_slot, left_icon, null)
	update_hand_slot(right_slot, right_icon, null)
	if announcement_band:
		announcement_band.hide()
	if announcement_frame:
		announcement_frame.hide()
	if end_game_overlay:
		end_game_overlay.hide()
	if victory_panel:
		victory_panel.hide()
	if defeat_panel:
		defeat_panel.hide()

## Presentation update for Workshop Health bar
func update_workshop_hp(current_hp: float, max_hp: float = 100.0) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
		var ratio: float = current_hp / maxf(1.0, max_hp)
		_low_hp = ratio > 0.0 and ratio <= 0.25
		# Tint progress bar by ratio: green / amber / red
		if ratio > 0.60:
			health_bar.tint_progress = Color(0.3, 0.85, 0.3, 1.0)
		elif ratio > 0.25:
			health_bar.tint_progress = Color(0.95, 0.75, 0.1, 1.0)
		else:
			health_bar.tint_progress = Color(0.95, 0.25, 0.2, 1.0)

		# Damage flash on reduction
		if _last_hp > 0 and current_hp < _last_hp:
			if _hp_flash_tween != null:
				_hp_flash_tween.kill()
			health_bar.modulate = Color(2.0, 1.5, 1.5, 1.0)
			_hp_flash_tween = create_tween()
			_hp_flash_tween.tween_property(health_bar, "modulate", Color.WHITE, 0.25)
		_last_hp = current_hp

	if workshop_hp_label:
		workshop_hp_label.text = "WORKSHOP HP  %d / %d" % [current_hp, max_hp]
		var ratio: float = current_hp / maxf(1.0, max_hp)
		if ratio <= 0.25 and ratio > 0.0:
			workshop_hp_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		else:
			workshop_hp_label.modulate = Color(0.95, 0.77, 0.06, 1.0)

## Presentation update for Left Hand slot. item_name is optional caption text.
func set_left_hand_item(item_texture: Texture2D = null, item_name: String = "") -> void:
	update_hand_slot(left_slot, left_icon, item_texture)
	_set_hand_caption(left_slot, "LEFT [1]", item_name)

## Presentation update for Right Hand slot. item_name is optional caption text.
func set_right_hand_item(item_texture: Texture2D = null, item_name: String = "") -> void:
	update_hand_slot(right_slot, right_icon, item_texture)
	_set_hand_caption(right_slot, "RIGHT [2]", item_name)

func _set_hand_caption(slot_rect: TextureRect, hand: String, item_name: String) -> void:
	var caption: Label = slot_rect.get_parent().get_node_or_null("Label") if slot_rect else null
	if caption:
		caption.text = hand + ("\n" + item_name if not item_name.is_empty() else "\nempty")

## Wave and Scrap visibility are independent: economy can exist before waves.
func set_wave_info_visible(value: bool) -> void:
	if wave_label:
		wave_label.visible = value
		_update_info_visibility()

func set_scrap_visible(value: bool) -> void:
	if scrap_container:
		scrap_container.visible = value
	elif scrap_label:
		scrap_label.visible = value
	_update_info_visibility()

func _update_info_visibility() -> void:
	if wave_label and wave_label.get_parent():
		var scrap_vis: bool = scrap_container.visible if scrap_container else (scrap_label.visible if scrap_label else false)
		wave_label.get_parent().visible = wave_label.visible or scrap_vis

## Helper to switch slot texture between empty and active
func update_hand_slot(slot_rect: TextureRect, icon_rect: TextureRect, item_texture: Texture2D) -> void:
	if not slot_rect:
		return
	if item_texture != null:
		slot_rect.texture = SLOT_ACTIVE
		if icon_rect:
			icon_rect.texture = item_texture
			icon_rect.visible = true
	else:
		slot_rect.texture = SLOT_EMPTY
		if icon_rect:
			icon_rect.texture = null
			icon_rect.visible = false

## Presentation update for Wave display. total_waves <= 0 shows just the number.
func set_wave(wave_number: int, total_waves: int = 0) -> void:
	if wave_label:
		wave_label.text = "WAVE %d/%d" % [wave_number, total_waves] if total_waves > 0 else "WAVE %d" % wave_number

## Presentation update for the wave phase line (enemies left, shop, timers). Empty hides it.
func set_wave_status(text: String) -> void:
	if not phase_label:
		return
	phase_label.text = text
	var is_vis: bool = not text.is_empty()
	if phase_container:
		phase_container.visible = is_vis
	phase_label.visible = is_vis
	_urgent = false

	var is_prep_or_countdown: bool = text.contains("PREPARE") or text.contains("NEXT WAVE") or text.contains("INCOMING")
	if watch_icon:
		watch_icon.visible = is_vis and is_prep_or_countdown

	# Dynamic visual identity per phase
	if text.contains("PREPARE") or text.contains("NEXT WAVE"):
		if text.contains("00:0") and text.substr(text.find("00:0") + 4, 1).to_int() < 5:
			_urgent = true
			phase_label.modulate = Color("ffbb33")
		else:
			phase_label.modulate = Color("55ff99")
	elif text.contains("INCOMING"):
		phase_label.modulate = Color("ffbb33")
	elif text.contains("ENEMIES REMAINING") or text.contains("COMBAT"):
		phase_label.modulate = Color("ff4444")
	elif text.contains("CLEARED"):
		phase_label.modulate = Color("ffd700")
	else:
		phase_label.modulate = Color(0.95, 0.77, 0.06, 1.0)

## Prototype owned-mod strip ("MODS: A | B"). Empty list hides it.
func set_owned_mods(mod_names: Array[String]) -> void:
	if mods_label:
		mods_label.text = "MODS: " + " | ".join(mod_names)
		mods_label.visible = not mod_names.is_empty()

## Big centred banner (countdown, expansion, victory). seconds <= 0 keeps it until replaced.
func show_announcement(text: String, seconds: float = 2.0) -> void:
	if not announcement_label:
		return
	if _announcement_tween != null:
		_announcement_tween.kill()

	if text.is_empty():
		announcement_label.hide()
		if announcement_band:
			announcement_band.hide()
		if announcement_frame:
			announcement_frame.hide()
		return

	announcement_label.text = text
	announcement_label.modulate = Color.WHITE
	announcement_label.show()
	if announcement_band:
		announcement_band.modulate.a = 1.0
		announcement_band.show()

	if announcement_frame:
		var is_warning: bool = text.contains("INCOMING") or text.contains("AAYE GUNDE") or text.contains("NAYA RAASTA") or text.contains("HAFTA")
		announcement_frame.texture = TEX_WARNING_PANEL if is_warning else TEX_NOTIFICATION_PANEL
		announcement_frame.pivot_offset = announcement_frame.size * 0.5
		announcement_frame.scale = Vector2(1.2, 1.2)
		announcement_frame.modulate.a = 1.0
		announcement_frame.show()

	# Dramatic entrance punch / scale animation
	announcement_label.pivot_offset = announcement_label.size * 0.5
	announcement_label.scale = Vector2(1.2, 1.2)

	# Dynamic color theme for announcement
	if text.contains("AAYE GUNDE"):
		announcement_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
	elif text.contains("INCOMING") or (text.length() <= 2 and text.is_valid_int()):
		announcement_label.modulate = Color(1.0, 0.75, 0.15, 1.0)
	elif text.contains("CLEARED") or text.contains("VICTORY") or text.contains("DEFENDED"):
		announcement_label.modulate = Color(1.0, 0.88, 0.25, 1.0)
	elif text.contains("EXPANDED") or text.contains("NAYA RAASTA"):
		announcement_label.modulate = Color(0.3, 0.9, 1.0, 1.0)

	_announcement_tween = create_tween()
	_announcement_tween.set_parallel(true)
	_announcement_tween.tween_property(announcement_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if announcement_frame:
		_announcement_tween.tween_property(announcement_frame, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if seconds > 0.0:
		var fade_delay: float = maxf(0.0, seconds - 0.35)
		_announcement_tween.chain().tween_interval(fade_delay)
		_announcement_tween.chain().tween_property(announcement_label, "modulate:a", 0.0, 0.35)
		if announcement_band:
			_announcement_tween.tween_property(announcement_band, "modulate:a", 0.0, 0.35)
		if announcement_frame:
			_announcement_tween.tween_property(announcement_frame, "modulate:a", 0.0, 0.35)
		_announcement_tween.chain().tween_callback(func():
			announcement_label.hide()
			if announcement_band:
				announcement_band.hide()
				announcement_band.modulate.a = 1.0
			if announcement_frame:
				announcement_frame.hide()
				announcement_frame.modulate.a = 1.0
		)

## Presentation update for Scrap display
func set_scrap(scrap_amount: int) -> void:
	if scrap_label:
		scrap_label.text = "SCRAP: %d" % scrap_amount

## Presentation update for Contextual Prompt
func set_prompt(prompt_text: String) -> void:
	if not prompt_container or not prompt_label:
		return
	if prompt_text.is_empty():
		prompt_container.visible = false
		return
	prompt_container.visible = true

	# Check for key prompt format "[KEY] ACTION" or "[ KEY - ACTION ]"
	if prompt_text.begins_with("[") and prompt_text.contains("]"):
		var close_bracket: int = prompt_text.find("]")
		var key_str: String = prompt_text.substr(1, close_bracket - 1).strip_edges()
		var action_str: String = prompt_text.substr(close_bracket + 1).strip_edges()
		if action_str.begins_with("-"):
			action_str = action_str.substr(1).strip_edges()
		if key_str.length() <= 3 and not action_str.is_empty():
			if keycap_rect and keycap_label:
				keycap_rect.visible = true
				keycap_label.text = key_str
			prompt_label.text = action_str
		else:
			if keycap_rect:
				keycap_rect.visible = false
			prompt_label.text = prompt_text
	else:
		if keycap_rect:
			keycap_rect.visible = false
		prompt_label.text = prompt_text

	if prompt_text.begins_with("+"):
		prompt_label.modulate = Color(0.4, 0.95, 0.4, 1.0) # Green scrap reward
	elif prompt_text.contains("[E]") or prompt_text.begins_with("E") or (keycap_rect and keycap_rect.visible and keycap_label.text == "E"):
		prompt_label.modulate = Color(1.0, 0.9, 0.4, 1.0) # Gold place prompt
	elif prompt_text.contains("[Q]") or prompt_text.begins_with("Q") or (keycap_rect and keycap_rect.visible and keycap_label.text == "Q"):
		prompt_label.modulate = Color(0.4, 0.85, 1.0, 1.0) # Cyan combine prompt
	else:
		prompt_label.modulate = Color(1.0, 0.8, 0.6, 1.0)

## End-Game Presentation Panels
func show_victory(total_waves: int, final_scrap: int, stats: Dictionary = {}) -> void:
	if end_game_overlay:
		end_game_overlay.show()
	if defeat_panel:
		defeat_panel.hide()
	if victory_panel:
		if victory_stats:
			victory_stats.text = "All %d Waves Defended Successfully!\nTotal Scrap Collected: %d" % [total_waves, final_scrap]
			if not stats.is_empty():
				victory_stats.text = "Waves: %d + THEKEDAAR\n%s" % [stats.waves, _stats_text(stats)]
		victory_panel.show()
		victory_panel.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(victory_panel, "modulate:a", 1.0, 0.5)

func show_defeat(wave: int, final_scrap: int, stats: Dictionary = {}, boss_reached: bool = false) -> void:
	if end_game_overlay:
		end_game_overlay.show()
	if victory_panel:
		victory_panel.hide()
	if defeat_panel:
		if defeat_stats:
			defeat_stats.text = "Workshop Destroyed on Wave %d.\nScrap Salvaged: %d" % [wave, final_scrap]
			if not stats.is_empty():
				defeat_stats.text = "Wave Reached: %s\n%s" % ["THEKEDAAR" if boss_reached else str(wave), _stats_text(stats)]
		defeat_panel.show()
		defeat_panel.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(defeat_panel, "modulate:a", 1.0, 0.5)

func _stats_text(stats: Dictionary) -> String:
	return "Enemies Thoked: %d\nJugaads Built: %d\nScrap Collected: %d\nTHOKs: %d" % [stats.kills, stats.built, stats.scrap, stats.thoks]

func update_boss(hp: int, maximum: int, speaker: bool, battery: bool, engine: bool) -> void:
	$BossPanel.show()
	$BossPanel/VBox/Health.max_value = maximum
	$BossPanel/VBox/Health.value = hp
	$BossPanel/VBox/Modules.text = "SPEAKER: %s\nBATTERY: %s\nENGINE: %s" % ["ACTIVE" if speaker else "DESTROYED", "ACTIVE" if battery else "DESTROYED", "ACTIVE" if engine else "DESTROYED"]

func hide_boss() -> void:
	$BossPanel.hide()

func show_subtitle(text: String, _seconds: float) -> void:
	$CinematicOverlay/Subtitle.text = text
	$CinematicOverlay/Subtitle.visible = not text.is_empty()
