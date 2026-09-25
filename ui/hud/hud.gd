class_name HUD
extends CanvasLayer

const SLOT_EMPTY = preload("res://assets/ui/hud_slot_empty.png")
const SLOT_ACTIVE = preload("res://assets/ui/hud_slot_active.png")

@onready var health_bar: TextureProgressBar = $MarginContainer/TopPanel/WorkshopHealth/ProgressBar
@onready var workshop_hp_label: Label = $MarginContainer/TopPanel/WorkshopHealth/Label
@onready var wave_label: Label = $MarginContainer/TopPanel/WaveInfo/WaveLabel
@onready var scrap_label: Label = $MarginContainer/TopPanel/WaveInfo/ScrapLabel
@onready var phase_label: Label = $MarginContainer/TopPanel/WaveInfo/PhaseLabel
@onready var announcement_band: ColorRect = $AnnouncementBand
@onready var announcement_label: Label = $Announcement
var _announcement_tween: Tween
var _hp_flash_tween: Tween
var _last_hp: float = -1.0

@onready var left_slot: TextureRect = $MarginContainer/BottomPanel/Hands/LeftHand/SlotBackground
@onready var left_icon: TextureRect = $MarginContainer/BottomPanel/Hands/LeftHand/SlotBackground/ItemIcon
@onready var right_slot: TextureRect = $MarginContainer/BottomPanel/Hands/RightHand/SlotBackground
@onready var right_icon: TextureRect = $MarginContainer/BottomPanel/Hands/RightHand/SlotBackground/ItemIcon
@onready var prompt_label: Label = $MarginContainer/BottomPanel/PromptLabel

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
	if scrap_label:
		scrap_label.visible = value
		_update_info_visibility()

func _update_info_visibility() -> void:
	if wave_label and wave_label.get_parent():
		wave_label.get_parent().visible = wave_label.visible or scrap_label.visible

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
	phase_label.visible = not text.is_empty()

	# Dynamic visual identity per phase
	if text.contains("PREPARE") or text.contains("NEXT WAVE"):
		if text.contains("00:0") and text.substr(text.find("00:0") + 4, 1).to_int() <= 5:
			phase_label.modulate = Color(1.0, 0.7, 0.2, 1.0) # Urgency warning
		else:
			phase_label.modulate = Color(0.4, 0.92, 0.65, 1.0) # Calm green
	elif text.contains("INCOMING"):
		phase_label.modulate = Color(1.0, 0.75, 0.15, 1.0) # Amber countdown
	elif text.contains("ENEMIES REMAINING"):
		phase_label.modulate = Color(0.95, 0.35, 0.25, 1.0) # Danger combat red
	elif text.contains("CLEARED"):
		phase_label.modulate = Color(1.0, 0.88, 0.25, 1.0) # Celebratory gold
	else:
		phase_label.modulate = Color(0.95, 0.77, 0.06, 1.0)

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
		return

	announcement_label.text = text
	announcement_label.modulate = Color.WHITE
	announcement_label.show()
	if announcement_band:
		announcement_band.show()

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

	if seconds > 0.0:
		var fade_delay: float = maxf(0.0, seconds - 0.35)
		_announcement_tween.chain().tween_interval(fade_delay)
		_announcement_tween.chain().tween_property(announcement_label, "modulate:a", 0.0, 0.35)
		if announcement_band:
			_announcement_tween.tween_property(announcement_band, "modulate:a", 0.0, 0.35)
		_announcement_tween.chain().tween_callback(func():
			announcement_label.hide()
			if announcement_band:
				announcement_band.hide()
				announcement_band.modulate.a = 1.0
		)

## Presentation update for Scrap display
func set_scrap(scrap_amount: int) -> void:
	if scrap_label:
		scrap_label.text = "SCRAP: %d" % scrap_amount

## Presentation update for Contextual Prompt
func set_prompt(prompt_text: String) -> void:
	if not prompt_label:
		return
	prompt_label.text = prompt_text
	prompt_label.visible = not prompt_text.is_empty()
	if prompt_text.begins_with("+"):
		prompt_label.modulate = Color(0.4, 0.95, 0.4, 1.0) # Green scrap reward
	elif prompt_text.begins_with("[E]"):
		prompt_label.modulate = Color(1.0, 0.9, 0.4, 1.0) # Gold place prompt
	elif prompt_text.begins_with("[Q]"):
		prompt_label.modulate = Color(0.4, 0.85, 1.0, 1.0) # Cyan combine prompt
	else:
		prompt_label.modulate = Color(1.0, 0.8, 0.6, 1.0)

## End-Game Presentation Panels
func show_victory(total_waves: int, final_scrap: int) -> void:
	if end_game_overlay:
		end_game_overlay.show()
	if defeat_panel:
		defeat_panel.hide()
	if victory_panel:
		if victory_stats:
			victory_stats.text = "All %d Waves Defended Successfully!\nTotal Scrap Collected: %d" % [total_waves, final_scrap]
		victory_panel.show()
		victory_panel.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(victory_panel, "modulate:a", 1.0, 0.5)

func show_defeat(wave: int, final_scrap: int) -> void:
	if end_game_overlay:
		end_game_overlay.show()
	if victory_panel:
		victory_panel.hide()
	if defeat_panel:
		if defeat_stats:
			defeat_stats.text = "Workshop Destroyed on Wave %d.\nScrap Salvaged: %d" % [wave, final_scrap]
		defeat_panel.show()
		defeat_panel.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(defeat_panel, "modulate:a", 1.0, 0.5)
