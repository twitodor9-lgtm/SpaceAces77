@tool
extends Node2D

@export var enabled: bool = true:
	set(value):
		enabled = value
		visible = value
		set_process(value)
		queue_redraw()

@export var ground_line_path: NodePath = NodePath("../GroundLine")
@export var fog_color: Color = Color(0.82, 0.92, 0.9, 0.10)
@export var edge_fog_color: Color = Color(0.92, 0.98, 0.96, 0.055)
@export var band_height: float = 132.0
@export var vertical_offset: float = -24.0
@export var drift_speed: float = 12.0
@export var wave_amplitude: float = 9.0
@export var wave_speed: float = 0.42
@export var puff_spacing: float = 150.0
@export var puff_width: float = 150.0
@export var puff_height: float = 30.0
@export var viewport_padding: float = 220.0
@export var secondary_layer_offset: float = -18.0
@export var secondary_layer_speed_mul: float = 0.58
@export var secondary_alpha_mul: float = 0.82

var _phase: float = 0.0

func _ready() -> void:
	visible = enabled
	set_process(enabled)
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

	_draw_fog_layer(left, right, base_y, 1.0, 0.0)
	_draw_fog_layer(left, right, base_y + secondary_layer_offset, secondary_alpha_mul, 1.7)

func _draw_fog_layer(left: float, right: float, base_y: float, alpha_mul: float, phase_offset: float) -> void:
	var rect := Rect2(Vector2(left, base_y - band_height * 0.58), Vector2(right - left, band_height))
	draw_rect(rect, Color(edge_fog_color.r, edge_fog_color.g, edge_fog_color.b, edge_fog_color.a * alpha_mul), true)

	var x := left
	var index := 0
	while x <= right:
		var wave := sin((_phase + phase_offset) * wave_speed + float(index) * 0.55) * wave_amplitude
		var speed_mul := 1.0 if alpha_mul >= 0.99 else secondary_layer_speed_mul
		var drift := fmod((_phase + phase_offset) * drift_speed * speed_mul + float(index) * 23.0, puff_spacing)
		var center := Vector2(x + drift, base_y + wave)
		var width_mul := 1.0 + 0.18 * sin(float(index) * 1.37 + phase_offset)
		var height_mul := 1.0 + 0.22 * cos(float(index) * 0.91 + phase_offset)
		_draw_soft_blob(center, Vector2(puff_width * width_mul, puff_height * height_mul), Color(fog_color.r, fog_color.g, fog_color.b, fog_color.a * alpha_mul), index + int(phase_offset * 10.0))
		_draw_soft_blob(center + Vector2(58.0, -6.0), Vector2(puff_width * 0.72, puff_height * 0.82), Color(edge_fog_color.r, edge_fog_color.g, edge_fog_color.b, edge_fog_color.a * alpha_mul), index + 17)
		x += puff_spacing
		index += 1

func _get_ground_y() -> float:
	var marker := get_node_or_null(ground_line_path) as Node2D
	if marker != null:
		return to_local(marker.global_position).y
	return get_viewport_rect().size.y - 96.0

func _draw_soft_blob(center: Vector2, radii: Vector2, color: Color, seed_i: int) -> void:
	var points := PackedVector2Array()
	var steps := 28
	for i in range(steps):
		var t := TAU * float(i) / float(steps)
		var wobble := 1.0 + 0.13 * sin(float(seed_i) * 0.71 + float(i) * 1.91) + 0.08 * cos(float(seed_i) * 1.23 + float(i) * 1.13)
		points.append(center + Vector2(cos(t) * radii.x * wobble, sin(t) * radii.y * wobble))
	draw_colored_polygon(points, color)
