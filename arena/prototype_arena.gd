class_name PrototypeArena
extends Node2D

# Staged combat footprint: the same map grows outward; nothing is regenerated.
signal bounds_changed(bounds: Rect2)

# Stage 0 is the M0-M4 arena. Each zoom keeps the whole stage visible at 1152x648.
const STAGES: Array[Dictionary] = [
	{"bounds": Rect2(-540, -290, 1080, 580), "zoom": 1.0},
	{"bounds": Rect2(-660, -360, 1320, 720), "zoom": 0.86},
	{"bounds": Rect2(-780, -430, 1560, 860), "zoom": 0.73},
]
const WALL_THICKNESS: float = 20.0
const CAMERA_SECONDS: float = 1.6
var stage: int = 0
var bounds: Rect2 = STAGES[0].bounds
var camera: Camera2D
var _camera_tween: Tween

func _ready() -> void:
	# Own copies so resizing never leaks into another instance of this scene.
	for wall in $Walls.get_children():
		wall.shape = wall.shape.duplicate()
	_apply_bounds()

func set_stage(index: int, animate: bool = true) -> void:
	index = clampi(index, 0, STAGES.size() - 1)
	if index == stage and bounds == STAGES[index].bounds:
		return
	stage = index
	bounds = STAGES[index].bounds
	_apply_bounds()
	if is_instance_valid(camera):
		var zoom: Vector2 = Vector2.ONE * float(STAGES[index].zoom)
		if _camera_tween != null:
			_camera_tween.kill()
		if animate:
			_camera_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_camera_tween.tween_property(camera, "zoom", zoom, CAMERA_SECONDS)
		else:
			camera.zoom = zoom
	bounds_changed.emit(bounds)

func _apply_bounds() -> void:
	var r: Rect2 = bounds
	$Ground.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var half: float = WALL_THICKNESS * 0.5
	var center: Vector2 = r.get_center()
	$Walls/North.shape.size = Vector2(r.size.x + WALL_THICKNESS, WALL_THICKNESS)
	$Walls/South.shape.size = Vector2(r.size.x + WALL_THICKNESS, WALL_THICKNESS)
	$Walls/West.shape.size = Vector2(WALL_THICKNESS, r.size.y + WALL_THICKNESS)
	$Walls/East.shape.size = Vector2(WALL_THICKNESS, r.size.y + WALL_THICKNESS)
	$Walls/North.position = Vector2(center.x, r.position.y - half)
	$Walls/South.position = Vector2(center.x, r.end.y + half)
	$Walls/West.position = Vector2(r.position.x - half, center.y)
	$Walls/East.position = Vector2(r.end.x + half, center.y)
