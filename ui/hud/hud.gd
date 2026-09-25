class_name HUD
extends CanvasLayer

const SLOT_EMPTY = preload("res://assets/ui/hud_slot_empty.png")
const SLOT_ACTIVE = preload("res://assets/ui/hud_slot_active.png")

@onready var health_bar: TextureProgressBar = $MarginContainer/TopPanel/WorkshopHealth/ProgressBar
@onready var workshop_hp_label: Label = $MarginContainer/TopPanel/WorkshopHealth/Label
@onready var wave_label: Label = $MarginContainer/TopPanel/WaveInfo/WaveLabel
@onready var scrap_label: Label = $MarginContainer/TopPanel/WaveInfo/ScrapLabel

@onready var left_slot: TextureRect = $MarginContainer/BottomPanel/Hands/LeftHand/SlotBackground
@onready var left_icon: TextureRect = $MarginContainer/BottomPanel/Hands/LeftHand/SlotBackground/ItemIcon
@onready var right_slot: TextureRect = $MarginContainer/BottomPanel/Hands/RightHand/SlotBackground
@onready var right_icon: TextureRect = $MarginContainer/BottomPanel/Hands/RightHand/SlotBackground/ItemIcon
@onready var prompt_label: Label = $MarginContainer/BottomPanel/PromptLabel

func _ready() -> void:
	# Ensure default presentation state is initialized
	if health_bar:
		update_workshop_hp(health_bar.value, health_bar.max_value)
	update_hand_slot(left_slot, left_icon, null)
	update_hand_slot(right_slot, right_icon, null)

## Presentation update for Workshop Health bar
func update_workshop_hp(current_hp: float, max_hp: float = 100.0) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp

## Presentation update for Left Hand slot
func set_left_hand_item(item_texture: Texture2D = null) -> void:
	update_hand_slot(left_slot, left_icon, item_texture)

## Presentation update for Right Hand slot
func set_right_hand_item(item_texture: Texture2D = null) -> void:
	update_hand_slot(right_slot, right_icon, item_texture)

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

## Presentation update for Wave display
func set_wave(wave_number: int) -> void:
	if wave_label:
		wave_label.text = "WAVE %d" % wave_number

## Presentation update for Scrap display
func set_scrap(scrap_amount: int) -> void:
	if scrap_label:
		scrap_label.text = "SCRAP: %d" % scrap_amount

## Presentation update for Contextual Prompt
func set_prompt(prompt_text: String) -> void:
	if prompt_label:
		prompt_label.text = prompt_text
		prompt_label.visible = not prompt_text.is_empty()
