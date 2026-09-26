class_name AttackRoute
extends Node2D

# One edge entry point. WaveDirector activates routes; the arena stage decides where the edge is.
@export var route_name: String = "EAST"
@export var direction: Vector2 = Vector2.RIGHT
@export_range(10.0, 200.0) var edge_inset: float = 40.0
@export_range(0.0, 300.0) var lane_spread: float = 90.0
var active: bool = false
# Temporary event state (RASTA BAND); independent of wave progression's `active`.
var blocked: bool = false
var _lane: int = 0

func _ready() -> void:
	direction = direction.normalized()
	$Label.text = "GUNDAS FROM " + route_name
	set_active(false)

func place_on(bounds: Rect2) -> void:
	var half: Vector2 = bounds.size * 0.5
	global_position = bounds.get_center() + direction * (absf(direction.x) * half.x + absf(direction.y) * half.y - edge_inset)
	var label_size: Vector2 = $Label.size
	if absf(direction.x) > absf(direction.y):
		# East/West: label on the arena side of the arrow.
		$Label.position = -direction * (44.0 + label_size.x * 0.5) - label_size * 0.5
	else:
		# North/South: label beside the lane so it stays clear of the HUD's centred hand slots.
		$Label.position = Vector2(lane_spread + 110.0, -direction.y * 14.0 - label_size.y * 0.5)
	queue_redraw()

func set_active(value: bool) -> void:
	active = value
	visible = value
	if value:
		modulate = Color(1.6, 1.6, 1.6)
		create_tween().tween_property(self, "modulate", Color.WHITE, 1.2)

func set_blocked(value: bool) -> void:
	blocked = value
	$Label.text = ("RASTA BAND: " if blocked else "GUNDAS FROM ") + route_name
	queue_redraw()

func next_spawn_position() -> Vector2:
	# Three deterministic lanes along the edge, like the M1 east spawner.
	var lateral: Vector2 = direction.orthogonal()
	var at: Vector2 = global_position + lateral * float(_lane % 3 - 1) * lane_spread
	_lane += 1
	return at

func _draw() -> void:
	var inward: Vector2 = -direction
	var side: Vector2 = direction.orthogonal() * 18.0
	var tip: Vector2 = inward * 34.0
	var color: Color = Color(0.6, 0.6, 0.6) if blocked else Color(1.0, 0.25, 0.25)

	# Lane boundary threat lines
	draw_line(Vector2.ZERO, direction.orthogonal() * lane_spread, Color(color, 0.45), 3.0)
	draw_line(Vector2.ZERO, -direction.orthogonal() * lane_spread, Color(color, 0.45), 3.0)

	# Primary arrow chevron
	draw_colored_polygon(PackedVector2Array([tip, -side, side]), Color(color, 0.90))
	draw_polyline(PackedVector2Array([-side, tip, side]), Color(1.0, 0.9, 0.4, 0.9), 2.0)

	# Secondary inward chevron
	var tip2: Vector2 = tip + inward * 14.0
	var side2: Vector2 = direction.orthogonal() * 12.0
	draw_polyline(PackedVector2Array([tip + -side2, tip2, tip + side2]), Color(color, 0.75), 2.5)

	if blocked:
		# Barricade across the lane with warning stripes
		var across: Vector2 = direction.orthogonal() * lane_spread
		draw_line(inward * 12.0 - across, inward * 12.0 + across, Color.ORANGE, 8.0)
		draw_line(inward * 12.0 - across * 0.3 + side, inward * 12.0 + across * 0.3 - side, Color.ORANGE, 4.0)
