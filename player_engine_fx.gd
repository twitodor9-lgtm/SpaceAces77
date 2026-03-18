@tool
extends Node2D

@export var enabled: bool = true:
	set(value):
		enabled = value
		visible = value
		set_process(value)
		queue_redraw()

@export var normal_flame_color: Color = Color(1.0, 0.62, 0.14, 0.9)
@export var normal_core_color: Color = Color(1.0, 0.94, 0.62, 0.95)
@export var turbo_flame_color: Color = Color(0.22, 0.75, 1.0, 0.95)
@export var turbo_core_color: Color = Color(0.9, 1.0, 1.0, 0.95)
@export var idle_scale: float = 0.75
@export var thrust_scale: float = 1.0
@export var turbo_scale: float = 1.35
@export var flame_length: float = 26.0
@export var flame_width: float = 11.0
@export var core_length: float = 13.0
@export var core_width: float = 5.5
@export var flicker_speed: float = 13.0
@export var flicker_amount: float = 0.12

var _phase: float = 0.0
var _throttle: float = 1.0
var _turbo_active: bool = false

func _ready() -> void:
	visible = enabled
	set_process(enabled)
	queue_redraw()

func _process(delta: float) -> void:
	if not enabled:
		return
	_phase += delta * flicker_speed
	queue_redraw()

func set_thrust_state(active: bool, turbo_active: bool = false) -> void:
	_throttle = thrust_scale if active else idle_scale
	_turbo_active = turbo_active
	queue_redraw()

func _draw() -> void:
	if not enabled:
		return

	var flicker := 1.0 + sin(_phase) * flicker_amount + cos(_phase * 0.57) * flicker_amount * 0.45
	var scale_mul := _throttle * (turbo_scale if _turbo_active else 1.0) * flicker
	var outer_len := flame_length * scale_mul
	var outer_w := flame_width * (0.92 + sin(_phase * 0.8) * 0.05)
	var inner_len := core_length * scale_mul
	var inner_w := core_width * (0.95 + cos(_phase * 0.9) * 0.04)

	var outer_color := turbo_flame_color if _turbo_active else normal_flame_color
	var inner_color := turbo_core_color if _turbo_active else normal_core_color

	_draw_flame_blob(Vector2(-outer_len * 0.6, 0.0), outer_len, outer_w, outer_color)
	_draw_flame_blob(Vector2(-inner_len * 0.48, 0.0), inner_len, inner_w, inner_color)

func _draw_flame_blob(center: Vector2, length: float, width: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(length * 0.5, 0.0),
		center + Vector2(0.1 * length, -width * 0.9),
		center + Vector2(-length * 0.6, 0.0),
		center + Vector2(0.1 * length, width * 0.9),
	])
	draw_colored_polygon(points, color)
