@tool
extends Node2D

@export var enabled: bool = true
@export var ground_line_path: NodePath = NodePath("../GroundLine")
@export var fog_color: Color = Color(0.82, 0.92, 0.9, 0.14)
@export var edge_fog_color: Color = Color(0.92, 0.98, 0.96, 0.08)
@export var band_height: float = 120.0
@export var vertical_offset: float = -26.0
@export var drift_speed: float = 10.0
@export var wave_amplitude: float = 10.0
@export var wave_speed: float = 0.55
@export var puff_spacing: float = 120.0
@export var puff_width: float = 110.0
@export var puff_height: float = 26.0
@export var viewport_padding: float = 180.0

var _phase: float = 0.0

func _ready() -> void:
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if not enabled:
		return
	_phase += delta
	queue_redraw()

func _draw() -> void:
	if not enabled:
		return

	var ground_y := _get_ground_y()
	var view := get_viewport_rect().size
	var left := -viewport_padding
	var right := view.x + viewport_padding
	var base_y := ground_y + vertical_offset

	var rect := Rect2(Vector2(left, base_y - band_height * 0.55), Vector2(right - left, band_height))
	draw_rect(rect, edge_fog_color, true)

	var x := left
	var index := 0
	while x <= right:
		var wave := sin(_phase * wave_speed + float(index) * 0.7) * wave_amplitude
		var drift := fmod(_phase * drift_speed + float(index) * 18.0, puff_spacing)
		var center := Vector2(x + drift, base_y + wave)
		_draw_soft_ellipse(center, Vector2(puff_width, puff_height), fog_color)
		_draw_soft_ellipse(center + Vector2(38.0, -8.0), Vector2(puff_width * 0.7, puff_height * 0.78), edge_fog_color)
		x += puff_spacing
		index += 1

func _get_ground_y() -> float:
	var marker := get_node_or_null(ground_line_path) as Node2D
	if marker != null:
		return to_local(marker.global_position).y
	return get_viewport_rect().size.y - 96.0

func _draw_soft_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var steps := 24
	for i in range(steps):
		var t := TAU * float(i) / float(steps)
		points.append(center + Vector2(cos(t) * radii.x, sin(t) * radii.y))
	draw_colored_polygon(points, color)
