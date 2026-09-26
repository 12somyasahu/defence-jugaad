class_name BossPart
extends Gunda

signal destroyed(part_id: StringName)
var part_id: StringName = &"chassis"
var tint: Color = Color.SANDY_BROWN

func _ready() -> void:
	z_index = 2
	scrap_reward = 0
	knockback_multiplier = 0.0
	current_hp = maximum_hp
	add_to_group("boss_part")
	collision_layer = 4
	collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 28.0 if part_id == &"chassis" else 18.0
	shape.shape = circle
	add_child(shape)
	var label: Label = Label.new()
	label.position = Vector2(-60, 24)
	label.size.x = 120
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.text = String(part_id).to_upper()
	add_child(label)
	var component: int = 3 if part_id == &"speaker" else (0 if part_id == &"battery" else -1)
	if component >= 0:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = JunkComponent.TEXTURES[component]
		sprite.scale = Vector2.ONE * 42.0 / maxf(sprite.texture.get_width(), sprite.texture.get_height())
		add_child(sprite)

func _physics_process(_delta: float) -> void:
	pass # Vehicle positions all parts; they never navigate or attack independently.

func receive_damage(amount: int) -> void:
	if not active or current_hp <= 0 or amount <= 0:
		return
	current_hp = maxi(0, current_hp - amount)
	health_changed.emit(current_hp, maximum_hp)
	queue_redraw()
	if current_hp == 0:
		active = false
		collision_layer = 0
		modulate = Color(0.3, 0.3, 0.3)
		destroyed.emit(part_id)
		died.emit()

func apply_knockback(_impulse: Vector2) -> void:
	pass

func _draw() -> void:
	# Presentation only: a light target ring so the Tempo art underneath stays visible.
	var radius: float = 27.0 if part_id == &"chassis" else 19.0
	draw_circle(Vector2.ZERO, radius, Color(tint, 0.0 if part_id == &"chassis" else 0.22))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0, 0, 0, 0.6), 4.0)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(tint, 0.9), 2.0)
	if part_id == &"engine":
		draw_line(Vector2(-8, -7), Vector2(8, 7), Color.ORANGE, 4)
