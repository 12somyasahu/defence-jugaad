class_name JugaadPresentation
extends Node2D

@onready var jam_warning: Node2D = $JamWarning
var _weapon: JugaadWeapon
var _punch_tween: Tween

func _ready() -> void:
	_weapon = get_parent() as JugaadWeapon
	if jam_warning:
		jam_warning.hide()

	if _weapon:
		_weapon.jammed_changed.connect(_on_jammed_changed)
		_weapon.repair_hit.connect(_on_repair_hit)
		_weapon.repaired.connect(_on_repaired)
		_weapon.instability_changed.connect(_on_instability_changed)

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

	var maint_label: Label = _weapon.get_node_or_null("Maintenance") as Label
	if maint_label:
		maint_label.text = "THAK! [%d/%d]" % [progress, required]
		maint_label.modulate = Color(1.0, 0.85, 0.2, 1.0)

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

	var maint_label: Label = _weapon.get_node_or_null("Maintenance") as Label
	if maint_label:
		maint_label.text = "REPAIRED!"
		maint_label.modulate = Color(0.4, 1.0, 0.4, 1.0)

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
