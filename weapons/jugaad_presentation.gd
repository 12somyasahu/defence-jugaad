class_name JugaadPresentation
extends Node2D

const STATUS_ICONS: Dictionary = {
	"active": preload("res://assets/ui/status/active.png"),
	"damaged": preload("res://assets/ui/status/damaged.png"),
	"needs_repair": preload("res://assets/ui/status/needs_repair.png"),
	"disabled": preload("res://assets/ui/status/disabled.png"),
	"destroyed": preload("res://assets/ui/status/destroyed.png"),
}

@onready var jam_warning: Node2D = $JamWarning
var _weapon: JugaadWeapon
var _punch_tween: Tween
var _repair_feedback: Label
var _feedback_remaining: float = 0.0
var _status_marker: Sprite2D

func _process(delta: float) -> void:
	_feedback_remaining = maxf(0.0, _feedback_remaining - delta)
	_repair_feedback.visible = _feedback_remaining > 0.0

func _show_repair_feedback(text: String, tint: Color) -> void:
	_repair_feedback.text = text
	_repair_feedback.modulate = tint
	_feedback_remaining = 0.8
	_repair_feedback.show()

func _ready() -> void:
	_weapon = get_parent() as JugaadWeapon
	# Separate transient feedback from the authoritative maintenance status label.
	_repair_feedback = Label.new()
	_repair_feedback.name = "RepairFeedback"
	_repair_feedback.position = Vector2(-75, -65)
	_repair_feedback.size.x = 150
	_repair_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_repair_feedback.add_theme_font_size_override("font_size", 14)
	_repair_feedback.add_theme_color_override("font_outline_color", Color.BLACK)
	_repair_feedback.add_theme_constant_override("outline_size", 4)
	add_child(_repair_feedback)
	_repair_feedback.hide()

	_status_marker = Sprite2D.new()
	_status_marker.name = "StatusMarker"
	_status_marker.position = Vector2(0, -38)
	_status_marker.scale = Vector2(0.18, 0.18)
	_status_marker.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_status_marker)
	_status_marker.hide()

	if jam_warning:
		jam_warning.hide()

	if _weapon:
		_weapon.jammed_changed.connect(_on_jammed_changed)
		_weapon.repair_hit.connect(_on_repair_hit)
		_weapon.repaired.connect(_on_repaired)
		_weapon.instability_changed.connect(_on_instability_changed)
		_weapon.placed.connect(_update_status_display)
		_weapon.picked_up.connect(_update_status_display)
		_weapon.power_changed.connect(func(_p: bool) -> void: _update_status_display())
		_update_status_display()

func _update_status_display() -> void:
	if not is_instance_valid(_weapon) or not _weapon.is_placed:
		if _status_marker:
			_status_marker.hide()
		return
	if not _status_marker:
		return

	var tex: Texture2D = null
	if _weapon.jammed:
		tex = STATUS_ICONS["needs_repair"]
	elif _weapon.power_cut:
		tex = STATUS_ICONS["disabled"]
	elif _weapon.instability >= _weapon.maximum_instability * 0.5:
		tex = STATUS_ICONS["damaged"]
	else:
		tex = STATUS_ICONS["active"]

	_status_marker.texture = tex
	_status_marker.show()

func _on_jammed_changed(is_jammed: bool) -> void:
	if not jam_warning:
		return
	if is_jammed:
		jam_warning.show()
		var particles: CPUParticles2D = jam_warning.get_node_or_null("SmokeParticles") as CPUParticles2D
		if particles:
			particles.emitting = true
		# Pulse warning
		if _punch_tween != null:
			_punch_tween.kill()
		jam_warning.scale = Vector2(1.3, 1.3)
		_punch_tween = create_tween()
		_punch_tween.tween_property(jam_warning, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		jam_warning.hide()
		var particles: CPUParticles2D = jam_warning.get_node_or_null("SmokeParticles") as CPUParticles2D
		if particles:
			particles.emitting = false
	_update_status_display()

func _on_repair_hit(progress: int, required: int) -> void:
	if not is_instance_valid(_weapon):
		return
	var sprite: Sprite2D = _weapon.get_node_or_null("Sprite") as Sprite2D
	if sprite:
		if _punch_tween != null:
			_punch_tween.kill()
		sprite.modulate = Color(2.5, 2.0, 0.5, 1.0)
		_punch_tween = create_tween()
		_punch_tween.set_parallel(true)
		_punch_tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
		_punch_tween.tween_property(sprite, "scale", sprite.scale * 1.15, 0.08).set_trans(Tween.TRANS_QUAD)
		_punch_tween.chain().tween_property(sprite, "scale", sprite.scale, 0.12)

	_show_repair_feedback("THAK! [%d/%d]" % [progress, required], Color.GOLD)

func _on_repaired() -> void:
	if not is_instance_valid(_weapon):
		return
	if jam_warning:
		jam_warning.hide()
	var sprite: Sprite2D = _weapon.get_node_or_null("Sprite") as Sprite2D
	if sprite:
		if _punch_tween != null:
			_punch_tween.kill()
		sprite.modulate = Color(0.5, 2.5, 0.5, 1.0)
		_punch_tween = create_tween()
		_punch_tween.tween_property(sprite, "modulate", Color.WHITE, 0.35)

	_show_repair_feedback("REPAIRED!", Color.LIGHT_GREEN)
	_update_status_display()

func _on_instability_changed(current: float, maximum: float) -> void:
	if not is_instance_valid(_weapon) or _weapon.jammed:
		return
	var ratio: float = current / maxf(1.0, maximum)
	var maint_label: Label = _weapon.get_node_or_null("Maintenance") as Label
	if maint_label:
		if ratio >= 0.8:
			maint_label.modulate = Color(1.0, 0.3, 0.2, 1.0) # Danger high heat
		elif ratio >= 0.5:
			maint_label.modulate = Color(1.0, 0.75, 0.2, 1.0) # Warm warning
		else:
			maint_label.modulate = Color(0.8, 0.8, 0.8, 1.0) # Normal
	_update_status_display()
